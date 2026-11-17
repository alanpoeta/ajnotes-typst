"""Shared helpers for the Inkscape figure workflow.

Adapted from Gilles Castel's inkscape-figures (https://castel.dev/post/lecture-notes-2/),
trimmed to the cross-platform core: create a figure from a template, and export
an .svg so that Typst draws it and typesets its labels.

Exporting mirrors LaTeX's pdf_tex route. Inkscape writes the drawing as a PDF
*without* its text (split into pages wherever text sits between shapes) plus a
.pdf_tex listing every label's position; that listing is translated into
<name>.typ, which places the PDF pages and the labels with the package's
inkscape-figure(). The .pdf_tex is a temporary file and is removed.
"""
import os
import re
import subprocess
import sys
from pathlib import Path

from config import INKSCAPE
from courses import course_containing
from utils import typst_string

TEMPLATE = Path(__file__).resolve().parent / 'figure-template.svg'


def beautify(name):
    """'my-figure' -> 'My Figure' for captions/labels."""
    return name.replace('_', ' ').replace('-', ' ').title()


def slugify(title):
    """'My Figure' -> 'my-figure' for file names."""
    return title.strip().replace(' ', '-').lower()


def typst_snippet(figure_typ, title, from_file=None):
    """The Typst snippet that includes a figure. Typst resolves an include relative
    to the file containing it, so the path is relative to the file you're editing
    (a lecture in lectures/ needs ../figures/...); without one, it's relative to
    the project's main.typ."""
    figure_typ = Path(figure_typ)
    base = Path(from_file).resolve().parent if from_file else figure_typ.parent.parent
    rel = os.path.relpath(figure_typ, base).replace(os.sep, '/')
    return f'#figure(include "{rel}", caption: [{title}]) <fig:{figure_typ.stem}>'


def open_in_inkscape(path):
    """Open a figure for editing in Inkscape.

    On macOS go through `open -a` (Launch Services): it hands the file to an
    already-running Inkscape instead of starting a brand-new process per figure,
    and focuses the app. Other platforms spawn the binary directly.
    """
    path = str(path)
    if sys.platform == 'darwin':
        app = INKSCAPE
        # /Applications/Inkscape.app/Contents/MacOS/inkscape -> the .app bundle
        marker = '.app/Contents/MacOS/'
        if marker in app:
            app = app[:app.index(marker) + len('.app')]
        try:
            subprocess.Popen(['open', '-a', app, path])
            return
        except FileNotFoundError:
            pass  # fall through to the direct launch below
    try:
        subprocess.Popen([INKSCAPE, path])
    except FileNotFoundError:
        print(f'Could not run Inkscape ({INKSCAPE!r}). Install Inkscape and put '
              f'it on your PATH, or set the INKSCAPE environment variable.')


