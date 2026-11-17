// ajnotes — lecture notes and exercise solutions in Typst.
//
// A course imports this once, in its course.typ, and every document of the
// course imports course.typ, so a single line brings in the package and the
// course's own macros:
//
//   #import "../course.typ": *          (notes/main.typ and lectures: ../../)

#import "src/settings.typ": env, mode
#import "src/labels.typ": lbl, labels, format-date
#import "src/template.typ": notes, problem-set
#import "src/structure.typ": lecture, part, exercise, subexercise, subsubexercise
#import "src/theorems.typ": (
  theorem, definition, property, lemma, proposition, corollary, law, postulate,
  conclusion, bonus, conjecture, example, unexample, notation,
  previouslyseen, recap, intermezzo, remark, note, observe, intuition,
  practical, problem, terminology, application, exercisebox, question, proof, qed,
  boxed-plain, set-theorem-counter,
)
#import "src/math.typ": ggT, kgV, evaluated, contra, correct
#import "src/units.typ": qty, unit
#import "src/figures.typ": inkscape-figure, include-pdf
#import "src/misc.typ": todo, todo-list
