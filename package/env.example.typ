// Per-machine settings for ajnotes.
//
// scripts/install.py copies this file to env.typ (git-ignored) the first time it
// runs; edit env.typ, not this file. Every key is optional: delete a line and
// the default noted beside it applies.

#let env = (
  // Shown on the title page and in the running header.
  author: "Typst notes",

  // Regional variant of each language. It controls hyphenation and quotation
  // marks: "CH" gives «Swiss» quotes, "DE"/"AT" „German“ ones; "US" gives
  // “American” and "GB" ‘British’ quotes.
  german-region: "CH", // "CH" | "DE" | "AT"
  english-region: "US", // "US" | "GB"

  // Number formatting for #qty, per language. none keeps the house style
  // in both languages: decimal point, comma thousands separator and a "·"
  // before powers of ten (1,234.5 and 6.67·10⁻¹¹). Set a preset to switch that
  // language only:
  //   "DE"  1 234,5   6,67·10⁻¹¹   (decimal comma, thin-space groups)
  //   "FR"  1 234,5   6,67×10⁻¹¹
  //   "UK" / "US"  1 234.5   6.67×10⁻¹¹
  // or give the parts yourself, e.g. (decimal: ",", group: ".", product: "·").
  german-numbers: none,
  english-numbers: none,
)
