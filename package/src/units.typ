// Quantities and units. One function for a value with or without a unit, and
// one for a unit on its own:
//
//   #qty("9.81", "m/s^2")                     9.81 m over s² (a fraction)
//   #qty("9.81", "m \/ s^2")                  9.81 m/s²
//   #qty("6.674e-11", "m^3 kg^(-1) s^(-2)")   6.674 · 10⁻¹¹ m³ kg⁻¹ s⁻²
//   #qty("12345.6")   #qty(42)                a number alone: 12,345.6   42
//   #qty(30, "deg")   #qty(5, "%")            30°   5 %
//   #unit("(kg m)/s^2")                       kg m over s²
//
// The value can be any math, not just a number — a fraction, a root, a whole
// expression — and the unit still follows with the right spacing:
//
//   $qty(sqrt(2)/2, "m")$   $qty(1/2 g t^2, "m")$   #qty("sqrt(2)/2", "m")
//
// A plain number gets number formatting (digit grouping, the decimal marker
// from env.typ, e-notation as a power of ten, "+-" as an uncertainty); anything
// else is set as written. Inside math, write e-notation as a string or a code
// number — qty("3e8", "m/s") or qty(#3e8, "m/s") — since Typst reads a bare 3e8
// there as 3 followed by a variable e8.
//
// A unit is Typst math (see _unit-source below): a space is a product, / a
// fraction, \/ a slash, ^ a power — but letters form upright unit names. A few
// names map to symbols: ohm → Ω, deg/degree → °, degC/celsius → °C, percent → %.
//
// Both return an inline equation, so they work in text and inside math alike.

#import "settings.typ": env

// Number formats. none in env.typ means the house style; a preset name or a
// dictionary of the three parts switches one language.
#let _thin = sym.space.thin
#let _presets = (
  house: (decimal: ".", group: ",", product: "·"),
  DE: (decimal: ",", group: _thin, product: "·"),
  FR: (decimal: ",", group: _thin, product: "×"),
  UK: (decimal: ".", group: _thin, product: "×"),
  US: (decimal: ".", group: _thin, product: "×"),
)
#let _format() = {
  let choice = if text.lang == "de" { env.german-numbers } else { env.english-numbers }
  if choice == none { _presets.house } else if type(choice) == str { _presets.at(choice) } else {
    _presets.house + choice
  }
}

// A separator character set without the spacing math gives "," or "·" on its own.
#let _sep(s) = if type(s) == str { math.class("normal", s) } else { s }

// Group digits in threes (siunitx groups once a part has 5+ digits). Integer
// parts group from the right, decimal parts from the left.
#let _group(digits, sep, from-left: false) = {
  if digits.len() < 5 { return digits }
  let chunks = ()
  if from-left {
    let i = 0
    while i < digits.len() {
      chunks.push(digits.slice(i, calc.min(i + 3, digits.len())))
      i += 3
    }
  } else {
    let i = digits.len()
    while i > 0 {
      chunks.insert(0, digits.slice(calc.max(i - 3, 0), i))
      i -= 3
    }
  }
  chunks.join(_sep(sep))
}

#let _minus(s) = s.replace("-", "−")

#let _number-re = regex("^([+-]?)([0-9]*)(?:\\.([0-9]*))?(?:[eE]([+-]?[0-9]+))?$")

// One number (no uncertainty) as math content.
#let _number(s, fmt) = {
  let m = s.match(_number-re)
  let (sign, int-part, dec-part, exp) = m.captures
  let mant = ()
  if sign == "-" { mant.push("−") }
  if int-part != "" or dec-part != none {
    mant.push(_group(if int-part == "" { "0" } else { int-part }, fmt.group))
    if dec-part != none and dec-part != "" {
      mant.push(_sep(fmt.decimal))
      // Decimal digits are grouped only with a spacing separator: "0.123,45"
      // would read as two numbers.
      mant.push(if type(fmt.group) == str { dec-part } else { _group(dec-part, fmt.group, from-left: true) })
    }
  }
  let mant = mant.join()
  if exp == none { return mant }
  let power = math.attach("10", t: _minus(exp.trim("+")))
  if mant == none { power } else {
    mant + math.class("binary", if fmt.product == "×" { sym.times } else { sym.dot.op }) + power
  }
}

// A float back to text. str() writes 6.674e-11 out positionally, so very large or
// small values are put into e-notation here, rounded to 14 significant digits to
// drop binary noise (0.1 + 0.2 → 0.3).
#let _float-text(x) = {
  if x == 0 { return "0" }
  let e = calc.floor(calc.log(calc.abs(x), base: 10))
  if e >= 6 or e < -4 {
    let m = calc.round(x / calc.pow(10.0, e), digits: 13)
    let ms = str(m)
    if ms.ends-with(".0") { ms = ms.slice(0, -2) }
    ms + "e" + str(e)
  } else {
    let r = str(calc.round(x, digits: calc.max(0, 13 - e)))
    if r.ends-with(".0") { r.slice(0, -2) } else { r }
  }
}

