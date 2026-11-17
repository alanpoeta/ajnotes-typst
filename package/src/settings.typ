// Shared settings: the per-machine env, with defaults for anything it omits, and
// the document mode.

// env.typ is private and git-ignored; scripts/install.py creates it from
// env.example.typ, so it always exists once the package is registered.
#import "../env.typ": env as _user-env

#let env = (
  author: "Typst notes",
  german-region: "CH",
  english-region: "US",
  german-numbers: none,
  english-numbers: none,
) + _user-env

// "notes" or "exercise". Set by the templates; read it in context, e.g. to give
// a course macro different behaviour on a problem sheet:
//   #context if mode.get() == "exercise" [...] else [...]
#let mode = state("ajnotes-mode", "notes")

// How a course counts, set from its `course` dictionary by the templates:
//   first-section: 0   sections are numbered from 0 (default 1)
//   theorem-from: 0    theorems are numbered N.0, N.1, … in each section (default 1)
// The offsets are added to the counters when a number is displayed, so every
// number (headings, theorems, equations, figures, references) agrees.
#let section-offset = state("ajnotes-section-offset", 0)
#let theorem-offset = state("ajnotes-theorem-offset", 0)

// The current section number as displayed; call inside context.
#let section-number() = counter(heading).get().at(0, default: 0) + section-offset.get()

// Map the language names used by the scripts ("german"/"english") to text
// settings, including the regional variant chosen in env.typ.
#let lang-settings(language) = {
  if language in ("german", "de") {
    (lang: "de", region: env.german-region)
  } else {
    (lang: "en", region: env.english-region)
  }
}
