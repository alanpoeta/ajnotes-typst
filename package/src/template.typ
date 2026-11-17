// The two document templates, applied with a show rule at the top of a document:
//
//   #show: notes.with(course)                      notes/main.typ
//   #show: problem-set.with(course, number: 3)     exercises/ex_03/main.typ
//
// `course` is the dictionary from the course's course.typ (title, language).

#import "settings.typ": env, mode, lang-settings, section-offset, theorem-offset, section-number
#import "labels.typ": label-text, lbl
#import "theorems.typ": show-theorems, show-numbered-plain, numbered-kinds, thm-kind, bookmark-label, qed-in-equation
#import "structure.typ": lecture-label, part-label
#import "math.typ": space-quantifiers
#import "figures.typ": attached-sheets

// --- Running header -------------------------------------------------------------
// The author's name on the left (handy for open-book exam prints) and the current
// section on the right, over a thin rule. When they don't both fit it degrades in
// steps:
//   1. both fit        -> full name, full title
//   2. too wide        -> "A. B. Lovelace", then "A. B. L."
//   3. still too wide  -> no name; a title too long on its own is cut with "…"
#let header-gap = 1.5em

#let _initial(word) = word.clusters().first() + "."
#let _short-name(name) = {
  let words = name.split(" ").filter(w => w != "")
  if words.len() < 2 { return name }
  (words.slice(0, -1).map(_initial) + (words.last(),)).join(" ")
}
#let _initials(name) = name.split(" ").filter(w => w != "").map(_initial).join(" ")

// The section at the bottom of the page, as LaTeX's \leftmark: the last section
// heading on this page or, failing that, before it.
#let _current-section() = {
  let page = here().page()
  let secs = query(heading.where(level: 1)).filter(s => (
    s.location().page() <= page and s.at("label", default: none) not in (bookmark-label, part-label)
  ))
  if secs.len() == 0 { return none }
  let sec = secs.last()
  if sec.numbering == none { sec.body } else {
    [#numbering(sec.numbering, ..counter(heading).at(sec.location()))#h(1em)#sec.body]
  }
}

