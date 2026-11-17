// Inkscape figures whose labels are typeset by Typst, like LaTeX's pdf_tex.
//
// scripts/figures.py exports a figure's .svg with Inkscape as a PDF *without* its
// text, and writes figures/<name>.typ, which calls inkscape-figure() with the
// PDF's pages and every label's position. Include it where the figure goes:
//
//   #figure(include "figures/light-cone.typ", caption: [Light cone]) <fig:light-cone>
//
// The figure spans the full text width, like LaTeX's \svgwidth=\columnwidth, and
// labels are set in the document's font at the document's size, whatever size
// they had in Inkscape. Write Typst markup in Inkscape text objects: $gamma$,
// $1/2$ — math is set in display style, so fractions, sums and integrals get
// their full-size form, and both $x$ and $ x $ work.

#import "math.typ": space-quantifiers
#import "settings.typ": mode

#let _figmath = <ajnotes-figure-math>

// layers: drawing pages and labels in Inkscape's stacking order. A drawing page
// is a path to the PDF plus its page number; a label is a dictionary
// (x, y, align, angle, color, lines) in Inkscape's units: x and y are fractions of
// the figure width, y measured up from the bottom; align is "l", "c" or "r".
// scope: names available to label markup — the generated file passes the
// course module, so course macros work in labels too.
#let inkscape-figure(aspect: 1, layers: (), scope: (:)) = layout(size => {
  let w = size.width
  let h = w * aspect
  box(width: w, height: h, {
    show math.equation: it => {
      if it.at("label", default: none) == _figmath { it } else [#math.equation(math.display(space-quantifiers(it.body).first()), block: false)#_figmath]
    }
    for layer in layers {
      if "page" in layer {
        place(top + left, image(layer.file, page: layer.page, width: w, height: h))
        continue
      }
      for (i, line) in layer.lines.enumerate() {
        let body = std.eval(line, mode: "markup", scope: scope)
        let c = text(top-edge: "bounds", bottom-edge: "baseline", fill: layer.at("color", default: black), body)
        let m = measure(c)
        // Inkscape anchors a label at its first baseline; lines follow 1.25em apart.
        let off = if layer.align == "r" { m.width } else if layer.align == "c" { m.width / 2 } else { 0pt }
        let shifted = move(dx: -off, dy: -m.height + i * 1.25em, c)
        let angle = layer.at("angle", default: 0)
        place(top + left, dx: layer.x * w, dy: h - layer.y * w, if angle == 0 { shifted } else {
          rotate(-angle * 1deg, origin: top + left, reflow: false, shifted)
        })
      }
    }
  })
})

// Attach a PDF (e.g. the given problem sheet) as full pages:
//   #include-pdf(path("sheet.pdf"), pages: 3)
// The path must be written with path(...) so it resolves next to your document.
// On a problem sheet the pages always come first, before the title and the
// solutions, wherever the line is written; elsewhere they appear where it is.
#let _pdf-pages(file, pages) = {
  for p in range(1, pages + 1) {
    page(margin: 0pt, header: none, footer: none, image(file, page: p, width: 100%, height: 100%, fit: "contain"))
  }
}
#let sheet-label = <ajnotes-sheet>
#let include-pdf(file, pages: 1) = context {
  if mode.get() == "exercise" { [#metadata((file: file, pages: pages))#sheet-label] } else { _pdf-pages(file, pages) }
}
// Used by problem-set: the attached sheets, then the page counter restarts at 1.
#let attached-sheets() = context {
  let sheets = query(sheet-label)
  for s in sheets { _pdf-pages(s.value.file, s.value.pages) }
  if sheets.len() > 0 { counter(page).update(1) }
}
