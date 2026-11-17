// Lectures and exercise answers.

#import "labels.typ": label-text, format-date

// --- Lectures ---------------------------------------------------------------------
//   #lecture(1, "2026-06-11", "Introduction")
//
// A heading "1  Lecture: Introduction" at subsection size, with the date flush
// right on the same line: small, sans-serif, normal weight. The date is stored as
// ISO YYYY-MM-DD and localized when typeset ("Thu 11. Jun 2026" /
// "Do 11. Jun 2026"). If title and date don't fit on one line, the date moves to
// the next line, still flush right. Like LaTeX's \subsection*, it is unnumbered
// and not in the table of contents.
#let lecture-label = <ajnotes-lecture>

#let lecture(number, date, title) = context {
  let name = [#number#h(1em)#label-text("lecture")#if title not in (none, "", []) [: #title]]
  let stamp = text(font: ("New Computer Modern Sans", "New Computer Modern"), size: 0.75em, weight: "regular", format-date(date))
  [#heading(level: 2, numbering: none, outlined: false, bookmarked: false, layout(size => {
      let gap = 1em.to-absolute()
      if measure(name).width + gap + measure(stamp).width <= size.width {
        [#name#h(1fr)#stamp]
      } else {
        [#name#linebreak()#h(1fr)#stamp]
      }
    }))#lecture-label]
}

// --- Parts -----------------------------------------------------------------------
//   #part[Vector spaces]
// A large centred heading "Part I" / "Teil I" with the title below, in the flow of
// the text (no page break), and a bold entry in the table of contents. Parts are
// numbered I, II, III … by their own counter; section numbers carry on across them.
#let part-label = <ajnotes-part>
#let part-counter = counter("ajnotes-part")

#let part(body) = {
  part-counter.step()
  context {
    let n = part-counter.get().first()
    [#heading(level: 1, numbering: none, outlined: true, bookmarked: true)[#numbering("I", n)#h(1em)#body]#part-label]
  }
}

// --- Exercise answers ----------------------------------------------------------------
// One function per level, passing the number/letter, so the source says exactly
// which (sub)exercise each block is:
//
//   #exercise(1)[
//     #subexercise("a")[First part's answer…]
//     #subexercise("b")[
//       Second part…
//       #subsubexercise("i")[A sub-point…]
//     ]
//   ]
//
// The label hangs in a 2em column and the answer fills the rest, so everything in
// an answer — wrapped lines, lists, display math (centred over the answer, not the
// page) — lines up under its text, at any depth.
#let _answer(label, body, above) = block(above: above, below: 0.9em, breakable: true, grid(
  columns: (2em, 1fr),
  label, body,
))

#let exercise(n, body) = _answer([#n.], body, 1.8em)
#let subexercise(n, body) = _answer([(#n)], body, 1.2em)
#let subsubexercise(n, body) = _answer([#n.], body, 1.2em)
