// Drafting notes, after LaTeX's todonotes: #todo[check sign] marks the spot in
// the text, and #todo-list() lists every open one with its page.

#import "labels.typ": lbl

#let _todo-color = rgb("#ffcc80")

#let todo(body) = box(fill: _todo-color, inset: (x: 3pt, y: 2pt), outset: (y: 1pt), radius: 2pt)[
  #text(size: 0.85em)[#body]#metadata(body)<ajnotes-todo>
]

#let todo-list() = context {
  let items = query(<ajnotes-todo>)
  if items.len() == 0 { return none }
  block(above: 1.2em, below: 1.2em)[
    #strong(lbl("todo"))
    #for item in items [
      / #link(item.location())[#item.location().page()]: #item.value
    ]
  ]
}
