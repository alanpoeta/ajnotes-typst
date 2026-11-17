import os
import re
import shutil
import subprocess
from pathlib import Path


# Fallback document language when a course's course.typ has no recognisable one.
DEFAULT_LANGUAGE = 'english'


def _find_tool(env_var, candidates, name):
    """An explicit override from the environment, else the first candidate path
    that exists, else whatever `name` resolves to on PATH."""
    override = os.environ.get(env_var)
    if override:
        return override
    for candidate in candidates:
        if Path(candidate).exists():
            return candidate
    return shutil.which(name) or name


# Command used to run Inkscape (for the figure scripts). Auto-detected per OS so
# the same toolkit works on macOS, Linux and Windows; the first path that exists
# wins, falling back to a bare 'inkscape' (i.e. whatever is on your PATH).
# Override with the INKSCAPE environment variable if yours lives elsewhere.
INKSCAPE = _find_tool('INKSCAPE', [
    # macOS (Homebrew cask puts the real binary inside the .app bundle)
    '/Applications/Inkscape.app/Contents/MacOS/inkscape',
    str(Path.home() / 'Applications/Inkscape.app/Contents/MacOS/inkscape'),
    '/opt/homebrew/bin/inkscape',
    '/usr/local/bin/inkscape',
    # Linux (a distro package lands on PATH; Flatpak needs the wrapper below)
    '/usr/bin/inkscape',
    '/var/lib/flatpak/exports/bin/org.inkscape.Inkscape',
    str(Path.home() / '.local/share/flatpak/exports/bin/org.inkscape.Inkscape'),
    # Windows
    r'C:\Program Files\Inkscape\bin\inkscape.exe',
    r'C:\Program Files (x86)\Inkscape\bin\inkscape.exe',
], 'inkscape')

# The Typst compiler. VS Code tasks don't always inherit your shell's PATH (on
# macOS, apps launched from the Dock get a minimal one), hence the explicit
# Homebrew locations. Override with the TYPST environment variable.
TYPST = _find_tool('TYPST', [
    '/opt/homebrew/bin/typst',
    '/usr/local/bin/typst',
    str(Path.home() / '.cargo/bin/typst'),
], 'typst')

# The root is the folder that holds your course folders. The toolkit (these
# scripts and the shared Typst package) lives elsewhere, so the root is taken
# from the AJNOTES_ROOT environment variable — the VS Code tasks set it to the
# folder you have open — and otherwise falls back to the current directory.
ROOT = Path(os.environ.get('AJNOTES_ROOT') or Path.cwd()).resolve()

# The shared Typst package, registered as a local package so it's found by name.
# Its name and version come from package/typst.toml, so a version bump there is
# picked up by every file the scripts generate.
TOOLKIT = Path(__file__).resolve().parent.parent
PACKAGE_DIR = TOOLKIT / 'package'


def _package_spec():
    toml = (PACKAGE_DIR / 'typst.toml').read_text(encoding='utf-8')
    name = re.search(r'^name\s*=\s*"(.+?)"', toml, re.M).group(1)
    version = re.search(r'^version\s*=\s*"(.+?)"', toml, re.M).group(1)
    return name, version


PACKAGE_NAME, PACKAGE_VERSION = _package_spec()
PACKAGE = f'@local/{PACKAGE_NAME}:{PACKAGE_VERSION}'

# Lecture dates are stored language-neutrally as ISO YYYY-MM-DD; #lecture in the
# package localizes the weekday and month name at compile time.
DATE_FORMAT = '%Y-%m-%d'


def typst_command(action, main, root):
    """The typst CLI call for `action` ('compile' or 'watch') on `main`, with the
    course folder as project root: every document imports ../course.typ (or
    ../../), which Typst only allows inside the root."""
    return [TYPST, action, '--root', str(root), str(main), str(Path(main).with_suffix('.pdf'))]


def compile_typst(main, root):
    """Build `main` (a main.typ) into main.pdf beside it. Typst's diagnostics are
    short and point at the exact line, so they're shown as-is. Returns the exit
    code; 127 if Typst isn't installed."""
    try:
        # Run from the course folder so error messages show short paths
        # (notes/lectures/lec_02.typ) whatever folder the task started in.
        return subprocess.run(typst_command('compile', main, root), cwd=str(root)).returncode
    except FileNotFoundError:
        print(f'Could not run Typst ({TYPST!r}). Install it (see the README), or set '
              f'the TYPST environment variable to its path.')
        return 127
