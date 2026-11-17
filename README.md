# Typst lecture notes toolkit

A shared toolkit for writing university lecture notes (and exercise solutions) in
[Typst](https://typst.app), based on [Gilles Castel's setup](https://castel.dev/post/lecture-notes-3).
It is the Typst counterpart of the LaTeX [ajnotes](https://github.com/alanpoeta/ajnotes) toolkit: the same folder layout, the same VS Code tasks, the same Inkscape figure
workflow and the same look on the page — with Typst's millisecond rebuilds instead
of a TeX installation. Installed **once per machine**, then used from any folder.
Works on **macOS, Linux and Windows** with VS Code.

## How it works

- **This toolkit folder** holds the `scripts/`, the shared `ajnotes` Typst package
  (`package/`), and a copy of the global VS Code tasks. It is installed once and
  lives in the same place for all your courses.
- **Your notes live anywhere.** Any folder you open in VS Code is treated as a
  *root*; the scripts act on it (the tasks pass it as `AJNOTES_ROOT`). A folder is
  a **course** if it contains `notes/main.typ`, at any depth under the root — so
  you can group courses in e.g. `semester-1/`.
- **Every course has a `course.typ`**: its title, language and its own macros. It
  imports the package, and every document of the course imports it — one line at
  the top of each file — so the notes, each lecture and each exercise share
  everything defined there.
- **The package is found by name:** `#import "@local/ajnotes:0.1.0": *` (written
  once, in `course.typ`) works from any folder, because Typst looks up local
  packages in a fixed per-user directory.

## Requirements

| | Required | Notes |
|---|---|---|
| **Typst** | 0.15+ | The `typst` CLI. One binary, no TeX installation. |
| **Python** | 3.8+ | The tasks call `python3` on macOS/Linux, the `py` launcher on Windows. |
| **VS Code** + **Tinymist** | recommended | Tinymist is the Typst extension: highlighting, completion, live preview. |
| **New Computer Modern** fonts | recommended | Typst ships the serif and math faces; the full family adds the sans used for lecture dates (falls back to serif without it). |
| **Inkscape** | optional | Needed only for the figure tasks. |
| `watchdog` | optional | Required by **Watch figures**. |
| `pyperclip` | optional | Copies a new figure's snippet to your clipboard. |

Inkscape is auto-detected per platform — inside `Inkscape.app` on macOS, on `PATH`
or via Flatpak on Linux, under `Program Files` on Windows — and an `INKSCAPE`
environment variable overrides the search. The same goes for Typst (`TYPST`).

## Installation

### 1. Get the toolkit

**macOS / Linux:**
```sh
git clone https://github.com/alanpoeta/ajnotes-typst.git ~/Projects/ajnotes/ajnotes-typst
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/alanpoeta/ajnotes-typst.git $HOME\Projects\ajnotes\ajnotes-typst
```

Any stable location works; the rest of these steps refer to it as `<toolkit>`. The
VS Code tasks use `${userHome}`, so if you keep the same path *relative to your home
folder* on each machine, the same `tasks.json` works everywhere unedited.

### 2. Install the prerequisites

**macOS** (via [Homebrew](https://brew.sh)):
```sh
brew install typst python
brew install --cask font-new-computer-modern
brew install --cask inkscape                      # optional, for figures
code --install-extension myriad-dreamin.tinymist
```

**Linux** — Typst is a single binary: take it from your distribution
(`pacman -S typst` on Arch, `brew install typst` with Homebrew on Linux) or from the
[releases page](https://github.com/typst/typst/releases) into `~/.local/bin`. Then:
```sh
sudo apt install python3 python3-venv inkscape    # Debian/Ubuntu
code --install-extension myriad-dreamin.tinymist
```
For the fonts, put the [New Computer Modern](https://ctan.org/pkg/newcomputermodern)
`.otf` files in `~/.local/share/fonts` (or install your distribution's package of
them, if it has one).

**Windows:**
```powershell
winget install --id Typst.Typst
winget install --id Python.Python.3.13
winget install --id Inkscape.Inkscape             # optional, for figures
code --install-extension myriad-dreamin.tinymist
```
Install the [New Computer Modern](https://ctan.org/pkg/newcomputermodern) fonts by
right-clicking the `.otf` files → *Install*.

Unlike LaTeX on Windows, nothing else is needed: Typst has no Perl, no `latexmk`
and no package manager to set up.

### 3. Register the package

**macOS / Linux:**
```sh
python3 <toolkit>/scripts/install.py --venv --vscode
```

**Windows (PowerShell):**
```powershell
py <toolkit>\scripts\install.py --venv --vscode
```

This links `package/` into Typst's local package directory as `@local/ajnotes:0.1.0`
(a link, not a copy, so edits to the package take effect immediately; on Windows a
directory junction, which needs no administrator rights), creates your private
`package/env.typ`; with `--venv` the virtualenv for the figure tasks
(`~/.local/share/ajnotes-venv`, or `%LOCALAPPDATA%\ajnotes-venv`); and with
`--vscode` the small VS Code extension in [`vscode-extension/`](vscode-extension)
that previews or exports a whole document from any of its files (see
[Previewing and PDFs](#previewing-and-pdfs)). It is safe to re-run. The venv is the one the LaTeX toolkit uses too, so with both installed
there is only one.

[`scripts/_python.py`](scripts/_python.py) finds the venv automatically (override
with `AJNOTES_PYTHON`); without it every script still runs on plain `python3` and
only **Watch figures** is unavailable. A venv rather than a bare `pip install`,
because Homebrew's Python and most distro Pythons refuse to install into the
system site-packages (PEP 668).

### 4. Set your name and region

Per-person settings live in `<toolkit>/package/env.typ` — git-ignored, so nothing
personal reaches the repository:

```typ
#let env = (
  author: "Your Name",          // title page + running header
  german-region: "CH",          // "CH" «Swiss» | "DE"/"AT" „German“ quotes
  english-region: "US",         // "US" “American” | "GB" ‘British’ quotes
  german-numbers: none,         // none = house style | "DE" | "FR" | "UK" | "US"
  english-numbers: none,
)
```

Set only the keys you care about; anything missing takes the default shown. The
regions control hyphenation and quotation marks. The number formats are
**opt-in**: left at `none`, numbers use the house style — decimal point, comma
thousands separator, `·` before powers of ten — in either language. A preset
switches one language only, so `german-numbers: "DE"` gives `1 234,5` in German
documents while English ones keep the house style. You can also give the parts
yourself: `(decimal: ",", group: ".", product: "·")`.

A single document can override the name: `#show: notes.with(course, author: "…")`.

### 5. Install the VS Code tasks

Copy [`vscode-user-tasks.json`](vscode-user-tasks.json) into your VS Code user folder
as `tasks.json`:

| Platform | Destination |
|---|---|
| macOS | `~/Library/Application Support/Code/User/tasks.json` |
| Linux | `~/.config/Code/User/tasks.json` |
| Windows | `%APPDATA%\Code\User\tasks.json` |

**Already using the LaTeX toolkit?** Append the `tasks` of this file to your
existing `tasks.json` instead of replacing it. Every task here is labelled
`Typst: …` and sets its own `AJNOTES_ROOT`, so the two sets coexist; the `inputs`
have the same ids and definitions in both, so keep one copy of each.

If you cloned somewhere other than `~/Projects/ajnotes/ajnotes-typst`, update the
`${userHome}/...` script paths inside it to match.

### 6. *(Optional)* Bind shortcuts

In the same folder's `keybindings.json`:

```json
{ "key": "ctrl+alt+r", "command": "workbench.action.tasks.runTask" },
{
    "key": "ctrl+alt+f",
    "command": "workbench.action.tasks.runTask",
    "args": "Typst: New figure",
    "when": "editorTextFocus && editorLangId == typst"
},
{
    "key": "ctrl+k v",
    "command": "ajnotes.previewDocument",
    "when": "editorLangId == typst"
},
{
    "key": "ctrl+alt+b",
    "command": "ajnotes.exportDocument",
    "when": "editorLangId == typst"
}
```

Use `cmd+…` on macOS. The last two preview and export the whole document rather
than the file you're in; `Ctrl/Cmd+Alt+B` is LaTeX Workshop's build shortcut, so
it does the same thing in both toolkits. They belong here rather than in the
extension because Tinymist binds `Ctrl/Cmd+K V` too, and your own keybindings are
the ones that win. Reload VS Code so it picks up the tasks and keybindings.

### Verifying the install

Run **Typst: New course**, open the new `notes/main.typ` and press
<kbd>Cmd/Ctrl+K</kbd> <kbd>V</kbd>: a preview with the title page means Typst,
Tinymist and the package registration are all working.
<kbd>Cmd/Ctrl+Alt+B</kbd> should then write `notes/main.pdf` next to `main.typ`.

## Layout

```
ajnotes-typst/                          installed once (this folder)
├── scripts/                            the tooling (install.py registers the package)
├── package/                            the ajnotes Typst package (edit here)
│   ├── lib.typ  src/  typst.toml
│   └── env.example.typ                 → env.typ, your private settings
├── vscode-extension/                   Preview / Export Document (install.py --vscode)
└── vscode-user-tasks.json              copy to your VS Code User dir as tasks.json

<any folder you open>/                  a root — one or more courses (may nest)
└── special-relativity/                 a course = a folder with notes/main.typ
    ├── course.typ                      title, language and macros for everything below
    ├── notes/                          lecture notes → one PDF
    │   ├── main.typ   lectures/   figures/   (build: main.pdf)
    └── exercises/                      appears on first "New exercise"
        └── ex_01/  main.typ · sheet.pdf · figures/  (build: main.pdf)
```

- A folder is a **course** if it has `notes/main.typ`. Its title and language are
  read from `course.typ` — by the documents and by the scripts.
- **Exercises** are standalone: each `exercises/ex_NN/` compiles to its own PDF and
  is never merged into the notes.
- **Course macros** go in `course.typ`, after the `course` dictionary. Since every
  file of the course imports it, a macro is defined once and works in the notes,
  in every exercise and in figure labels:

  ```typ
  // special-relativity/course.typ
  #import "@local/ajnotes:0.1.0": *

  #let course = (title: "Special Relativity", language: "english")

  #let Lor = math.op("Lor")
  #let fourvec(x) = math.underline(x)
  // `mode` tells the notes and a problem sheet apart:
  #let hint(body) = context if mode.get() == "notes" [#body]
  ```

  To override one for a single sheet, redefine it with `#let` below that sheet's
  import.
- **Course options** go in the `course` dictionary (all optional):
  `first-section: 0` numbers sections from 0, `theorem-from: 0` numbers theorems
  N.0, N.1, … in each section, `toc-depth: 2` limits the table of contents.
  `#part[Title]` starts a part (I, II, …) above the sections, `#set-theorem-counter(1)`
  continues a section's theorem numbering from a given number, and
  `boxed-plain("Behauptung")` makes an unnumbered boxed environment (such as
  `#let claim = boxed-plain("Behauptung")` in `course.typ`).
- The **first line of each file** imports `course.typ` (`#import "../course.typ": *`
  in `notes/main.typ`, `"../../course.typ"` in lectures and exercises). The scripts
  write it for you; keep it.
- `notes/main.typ` includes **every** lecture: **New lecture** adds its
  `#include` after the last one, so anything you put after the lectures (a
  bibliography, say) stays at the end. Unlike LaTeX there's no speed reason to
  leave lectures out, and the preview always shows the whole notes.
- To **renumber** a lecture, rename its `lec_NN.typ` **and** edit the number in its
  `#lecture(N, …)` line (that argument is what's printed).
- The **project root** for Typst is the course folder or above: documents import
  `../course.typ`, and Typst refuses paths outside the root. The tasks handle this;
  in VS Code, open the course folder or a parent of it (not `notes/` alone).

## Everyday use (VS Code tasks)

Press <kbd>Cmd+Alt+R</kbd> (macOS) / <kbd>Ctrl+Alt+R</kbd> (Windows/Linux), or
**Terminal → Run Task…**, then pick one. Course/project tasks act on the **file you
have open**; prompting tasks pop a text box at the top — type and press
<kbd>Enter</kbd>.

| Task | What it does |
|------|--------------|
| Typst: New course | create a course folder with `course.typ` and `notes/main.typ` (prompts title + language) |
| Typst: New lecture | add the next `lec_NN.typ` and include it (prompts an optional title) |
| Typst: Compile all courses | build every course's notes |
| Typst: New exercise | scaffold an `exercises/ex_NN` solution mini-project (prompts title) |
| Typst: New figure | create + open an Inkscape figure, copy its `#figure` snippet |
| Typst: Edit figure | reopen an existing figure in Inkscape |
| Typst: Watch figures | auto-export figures on save (run once per session) |

## Previewing and PDFs

Where LaTeX has a compile step, Typst has a **live preview**: press
<kbd>Cmd/Ctrl+K</kbd> <kbd>V</kbd> in any file of a document and a panel beside the
editor shows the whole document — the notes for a lecture, the sheet for an
exercise file — and re-renders as you type, without saving. Clicking in the preview
jumps to that spot in the source, and moving the cursor scrolls the preview along.

That shortcut is the toolkit's **ajnotes: Preview Document** command (from the
extension `install.py --vscode` installs). Tinymist's own preview shows only the
file you're in, so from a lecture you'd see that lecture alone, without the title
page, header or section numbers; this command finds the document's `main.typ` —
walking up from the open file, and from `course.typ` to the notes — and previews
that instead, leaving you in the file you were editing.

The preview never writes a file. For the PDF itself, to print or hand in, press
<kbd>Cmd/Ctrl+Alt+B</kbd> — **ajnotes: Export Document PDF**, LaTeX Workshop's
build shortcut — in any file of the document. Like the preview it finds the
document's `main.typ`, so from a lecture you get the whole notes, and it writes
`main.pdf` next to `main.typ` using Tinymist's compiler. (Tinymist's own *Export
as PDF* exports the open file alone, which from a lecture means a stray
`lec_NN.pdf`.) **Typst: Compile all courses** rebuilds every course's notes at
once, e.g. before an exam.

## Writing notes

Lecture files hold ordinary Typst markup. Headings are `= Section`,
`== Subsection`; math is `$x^2$` inline and `$ x^2 $` (spaces inside) displayed.

```typ
#import "../../course.typ": *

#lecture(3, "2026-11-17", [Ableitungen])

= Differenzierbarkeit
#definition("Differenzierbar")[
  $f$ heisst differenzierbar in $x_0$, falls $lim_(h -> 0) (f(x_0 + h) - f(x_0))/h$ existiert.
] <def-diff>

#theorem[Jede differenzierbare Funktion ist stetig.]
#proof[Nach @def-diff gilt … ]

#example[$dif/(dif x) x^2 = 2x$ und $integral_0^1 x dif x = evaluated(x^2/2)_0^1 = 1/2$.]
```

### From the LaTeX preamble

| LaTeX (`ajnotes.sty`) | Typst (`ajnotes`) |
|---|---|
| `\begin{theorem}[Title] … \end{theorem}` | `#theorem("Title")[…]` — likewise `definition`, `property`, `lemma`, `proposition`, `corollary`, `law`, `postulate`, `conclusion`, `bonus`, `conjecture` (boxed, numbered) |
| `example`, `unexample`, `remark`, `note`, `notation`, `intermezzo`, … | `#example[…]` etc. (unboxed; `example`, `unexample`, `intermezzo` end with ⋄; `example` and `remark` are numbered per section, e.g. "Beispiel 2.1", and can be labelled and referenced like theorems) |
| `\begin{proof}[Beweisidee]` | `#proof[…]`, `#proof("Beweisidee")[…]` |
| `\qed` (e.g. at the end of an answer on a sheet) | `#qed` — □ flush right, on the next line if the current one is full |
| `\qedhere` (□ on the last line of a display) | `qed` at the end of the display: `$ a &= b \ &= c qed $` — □ at the right margin of that line; a proof ending this way adds no second □ |
| `\label{x}` … `\ref{x}` | `<x>` after the element … `@x` ("Satz 2.3", "Gleichung (2.1)") |
| `\begin{equation}` / `\[ … \]` | `$ … $ <label>` (numbered) / `$ … $` (unnumbered) |
| `\lecture{3}{2026-11-17}{Title}` | `#lecture(3, "2026-11-17", [Title])` |
| `\begin{enumerate}` (nested: 1. → (a) → i. → A.), `[(a)]` | `+ item`, indented `+` to nest — the levels step through 1. → (a) → i. → A. like LaTeX; `#set enum(numbering: "(a)")` starts a list at that level (its sub-lists continue with i.) |
| `\exercise{1}` `\subexercise{a}` `\subsubexercise{i}` | `#exercise(1)[…]` `#subexercise("a")[…]` `#subsubexercise("i")[…]` |
| `\qty{9.81}{m/s^2}`, `\num{12345}`, `\ang{30}`, `\unit{kg.m/s^2}` | `#qty("9.81", "m/s^2")`, `#qty("12345")`, `#qty(30, "deg")`, `#unit("kg m \/ s^2")` (also inside math, without `#`) — see [Quantities](#quantities) |
| `\odv{f}{x}`, `\odv{}{t}`, `\pdv{f}{x}` | `$(dif f)/(dif x)$`, `$dif/(dif t)$`, `$(partial f)/(partial x)$` — Typst's `dif` is the upright differential, no macro needed |
| `f_n(x)`, `x_i'` | `f_n (x)`, `x'_i` — Typst attaches a bracket or prime right after a one-letter sub/superscript to it (`f_n(x)` puts `(x)` in the subscript, `x_i'` gives x with subscript i′); a space before the bracket and the prime before `_` give the LaTeX result. Digits (`f_1(x)`) and groups (`a_(n+1)(x)`) are fine; `e^sin(x)` stays a function call |
| `\vec{v}` | `arrow(v)` — careful: Typst's `vec(…)` is a column vector |
| `\eval{F(x)}_a^b` | `$evaluated(F(x))_a^b$` |
| `\N \Z \Q \R \C` | `NN ZZ QQ RR CC` (built in) |
| `\abs{x}` `\ceil{x}` `\floor{x}` `\p{x}` | `abs(x)` `ceil(x)` `floor(x)` `(x)` — built in, and they all scale |
| `\gcd` `\lcm` `\ggT` `\kgV` | `gcd` `lcm` (built in), `ggT` `kgV` |
| `\forall`, `\exists`, `\nexists`, `\lnot` | `forall`, `exists`, `exists.not`, `not` |
| `\mathscr` `\bm` `\cancel` | `scr()` `bold()` `cancel()` (built in) |
| `\correct{3}{2}` `\green{x}` `\contra` `\hr` | `#correct[3][2]` `#text(green)[x]` `#contra` `#line(length: 100%)` |
| `\todo{…}`, `\listoftodos` | `#todo[…]`, `#todo-list()` |
| `\hide{…}` | `/* … */` (Typst block comment) |
| `\incfig{name}` | `#figure(include "../figures/name.typ", caption: […])` — see [Figures](#figures-inkscape) |
| `\includepdf[pages=-]{sheet.pdf}` | `#include-pdf(path("sheet.pdf"), pages: 3)` |
| `\addbibresource{refs.bib}` … `\cite{k}` | `#bibliography("refs.bib")` … `@k` (IEEE style preset) |
| `tikz` | the [cetz](https://typst.app/universe/package/cetz) package, imported in `course.typ` |

### Quantities

One function, `qty`, does what siunitx splits into `\num`, `\qty` and `\ang`: a
value with or without a unit. `unit` sets a unit on its own.

```typ
#qty("9.81", "m/s^2")                     9.81 m over s², as a fraction
#qty("9.81", "m \/ s^2")                  9.81 m/s², with a slash
#qty("6.674e-11", "m^3 kg^(-1) s^(-2)")   6.674 · 10⁻¹¹ m³ kg⁻¹ s⁻²
#qty("12345.6")   #qty(30, "deg")         12,345.6   30°
$qty(sqrt(2)/2, "m")$   $qty(1/2 g t^2, "J")$
```

- **The value can be any math**, not just a number — a fraction, a root, a whole
  expression — and the unit follows with the same thin space (siunitx can't do
  this). A plain number gets number formatting instead: digit grouping, the decimal
  marker from `env.typ`, `e`-notation as a power of ten, `"+-"` as an uncertainty.
- **Units are written in Typst math syntax**, so they look like any other math:
  a space is a product, `/` a fraction (`"m/s^2"` is m over s²), `( )` groups and
  disappears (`"(kg m)/s^2"`, `"J/(kg K)"`), `\/` gives a slash instead
  (`"m \/ s^2"` → m/s²), `^` a power — with parentheses for anything longer than
  one character, `"s^(-1)"`, as everywhere in Typst. Functions work too:
  `"sqrt(Hz)"`. The one difference from math mode: a run of letters is a unit
  name, set upright as one symbol — `kg`, `Hz`, `μm` — instead of an unknown
  variable. `deg`, `degC`, `ohm` and `percent` become `°`, `°C`, `Ω`, `%`. Degrees sit flush against the value; every other unit
  follows a thin space.
- **In text**, `#qty(1/2, "m")` is code arithmetic and prints `0.5 m`; for the
  fraction write `$qty(1/2, "m")$` or `#qty("1/2", "m")` (a string that isn't a
  plain number is read as math).
- **Inside math**, write `e`-notation as a string or a code number —
  `qty("3e8", "m/s")` or `qty(#3e8, "m/s")` — since Typst reads a bare `3e8` there
  as `3` followed by a variable `e8`.

### Carried over on purpose


- **Quantifier spacing.** Typst puts no space before ∀ ∃ ∄ (`0 ∃x` is spaced like
  `0x`), so the package adds it, with nothing extra typed:
  - **thick** (5/18 em, like `\;`) where a phrase ends: `∀ε > 0 ∃δ > 0`,
    `∀x ∈ X ∃y`, `∀x, y ∃z`;
  - **thin** (3/18 em, like `\,`) in a run of bare quantifiers, i.e. when the
    previous quantifier had just its variable: `∀x ∀y ∀z`, `∀x_1 ∃x_2`, `∃! x ∀y`;
  - **nothing** at the start, after a relation, arrow, operator, comma, colon,
    opening bracket, `¬` or a set-builder `|` (Typst spaces those itself), in sub-
    and superscripts, or where you put a space yourself (`thin`, `thick`, …).

  It works in text, displays and figure labels, for `∀ ∃ ∄` typed directly too.
- **`evaluated` brackets** never get smaller than LaTeX's `\bigl[ \bigr]`, and grow
  with their contents like every Typst delimiter.

No name in the package hides one of Typst's own — which is why the proposition
box is `proposition` (not `prop`, Typst's ∝), the evaluation bar `evaluated` (not
`eval`), and there's no `\green` (`green` is Typst's colour). The two overlaps are
`note`, which hides the ♪ symbol, and `qed`, which hides the ∎ symbol in math;
`sym.note` and `sym.qed` still reach them.

## Language (English ⇄ German)

Set per course in `course.typ`:

```typ
#let course = (title: "Analysis I", language: "german")   // or "english"
```

The notes and every exercise read it from there, so one edit switches the whole
course. Everything localizes at **compile time**: hyphenation and quotation marks,
every printed label (Theorem→Satz, Exercise→Aufgabe, Lecture→Vorlesung, Figure→
Abbildung, …), the lecture dates (stored as ISO `YYYY-MM-DD`, rendered with a
localized weekday + month, e.g. `Thu 11. Jun 2026` ↔ `Do 11. Jun 2026`), and an
exercise's default title (Problem Set N ↔ Übungsserie N). The function names you
type don't change.

The regional variant of each language is a per-person setting, not per course; see
[step 4](#4-set-your-name-and-region).

## Exercises

Exercise sessions live in `<course>/exercises/`, one self-contained mini-project per
session — each compiles to its **own** PDF.

1. With any file of the course open, run **Typst: New exercise** (title e.g.
   "Sheet 1", or blank for the localized "Problem Set N") → creates
   `exercises/ex_NN/main.typ`, using `#show: problem-set.with(course, number: N)`.
   A sheet numbers theorems, equations and figures straight through (1, 2, 3)
   instead of within a section, since it has no sections.
2. Drop the given problem set into that folder as `sheet.pdf`; to print it ahead of
   your solutions, set its page count in the `#include-pdf(...)` line and
   un-comment it. On a problem sheet its pages always come first, before your
   title, wherever the line stands; page numbers start at 1 on the title page.
3. Write solutions with one function per level, passing the number/letter — they
   format and indent like a real sheet (`1.` / `(a)` / `i.`) and the code says
   exactly which (sub)exercise each block is. Keep the preview open while you
   write; press <kbd>Cmd/Ctrl+Alt+B</kbd> for the PDF to hand in.

   ```typ
   #exercise(1)[
     #subexercise("a")[First part's answer…]
     #subexercise("b")[
       Second part's answer…
       #subsubexercise("i")[A sub-point…]
     ]
   ]
   #exercise(2)[…]
   ```

   Each label hangs in its own column, so everything inside an answer — wrapped
   lines, lists, display math (centred over the answer) — lines up under it at any
   depth, and anything after the exercises is back at the margin.

Figures work as in the notes: with an exercise open, **Typst: New figure** places it
in that exercise's `figures/`.

## Figures (Inkscape)

Vector drawings whose labels are typeset by Typst, in the document's font and size —
the same pipeline as LaTeX's `pdf_tex`.

- **Typst: New figure** (<kbd>Cmd/Ctrl+Alt+F</kbd> if bound) → name it → draw in
  Inkscape → save → paste the copied snippet into your document:

  ```typ
  #figure(include "../figures/light-cone.typ", caption: [Light Cone]) <fig:light-cone>
  ```

  The path is relative to the file you had open (Typst resolves includes from the
  including file), so it's right whether you paste it into a lecture or an
  exercise's `main.typ`. It compiles straight away — an empty placeholder of the
  right size stands in until the first save.
- Keep **Typst: Watch figures** running: each save in Inkscape exports the drawing
  to `<name>.pdf` (without its text) and writes `<name>.typ`, which places the PDF
  and every label. An open preview picks the new version up by itself.
- **Typst: Edit figure** reopens an existing figure's `.svg`; save and it
  re-exports.
- **Styling:** use Inkscape's **Fill & Stroke** dialog (<kbd>Ctrl+Shift+F</kbd>);
  copy a styled object and apply its look with **Paste Style**
  (<kbd>Ctrl+Shift+V</kbd>). Each new figure includes ready-made objects (arrows,
  axes) parked just below the page — copy them onto your page.
- **Labels:** type Typst markup straight into an Inkscape text object — `$gamma$`,
  `$1/2$`, `$sum_(i=1)^n i$`. Math is set in display style, so fractions, sums and
  integrals get their full-size form; `$x$` and `$ x $` both work. Course macros
  from `course.typ` work too. Colour, rotation, left/centre/right alignment and
  stacking order (a label under a filled shape stays under it) carry over from
  Inkscape.

## Editing the package

Edit the files under [`package/`](package/): [`lib.typ`](package/lib.typ) lists
what's exported, [`src/`](package/src) holds the implementation — templates and
header in `template.typ`, environments in `theorems.typ`, math in `math.typ`, units
in `units.typ`, every printed word in `labels.typ`. Changes apply to every document
on the next build, since the registered package is a link to this folder.

If you change the package's `version` in `package/typst.toml`, re-run
`scripts/install.py` and update the version in your courses' `course.typ` lines —
the scripts write new courses with the current one.

## Configuration — [`scripts/config.py`](scripts/config.py)

- `DEFAULT_LANGUAGE` — fallback language when a `course.typ` has none.
- `INKSCAPE`, `TYPST` — auto-detected per platform; set the environment variables of
  the same name to override.
- `DATE_FORMAT` — how lecture dates are stored (ISO `YYYY-MM-DD`); the package
  localizes them at compile time.
- `ROOT` — from `AJNOTES_ROOT` (set by the tasks) or the current directory; never
  set by hand.
- `PACKAGE` — `@local/<name>:<version>`, read from `package/typst.toml`.

## Differences from the LaTeX toolkit

- **One import line per file** instead of a preamble: Typst has no global package
  path for documents, so each file imports its `course.typ`. The scripts write it.
- **Answers are blocks, not running commands**: `#exercise(1)[…]` wraps its answer.
  That is what lets lists and display math inside an answer indent with it.
- **Equations are numbered only when labelled**, so plain `$ … $` stays clean.
- **A live preview instead of build-on-save**: the document re-renders as you
  type; compiling to `main.pdf` is a separate step for when you need the file.
- **No auxiliary files**: a build writes only `main.pdf`.
- **Language and title are per course** (in `course.typ`), not per document.
- **To-dos** are highlighted in the text rather than in the margin.

## License and credit

MIT — see [LICENSE](LICENSE). Built on [Gilles Castel's university
setup](https://github.com/gillescastel/university-setup) (MIT, © 2019 Gilles
Castel); the course/lecture handling and the figure workflow derive from it.