#let _header(author) = context {
  if here().page() == 1 { return none }
  let section = _current-section()
  let line = layout(size => {
    let avail = size.width
    let tw = if section == none { 0pt } else { measure(section).width }
    let fits(name) = measure(name).width + header-gap.to-absolute() + tw <= avail
    let name = author
    for candidate in (author, _short-name(author), _initials(author)) {
      name = candidate
      if fits(candidate) { break }
      name = none
    }
    if name != none { [#name#h(1fr)#section] } else if tw <= avail { [#h(1fr)#section] } else {
      let dots = […]
      let cut = avail - measure(dots).width
      [#box(width: cut, clip: true, box(width: tw, section))#dots]
    }
  })
  block(width: 100%, below: 0pt, stroke: (bottom: 0.4pt), inset: (bottom: 3pt), line)
}

#let _footer = context align(right, counter(page).display())

// --- Shared setup -----------------------------------------------------------------
// enumerate levels, as in LaTeX
#let _enum-levels = ("1.", "(a)", "i.", "A.")

#let _setup(course, author, body) = {
  let author = if author == auto { env.author } else { author }
  set document(title: course.title, author: author)
  set text(font: "New Computer Modern", size: 10pt, ..lang-settings(course.at("language", default: "english")))
  // LaTeX article on A4 at 10pt: a 345pt text block, centred.
  set page(
    paper: "a4",
    margin: (x: 125pt, top: 127.5pt, bottom: 120pt),
    header: _header(author),
    header-ascent: 31pt,
    footer: _footer,
    footer-descent: 22pt,
  )
  // parskip: no indent, half a line between paragraphs.
  set par(justify: true, leading: 0.52em, spacing: 1.12em, first-line-indent: 0pt)
  set list(indent: 1em, body-indent: 0.6em)
  set enum(indent: 1em, body-indent: 0.6em, numbering: _enum-levels.first())
  // Nested lists step through the levels like LaTeX's enumerate: 1. → (a) → i. → A.
  // A list with your own numbering (e.g. "(a)") continues from that level; any
  // other pattern is left alone.
  show enum: it => {
    let i = _enum-levels.position(l => l == it.numbering)
    if i == none { return it }
    set enum(numbering: _enum-levels.at(calc.rem(i + 1, _enum-levels.len())))
    it
  }
  show math.equation: set text(font: "New Computer Modern Math")
  show raw: set text(font: ("New Computer Modern Mono", "DejaVu Sans Mono"))
  set bibliography(style: "ieee")

  // Headings like LaTeX's \section / \subsection / \subsubsection: bold, \Large /
  // \large / normal size, a quad after the number.
  // Heading numbers count from `first-section` (a course may start at 0).
  set heading(numbering: (..n) => context {
    let nums = n.pos()
    numbering("1.1", nums.first() + section-offset.get(), ..nums.slice(1))
  })
  show heading: it => {
    if it.at("label", default: none) == bookmark-label { return it }
    // A part: a large centred title in the flow; it doesn't restart any counter.
    if it.at("label", default: none) == part-label {
      return block(width: 100%, above: 2.6em, below: 1.6em, sticky: true, align(center, text(size: 17.28pt, weight: "bold", it.body)))
    }
    let size = (14.4pt, 12pt, 10pt).at(calc.min(it.level, 3) - 1)
    let (above, below) = ((2.1em, 1.1em), (1.9em, 1em), (1.6em, 0.9em)).at(calc.min(it.level, 3) - 1)
    // A new section restarts the numbers that count within it (not the contents
    // title or an unnumbered heading, which aren't sections).
    if it.level == 1 and it.numbering != none {
      counter(figure.where(kind: thm-kind)).update(0)
      for k in numbered-kinds { counter(figure.where(kind: k)).update(0) }
      counter(figure.where(kind: image)).update(0)
      counter(figure.where(kind: table)).update(0)
      // Equation numbers carry their section in the counter (section * 1000 + n):
      // a reference is numbered where it stands, not where the equation is, so the
      // section has to be part of the value for "(2.1)" to survive being cited
      // from section 5. Typst steps the counter by one per numbered equation.
      context counter(math.equation).update(
        (counter(heading).at(it.location()).first() + section-offset.get()) * 1000)
    }
    set text(size: size, weight: "bold")
    set par(justify: false)
    block(above: above, below: below, sticky: true, {
      if it.numbering != none { counter(heading).display(it.numbering); h(1em) }
      it.body
    })
  }

  // Equations are numbered only when labelled — the $ ... $ you don't refer to
  // stays clean, like \[ ... \] against \begin{equation}. "(2.1)" in the notes,
  // "(1)" on a problem sheet.
  set math.equation(numbering: (..n) => context {
    if mode.get() == "exercise" { numbering("(1)", ..n) } else {
      let v = n.pos().first()
      numbering("(1.1)", calc.quo(v, 1000), calc.rem(v, 1000))
    }
  })
  // Every equation shown is rebuilt (once — the <ajnotes-unnumbered> label marks
  // the rebuilt one), so a displayed equation gets its quantifier spacing (see
  // space-quantifiers), a possible qed, and its numbering in one place. A rebuilt
  // equation is a new element: the original's counter step is undone first, and
  // references to a label still resolve to the original, at the same number.
  show math.equation.where(block: true): it => {
    if it.at("label", default: none) == <ajnotes-unnumbered> { return it }
    let (body, spaced) = space-quantifiers(it.body)
    // A display ending in qed: □ at the right margin (see qed-in-equation).
    let with-qed = qed-in-equation(it, body: body)
    if with-qed != none { return with-qed }
    let undo = counter(math.equation).update(v => v - 1)
    if it.has("label") {
      if not spaced { return it }
      return [#undo#math.equation(body, block: true)<ajnotes-unnumbered>]
    }
    [#undo#math.equation(body, block: true, numbering: none)<ajnotes-unnumbered>]
  }
  // Inline equations aren't numbered, so they're only rebuilt when a quantifier
  // needs space; a second pass finds nothing to change and stops. A label (only
  // set by the figure overlay) is kept.
  show math.equation.where(block: false): it => {
    let (body, spaced) = space-quantifiers(it.body)
    if not spaced { return it }
    let eq = math.equation(body, block: false)
    if it.has("label") [#eq#it.label] else { eq }
  }
  set figure(numbering: (..n) => context {
    if mode.get() == "exercise" { numbering("1", ..n) } else {
      numbering("1.1", section-number(), ..n)
    }
  })

  show: show-theorems
  show: show-numbered-plain
  // How the course counts (see settings.typ): sections from `first-section`,
  // theorems from `theorem-from`, both 1 unless the course says otherwise.
  section-offset.update(course.at("first-section", default: 1) - 1)
  theorem-offset.update(course.at("theorem-from", default: 1) - 1)
  body
}

// Title block like LaTeX's \maketitle (no date: notes span many lectures, and
// each lecture shows its own date).
#let _title-block(title, author) = {
  set align(center)
  v(1.5em)
  block(text(size: 17.28pt, title))
  v(0.9em)
  block(text(size: 12pt, author))
  v(2.2em)
}

// --- Notes ---------------------------------------------------------------------------
#let notes(course, author: auto, contents: true, body) = {
  show: _setup.with(course, author)
  mode.update("notes")
  _title-block(course.title, if author == auto { env.author } else { author })
  if contents {
    // Table of contents like LaTeX's: sections bold with no leaders, the rest
    // dotted.
    show outline.entry.where(level: 1): it => {
      v(0.9em, weak: true)
      strong(link(it.element.location(), it.indented(it.prefix(), [#it.body()#h(1fr)#it.page()])))
    }
    outline(title: context label-text("contents"), indent: auto, depth: course.at("toc-depth", default: 3))
    pagebreak(weak: true)
  }
  body
}

// --- Problem sets -------------------------------------------------------------------
// The default title is "<course> — Problem Set N" / "<course> — Übungsserie N",
// localized when typeset; pass title: to use your own after the course name.
// Numbering runs straight through (1, 2, 3) since a sheet has no sections.
#let problem-set(course, number: none, title: none, author: auto, body) = {
  show: _setup.with(course, author)
  mode.update("exercise")
  let name = if title != none { title } else [#lbl("problemset") #number]
  attached-sheets()
  _title-block([#course.title — #name], if author == auto { env.author } else { author })
  body
}
