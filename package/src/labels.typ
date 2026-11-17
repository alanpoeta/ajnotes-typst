// Every word the package prints, in both languages. They are looked up from
// text.lang at the point of use, so a document switches entirely by changing
// its language — nothing is fixed when the package loads.

#let labels = (
  en: (
    theorem: "Theorem",
    definition: "Definition",
    property: "Property",
    lemma: "Lemma",
    prop: "Proposition",
    corollary: "Corollary",
    law: "Law",
    postulate: "Postulate",
    conclusion: "Conclusion",
    bonus: "Bonus",
    conjecture: "Conjecture",
    example: "Example",
    unexample: "Non-example",
    notation: "Notation",
    previouslyseen: "As previously seen",
    recap: "Recap",
    intermezzo: "Intermezzo",
    remark: "Remark",
    note: "Note",
    observe: "Observe",
    intuition: "Intuition",
    practical: "Practical",
    problem: "Problem",
    terminology: "Terminology",
    application: "Application",
    exercise: "Exercise",
    question: "Question",
    proof: "Proof",
    lecture: "Lecture",
    problemset: "Problem Set",
    contents: "Contents",
    todo: "To do",
  ),
  de: (
    theorem: "Satz",
    definition: "Definition",
    property: "Eigenschaft",
    lemma: "Lemma",
    prop: "Proposition",
    corollary: "Korollar",
    law: "Gesetz",
    postulate: "Postulat",
    conclusion: "Folgerung",
    bonus: "Bonus",
    conjecture: "Vermutung",
    example: "Beispiel",
    unexample: "Unbeispiel",
    notation: "Notation",
    previouslyseen: "Wie zuvor gesehen",
    recap: "Zusammenfassung",
    intermezzo: "Intermezzo",
    remark: "Bemerkung",
    note: "Anmerkung",
    observe: "Beobachtung",
    intuition: "Intuition",
    practical: "Praktischer Hinweis",
    problem: "Problem",
    terminology: "Terminologie",
    application: "Anwendung",
    exercise: "Aufgabe",
    question: "Frage",
    proof: "Beweis",
    lecture: "Vorlesung",
    problemset: "Übungsserie",
    contents: "Inhaltsverzeichnis",
    todo: "Zu erledigen",
  ),
)

#let months = (
  en: ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"),
  de: ("Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"),
)
#let weekdays = (
  en: ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"),
  de: ("Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"),
)

// The table key for the current language; call inside context.
#let lang-key() = if text.lang == "de" { "de" } else { "en" }

// A label as a plain string; call inside context.
#let label-text(key) = labels.at(lang-key()).at(key)

// A label as content that localizes wherever it is placed, e.g. #lbl("lecture").
#let lbl(key) = context label-text(key)

// "2026-06-11" -> "Thu 11. Jun 2026" / "Do 11. Jun 2026"; call inside context.
#let format-date(iso) = {
  let parts = iso.split("-").map(int)
  let d = datetime(year: parts.at(0), month: parts.at(1), day: parts.at(2))
  let k = lang-key()
  [#weekdays.at(k).at(d.weekday() - 1) #d.day(). #months.at(k).at(d.month() - 1) #d.year()]
}