// The text of content that is only text (a number typed inside math arrives as
// text, a negative one as a sequence of "−" and digits); none if it holds any
// real math, like a fraction.
#let _plain-text(c) = {
  if c.has("text") { return c.text }
  if c.has("children") {
    let parts = c.children.map(_plain-text)
    if none in parts { return none }
    return parts.join()
  }
  if c.func() == [ ].func() { return "" }
  none
}

// The value as text if it is a plain number (with an optional "+-" uncertainty),
// else none.
#let _numeric-text(value) = {
  let s = if type(value) == float { _float-text(value) } else if type(value) in (int, decimal, str) {
    str(value)
  } else if type(value) == content { _plain-text(value) } else { none }
  if s == none { return none }
  let s = s.replace("−", "-").replace(" ", "").trim()
  if s.split("+-").all(part => part.match(_number-re) != none and part != "") { s } else { none }
}

// The value as math: formatted when it's a number, otherwise set as written —
// content as it is, a string read as math.
#let _value-content(value) = {
  let s = _numeric-text(value)
  if s != none {
    let fmt = _format()
    let parts = s.split("+-")
    if parts.len() == 2 {
      _number(parts.at(0), fmt) + math.class("binary", sym.plus.minus) + _number(parts.at(1), fmt)
    } else { _number(s, fmt) }
  } else if type(value) == str {
    std.eval(value, mode: "math")
  } else { value }
}

// --- Units ---------------------------------------------------------------------
#let _aliases = (
  ohm: "Ω", deg: "°", degree: "°", degC: "°C", celsius: "°C", percent: "%",
)

// A unit is written in Typst math syntax — space for a product, / for a fraction
// (with ( ) to group, dropped in the output), \/ for a slash, ^ for powers,
// ^(-1) for negative ones — with one difference from math mode: a run of
// letters is a unit name, set upright as one symbol ("kg", "Hz", "°C"), not an
// unknown variable. A name directly followed by "(" is left as a function, so
// sqrt(Hz) works.
//
// It's turned into Typst math source with every unit name quoted and evaluated.
// The source is written without spaces: in math, a space next to quoted text is
// typeset, so products get exactly one thin space and the rest none.
#let _unit-token = regex("[\\p{L}\\p{M}°%]+|\\s+|\\\\/|[0-9]+(?:\\.[0-9]+)?|.")
#let _is-name(t) = t.match(regex("^[\\p{L}\\p{M}°%]+$")) != none
#let _is-number(t) = t.match(regex("^[0-9]")) != none
#let _is-space(t) = t.trim() == ""

#let _unit-source(u) = {
  let toks = u.trim().matches(_unit-token).map(m => m.text)
  let ends-atom(t) = _is-name(t) or _is-number(t) or t == ")"
  let starts-atom(t) = _is-name(t) or _is-number(t) or t == "("
  let src = ""
  for (i, t) in toks.enumerate() {
    if _is-space(t) {
      // A space between two factors is a product; any other space is layout.
      let prev = toks.slice(0, i).filter(x => not _is-space(x))
      let next = toks.slice(i + 1).filter(x => not _is-space(x))
      if prev.len() > 0 and next.len() > 0 and ends-atom(prev.last()) and starts-atom(next.first()) {
        src += "thin "
      }
    } else if _is-name(t) {
      let called = i + 1 < toks.len() and toks.at(i + 1) == "("
      src += if called { t } else { "\"" + _aliases.at(t, default: t) + "\"" }
    } else {
      src += t
    }
  }
  src
}

#let _unit-content(u) = std.eval(_unit-source(u), mode: "math")

#let unit(u) = math.equation(block: false, _unit-content(u))

// qty(value) or qty(value, unit). Degrees and angle marks sit flush against the
// value, as in siunitx; every other unit (including %) follows a thin space.
#let qty(value, ..unit-arg) = {
  let rest = unit-arg.pos()
  assert(rest.len() <= 1, message: "qty takes a value and at most one unit, e.g. qty(\"9.81\", \"m/s^2\")")
  assert(unit-arg.named().len() == 0, message: "qty takes no named arguments")
  context {
    let body = _value-content(value)
    if rest.len() == 1 {
      let u = rest.first()
      let tight = u.trim() in ("°", "deg", "degree", "'", "\"")
      body = body + (if tight { none } else { _thin }) + _unit-content(u)
    }
    math.equation(block: false, body)
  }
}
