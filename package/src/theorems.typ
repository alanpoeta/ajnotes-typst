// Theorem-like environments, matching the LaTeX preamble:
//
//   #theorem[...]                   boxed, numbered (Satz 2.3)
//   #definition("Title")[...]       an optional title goes before the body
//   #example[...]                   unboxed, numbered (Beispiel 2.1), ends with ⋄
//   #proof[...]  #proof("Beweisidee")[...]   ends with □
//
// The boxed ones share one counter, so everything interleaves in one sequence
// (Definition 2.1, Satz 2.2, Lemma 2.3, …), numbered within the section in the
// notes and straight through on a problem sheet. Each can be labelled and
// referenced: #theorem[...] <pythagoras> … @pythagoras gives "Satz 2.2".

#import "labels.typ": label-text, lbl
#import "settings.typ": mode, section-number, theorem-offset

#let thm-kind = "ajnotes-theorem"
#let bookmark-label = <ajnotes-bookmark>

// "2.3" in the notes, "3" on a problem sheet. The section number is read where
// the theorem is, so references elsewhere show the theorem's own number.
#let thm-numbering(..nums) = {
  if mode.get() == "exercise" { numbering("1", ..nums) } else {
    numbering("1.1", section-number(), nums.pos().first() + theorem-offset.get())
  }
}

// Set the theorem counter, as LaTeX's \setcounter{theorem}{n}: the next theorem
// is number n (n + 1 in a course whose theorems start at 0).
#let set-theorem-counter(n) = counter(figure.where(kind: thm-kind)).update(n)

// Split (title?, body) from positional arguments.
#let _title-body(args) = {
  let pos = args.pos()
  if pos.len() >= 2 { (pos.at(0), pos.at(1)) } else { (none, pos.at(0)) }
}

#let _boxed(key) = (..args) => {
  let (title, body) = _title-body(args)
  figure(
    kind: thm-kind,
    supplement: lbl(key),
    numbering: thm-numbering,
    caption: if title == none { none } else { figure.caption(title) },
    outlined: false,
    // The key travels in the body so the show rule can name the bookmark.
    [#metadata(key)#body],
  )
}

// A boxed environment without a number, for courses where definitions and claims
// aren't numbered (the box and the bold head are the same):
//   #let definition = boxed-plain(lbl("definition"))
//   #let claim = boxed-plain("Behauptung")
#let boxed-plain(name) = (..args) => {
  let (title, body) = _title-body(args)
  block(width: 100%, stroke: 0.4pt, inset: (x: 10pt, y: 6pt), above: 1.2em, below: 1.2em, breakable: true)[
    #strong[#name]#if title != none [ (#title)]#strong[.]#h(0.5em)#body
  ]
}

// How boxed theorems look: a 0.4pt frame, the run-in head in bold, the optional
// title in parentheses at normal weight (amsthm's definition style). Each also
// gets a PDF bookmark ("Satz: Title", or "Satz 2.3" without one) one level below
// the current heading, so theorems can be clicked through in the viewer's
// sidebar; nothing changes on the page.
#let show-theorems(body) = {
  show figure.where(kind: thm-kind): set block(breakable: true)
  show figure.where(kind: thm-kind): it => context {
    // The key is the metadata the constructor put first in the body.
    let key = it.body.children.first().value
    let name = label-text(key)
    let number = it.counter.display(it.numbering)
    let title = if it.caption != none { it.caption.body } else { none }
    let headings = query(selector(heading).before(it.location())).filter(h => h.at("label", default: none) != bookmark-label)
    let level = if headings.len() == 0 { 1 } else { calc.min(headings.last().level + 1, 6) }
    let mark = if title == none [#name #number] else [#name: #title]
    place(hide[#heading(level: level, numbering: none, outlined: false, bookmarked: true, mark)#bookmark-label])
    set align(left)
    block(width: 100%, stroke: 0.4pt, inset: (x: 10pt, y: 6pt), above: 1.2em, below: 1.2em, breakable: true)[
      #strong[#name #number]#if title != none [ (#title)]#strong[.]#h(0.5em)#it.body
    ]
  }
  body
}

#let theorem = _boxed("theorem")
#let definition = _boxed("definition")
#let property = _boxed("property")
#let lemma = _boxed("lemma")
#let proposition = _boxed("prop")
#let corollary = _boxed("corollary")
#let law = _boxed("law")
#let postulate = _boxed("postulate")
#let conclusion = _boxed("conclusion")
#let bonus = _boxed("bonus")
#let conjecture = _boxed("conjecture")

// Unboxed, unnumbered: bold run-in head, upright body; some end with a mark set
// flush right on the last line.
#let _plain(key, end: none) = (..args) => {
  let (title, body) = _title-body(args)
  block(width: 100%, above: 1.2em, below: 1.2em, breakable: true)[
    #strong[#lbl(key)]#if title != none [ (#title)]#strong[.]#h(0.5em)#body#if end != none [#h(1fr)#end]
  ]
}

// Unboxed but numbered (example, remark): each has its own counter, numbered within
// the section like the boxed ones, and can be labelled and referenced:
// #example[...] <ex-a> … @ex-a gives "Beispiel 2.1".
#let numbered-kinds = ("ajnotes-example", "ajnotes-remark")
#let _plain-numbering(..nums) = {
  if mode.get() == "exercise" { numbering("1", ..nums) } else {
    numbering("1.1", section-number(), nums.pos().first())
  }
}
#let _plain-numbered(key, end: none) = (..args) => {
  let (title, body) = _title-body(args)
  figure(
    kind: "ajnotes-" + key,
    supplement: lbl(key),
    numbering: _plain-numbering,
    caption: if title == none { none } else { figure.caption(title) },
    outlined: false,
    [#metadata(end)#body],
  )
}
#let show-numbered-plain(body) = {
  show figure.where(kind: "ajnotes-example").or(figure.where(kind: "ajnotes-remark")): set block(breakable: true)
  show figure.where(kind: "ajnotes-example").or(figure.where(kind: "ajnotes-remark")): it => {
    let end = it.body.children.first().value
    let title = if it.caption != none { it.caption.body } else { none }
    set align(left)
    block(width: 100%, above: 1.2em, below: 1.2em, breakable: true)[
      #strong[#it.supplement #it.counter.display(it.numbering)]#if title != none [ (#title)]#strong[.]#h(0.5em)#it.body#if end != none [#h(1fr)#end]
    ]
  }
  body
}

