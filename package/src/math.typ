// Math additions. Typst already has much of what the LaTeX preamble added by
// hand: NN RR ZZ QQ CC, abs() norm() floor() ceil(), gcd lcm, cancel(),
// bold(), scr(), dif and partial, and epsilon is the curly ε. What's here fills
// the gaps.

// --- Quantifier spacing -----------------------------------------------------
// Typst puts no space before ∀ ∃ ∄ — "0 ∃" is spaced like "0x". So the templates
// walk each formula and add space before a quantifier where a term precedes it:
//
//   ∀ε > 0 ∃δ > 0      thick (5/18 em) — the previous quantifier's phrase ended
//   ∀x ∀y ∀z           thin (3/18 em) — a run of bare quantifiers, i.e. the
//                      previous quantifier had just its variable (x, x_1, x')
//
// and nothing at the start, after a relation, arrow, operator, comma, colon,
// opening bracket, ¬ or a set-builder bar — Typst spaces those itself — nor where
// you put a space by hand (thin, thick, …). Sub- and superscripts are left alone.
//
// This looks at what precedes each quantifier, which no math-class trick can do:
// both math engines only make a thick space next to a relation, and a relation
// right after another one (⟹ ∀) gets none.

#let _quantifiers = ("∀", "∃", "∄")
#let _space = [ ].func()
#let _seq = [a#[b]].func()
#let _align-point = $&$.body.func()

#let _non-space(items) = items.filter(c => c.func() != _space)

// A quantifier, or a group starting with one (∃!).
#let _is-quantifier(c) = {
  if c.has("text") { return c.text in _quantifiers }
  if c.func() == _seq {
    let kids = _non-space(c.children)
    return kids.len() > 0 and _is-quantifier(kids.first())
  }
  false
}

// Does `c` end a term — something a quantifier after it needs space from?
#let _ends-term(c) = {
  if c.has("text") {
    if c.text in _quantifiers { return false }
    return c.text.match(regex("^(\p{L}+|[\p{N}.]+|[)\]}⟩⌉⌋∞∅′″])$")) != none
  }
  let f = c.func()
  if f in (h, linebreak, math.op, _align-point) { return false }
  if f == math.class { return c.class in ("normal", "closing") }
  if f == _seq {
    let kids = _non-space(c.children)
    return kids.len() > 0 and not _is-quantifier(kids.first()) and _ends-term(kids.last())
  }
  // Variables with indices, brackets, fractions, roots, accents — and content
  // that is only filled in later (context, nested equations): a term.
  true
}

// A bare variable: one letter, possibly with an index or primes.
#let _is-variable(c) = {
  if c.func() == math.attach { return _is-variable(c.base) }
  c.has("text") and c.text.clusters().len() == 1 and c.text.match(regex("^\p{L}$")) != none
}

// The space to add before the quantifier at `i`, given its siblings, or none.
#let _space-before(items, i) = {
  let before = _non-space(items.slice(0, i))
  if before.len() == 0 or not _ends-term(before.last()) { return none }
  if before.len() >= 2 and _is-variable(before.last()) and _is-quantifier(before.at(-2)) {
    return h(1em / 6)
  }
  h(5em / 18)
}

// Returns (body, changed). Recurses into groups, brackets, fractions and roots;
// unchanged content is returned as is, so applying it twice changes nothing.
#let space-quantifiers(c) = {
  let f = c.func()
  if f == _seq {
    let changed = false
    let kids = ()
    for k in c.children {
      let (k2, ch) = space-quantifiers(k)
      kids.push(k2)
      changed = changed or ch
    }
    let out = ()
    for (i, k) in kids.enumerate() {
      if _is-quantifier(k) {
        let gap = _space-before(kids, i)
        if gap != none { out.push(gap); changed = true }
      }
      out.push(k)
    }
    return if changed { (out.join(), true) } else { (c, false) }
  }
  if f == math.lr {
    let (b, ch) = space-quantifiers(c.body)
    return if ch { (math.lr(b, ..c.fields().pairs().filter(p => p.first() == "size").to-dict()), true) } else { (c, false) }
  }
  if f == math.frac {
    let (n, ch1) = space-quantifiers(c.num)
    let (d, ch2) = space-quantifiers(c.denom)
    return if ch1 or ch2 { (math.frac(n, d), true) } else { (c, false) }
  }
  if f == math.root {
    let (r, ch) = space-quantifiers(c.radicand)
    return if ch { (math.root(c.at("index", default: none), r), true) } else { (c, false) }
  }
  if f == math.class {
    let (b, ch) = space-quantifiers(c.body)
    return if ch { (math.class(c.class, b), true) } else { (c, false) }
  }
  (c, false)
}

// --- Operators ----------------------------------------------------------------
// gcd and lcm are built in. ggT and kgV are the German names, kept separate so a
// document can use either set deliberately.
#let ggT = math.op("ggT")
#let kgV = math.op("kgV")

// --- Integral evaluation ----------------------------------------------------------
//   $integral_a^b f'(x) dif x = evaluated(f(x))_a^b$
// The brackets grow with their contents like every Typst delimiter, but never get
// smaller than LaTeX's \bigl[ \bigr]: plain [ ] hugs short contents like f(x) far
// too closely for an evaluation bar. An invisible strut sets that minimum.
// size: forces a size relative to the contents, e.g. evaluated(f(x), size: #150%).
//
// Named `evaluated` rather than LaTeX's \eval, which would hide Typst's own
// eval() function.
#let _eval-strut = box(height: 0.85em, baseline: 0.35em)
#let evaluated(body, size: 100%) = math.lr(
  math.class("opening", "[") + _eval-strut + body + math.class("closing", "]"),
  size: size,
)

// --- Derivatives -----------------------------------------------------------------
// No macro needed: Typst's dif is the upright differential, so
//   (dif f)/(dif x)   dif/(dif t) v   (dif^2 f)/(dif x^2)   (partial f)/(partial y)
// typeset exactly as LaTeX's derivative package did, and integral f(x) dif x
// gets the right spacing too.

// --- Small helpers --------------------------------------------------------------
// Contradiction mark: ↯, a little larger than text. Works in text and math.
#let contra = box(scale(150%, reflow: true, sym.arrow.zigzag))

// Short corrections: 1 + 1 = #correct[3][2] (or correct(3, 2) inside math).
#let correct-green = rgb("#009900")
#let correct(wrong, right) = [#h(0.22em)#text(fill: red, wrong)#h(0.1em)$->$#h(0.1em)#text(fill: correct-green, right)#h(0.22em)]