def _inkscape_version():
    try:
        out = subprocess.check_output([INKSCAPE, '--version'], universal_newlines=True,
                                      stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        raise SystemExit(
            f'Could not run Inkscape ({INKSCAPE!r}). Install Inkscape and put it '
            f'on your PATH, or set the INKSCAPE environment variable.')
    version = re.findall(r'[0-9.]+', out)[0]
    parts = [int(p) for p in version.split('.') if p]
    return parts + [0] * (3 - len(parts))


# --- pdf_tex -> Typst -------------------------------------------------------------

def _braced(s, start):
    """The text inside the {...} group opening at s[start], and the index after it."""
    depth = 0
    for i in range(start, len(s)):
        if s[i] == '{':
            depth += 1
        elif s[i] == '}':
            depth -= 1
            if depth == 0:
                return s[start + 1:i], i + 1
    return s[start + 1:], len(s)


def _unlatex(text):
    """Undo what Inkscape adds to label text for LaTeX: it escapes & and %, and
    wraps bold/italic text in \\textbf / \\textit. The rest is the Typst markup
    you typed, passed through untouched."""
    out = ''
    i = 0
    while i < len(text):
        m = re.match(r'\\(textbf|textit|emph)\{', text[i:])
        if m:
            inner, end = _braced(text, i + m.end() - 1)
            func = 'strong' if m.group(1) == 'textbf' else 'emph'
            out += f'#{func}[{_unlatex(inner)}]'
            i = end
        elif text.startswith('\\&', i) or text.startswith('\\%', i):
            out += text[i + 1]
            i += 2
        else:
            out += text[i]
            i += 1
    return out


_NUM = r'(-?[0-9.]+(?:e-?[0-9]+)?)'


def pdf_tex_layers(pdf_tex):
    """Parse an Inkscape .pdf_tex into (aspect, layers) in stacking order."""
    aspect = 1.0
    layers = []
    for line in pdf_tex.splitlines():
        m = re.search(r'\\begin\{picture\}\(' + _NUM + ',' + _NUM + r'\)', line)
        if m:
            aspect = float(m.group(2)) / float(m.group(1))
            continue
        m = re.match(r'\s*\\put\(' + _NUM + ',' + _NUM + r'\)\{(.*)\}%\s*$', line)
        if not m:
            continue
        x, y, inner = float(m.group(1)), float(m.group(2)), m.group(3)
        img = re.search(r'\\includegraphics\[[^\]]*page=(\d+)\]\{([^}]*)\}', inner)
        if img:
            layers.append({'page': int(img.group(1)), 'file': img.group(2)})
            continue
        tab = re.search(r'\\begin\{tabular\}\[t\]\{(\w)\}(.*)\\end\{tabular\}', inner)
        if not tab:
            continue
        # Inkscape lists every text object, wherever it is; one anchored off the
        # page (e.g. a note parked beside the drawing) isn't part of the figure.
        eps = 1e-3
        if not (-eps <= x <= 1 + eps and -eps <= y <= aspect + eps):
            continue
        align = {'l': 'l', 'c': 'c', 'r': 'r'}.get(tab.group(1), 'l')
        label = {'x': x, 'y': y, 'align': align,
                 'lines': [_unlatex(t) for t in tab.group(2).split('\\\\')]}
        color = re.search(r'\\color\[rgb\]\{' + _NUM + ',' + _NUM + ',' + _NUM + r'\}', inner)
        if color:
            rgb = [float(c) for c in color.groups()]
            if rgb != [0.0, 0.0, 0.0]:
                label['color'] = rgb
        rot = re.search(r'\\rotatebox\{' + _NUM + r'\}', inner)
        if rot and float(rot.group(1)) != 0:
            label['angle'] = float(rot.group(1))
        layers.append(label)
    return aspect, layers


def _fmt(v):
    return f'{v:.6g}'


def typst_figure_module(aspect, layers, course_import):
    """The source of <name>.typ for parsed pdf_tex layers."""
    out = [
        '// Generated by ajnotes from the .svg beside it: edit the drawing in Inkscape',
        '// (Edit figure); this file is rewritten on every export.',
        f'#import {typst_string(course_import)} as scope',
        '#scope.inkscape-figure(',
        f'  aspect: {_fmt(aspect)},',
        '  scope: dictionary(scope),',
        '  layers: (',
    ]
    for layer in layers:
        if 'page' in layer:
            out.append(f'    (file: path({typst_string(layer["file"])}), page: {layer["page"]}),')
            continue
        parts = [f'x: {_fmt(layer["x"])}', f'y: {_fmt(layer["y"])}',
                 f'align: "{layer["align"]}"']
        if 'color' in layer:
            r, g, b = (round(c * 255) for c in layer['color'])
            parts.append(f'color: rgb({r}, {g}, {b})')
        if 'angle' in layer:
            parts.append(f'angle: {_fmt(layer["angle"])}')
        lines = ', '.join(typst_string(t) for t in layer['lines'])
        parts.append(f'lines: ({lines},)')
        out.append(f'    ({", ".join(parts)}),')
    out += ['  ),', ')', '']
    return '\n'.join(out)


def _course_import(svg_path):
    """course.typ relative to the figure, so labels can use the course's macros."""
    course = course_containing(svg_path)
    if course is None:
        return '../course.typ'
    return os.path.relpath(course.course_file, Path(svg_path).parent).replace(os.sep, '/')


def write_placeholder(svg_path):
    """An empty <name>.typ of the drawing's proportions, so a figure's snippet
    compiles as soon as it's pasted; the first export replaces it."""
    svg = Path(svg_path).read_text(encoding='utf-8')
    w = re.search(r'<svg[^>]*?\swidth="([0-9.]+)', svg, re.S)
    h = re.search(r'<svg[^>]*?\sheight="([0-9.]+)', svg, re.S)
    aspect = float(h.group(1)) / float(w.group(1)) if w and h else 0.5
    Path(svg_path).with_suffix('.typ').write_text(
        typst_figure_module(aspect, [], _course_import(svg_path)), encoding='utf-8')


def export_figure(svg_path):
    """Export an .svg to <name>.pdf + <name>.typ next to it. Returns True on success."""
    svg_path = Path(svg_path)
    pdf_path = svg_path.with_suffix('.pdf')
    pdf_tex_path = svg_path.with_suffix('.pdf_tex')
    typ_path = svg_path.with_suffix('.typ')

    if _inkscape_version() < [1, 0, 0]:
        command = [
            INKSCAPE,
            '--export-area-page',
            '--export-dpi', '300',
            '--export-pdf', str(pdf_path),
            '--export-latex', str(svg_path),
        ]
    else:
        command = [
            INKSCAPE, str(svg_path),
            '--export-area-page',
            '--export-dpi', '300',
            '--export-type=pdf',
            '--export-latex',
            '--export-filename', str(pdf_path),
        ]

    if subprocess.run(command, stderr=subprocess.DEVNULL).returncode != 0 or not pdf_tex_path.exists():
        return False

    # Labels can use the course's macros: the figure module evaluates them with
    # course.typ in scope, imported relative to the figure.
    aspect, layers = pdf_tex_layers(pdf_tex_path.read_text(encoding='utf-8'))
    typ_path.write_text(typst_figure_module(aspect, layers, _course_import(svg_path)),
                        encoding='utf-8')
    pdf_tex_path.unlink()
    return True