#let _diamond = $diamond.small$
#let example = _plain-numbered("example", end: _diamond)
#let unexample = _plain("unexample", end: _diamond)
#let notation = _plain("notation")
#let previouslyseen = _plain("previouslyseen")
#let recap = _plain("recap")
#let intermezzo = _plain("intermezzo", end: _diamond)
#let remark = _plain-numbered("remark")
#let note = _plain("note")
#let observe = _plain("observe")
#let intuition = _plain("intuition")
#let practical = _plain("practical")
#let problem = _plain("problem")
#let terminology = _plain("terminology")
#let application = _plain("application")
#let exercisebox = _plain("exercise")
#let question = _plain("question")

// End-of-proof mark, like LaTeX's \qed: #qed puts □ flush right on the line
// where it's written, at least 1em after the text. If the line is too full for
// that, it goes flush right on the next line instead — not at the left, where a
// plain #h(1fr) would leave it after a wrap.
//
// How: a fixed-width slot for □ follows a fill, so the line breaker reserves
// room for it. Two markers — one before the fill, one inside the slot — show
// after layout whether the slot wrapped onto a new line; only then is □ moved
// to the right end of that line. (Typst allows a line break next to any inline
// box, so this can't be done with no-break characters alone.)
#let _qed-mark = text(font: "New Computer Modern Math", sym.square.stroked)
#let _qed-wrapped() = {
  let before = query(selector(<ajnotes-qed-a>).before(here())).last().location().position()
  let slot = query(selector(<ajnotes-qed-b>).before(here())).last().location().position()
  slot.y > before.y + 1pt
}
// The first marker sits outside the context, so a show rule can find #qed inside
// a display equation (see qed-in-equations below).
#let qed = [#metadata(none)<ajnotes-qed-a>#context [#h(1fr)#box(
    width: measure(_qed-mark).width + 1em,
  )[#metadata(none)<ajnotes-qed-b>#context if not _qed-wrapped() { align(right, _qed-mark) }]#context if _qed-wrapped() [#h(1fr)#_qed-mark]]]

// Is `c` the #qed above?
#let _is-qed(c) = (
  type(c) == content and c.has("children") and c.children.len() > 0
    and c.children.first().func() == metadata
    and c.children.first().at("label", default: none) == <ajnotes-qed-a>
)

// qed at the end of a display equation, like LaTeX's \qedhere:
//
//   $ a &= b \
//       &= c qed $
//
// puts □ at the right margin on the equation's last line — the slot an
// equation number would take — instead of on a line of its own. Applied by the
// templates to block equations; returns none for an equation without qed. An
// equation that is labelled (so numbered) keeps its number, and □ follows on
// the line below.
#let qed-in-equation(eq, body: auto) = {
  let body = if body == auto { eq.body } else { body }
  let children = if body.has("children") { body.children } else { (body,) }
  let rest = children.filter(c => not _is-qed(c))
  if rest.len() == children.len() { return none }
  // The equation shown is a new element, so the original's counter step is undone
  // first; references to a label still resolve to the original, at the same
  // number. (The update must be part of the returned content: `return` drops
  // anything a code block produced before it.)
  let undo = counter(math.equation).update(v => v - 1)
  if eq.has("label") {
    return [#undo#math.equation(rest.join(), block: true)<ajnotes-unnumbered>#qed]
  }
  // Shown with a "number" (the □), so it steps the counter too; undo that as well.
  [#undo#math.equation(rest.join(), block: true, numbering: _ => _qed-mark, number-align: end + bottom)<ajnotes-unnumbered>#undo]
}

// Does `body` already end with a □ — a #qed, or a display equation ending in
// qed? Then a proof doesn't add its own, as \qedhere does in LaTeX.
#let _ends-with-qed(body) = {
  let children = if body.has("children") { body.children } else { (body,) }
  let ignorable = (parbreak, linebreak, [ ].func())
  let rest = children.filter(c => c.func() not in ignorable)
  if rest.len() == 0 { return false }
  let last = rest.last()
  if _is-qed(last) { return true }
  if last.func() == math.equation and last.block {
    let eq-children = if last.body.has("children") { last.body.children } else { (last.body,) }
    return eq-children.any(_is-qed)
  }
  false
}

// amsthm's proof: italic "Proof." (or your own name, e.g. "Beweisidee"), □ at
// the end of the last line — or on the last equation's line, if the proof ends
// with $ … qed $.
#let proof(..args) = {
  let (name, body) = _title-body(args)
  block(width: 100%, above: 1.2em, below: 1.2em, breakable: true)[
    #emph[#if name == none { lbl("proof") } else { name }.]#h(0.5em)#body#if not _ends-with-qed(body) { qed }
  ]
}
