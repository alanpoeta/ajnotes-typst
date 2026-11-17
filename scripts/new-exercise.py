#!/usr/bin/env python3
"""Create a new exercise session as a standalone mini-project.

Usage:
    python scripts/new-exercise.py [course]
    python scripts/new-exercise.py --from-file path/to/lec_03.typ
    python scripts/new-exercise.py --from-file <file> --title "Sheet 1"

Each session lives in <course>/exercises/ex_NN/ with its own main.typ (compiled
to its own PDF beside it), plus a figures/ folder. Drop the given problem set
into the folder as sheet.pdf and, if you want it attached to your solutions,
un-comment the #include-pdf line in main.typ.
"""
import argparse
import re
import sys

from courses import get_course, exercise_projects
from utils import typst_content


EXERCISE_TEMPLATE = '''{course_import}
#show: problem-set.with(course, {title_arg})

// Attach the given problem sheet: drop it in this folder as sheet.pdf, set its
// page count and un-comment the next line.
// #include-pdf(path("sheet.pdf"), pages: 1)

#exercise(1)[
  #subexercise("a")[

  ]
]
'''


def next_number(course):
    numbers = []
    for d in exercise_projects(course):
        match = re.match(r'ex_(\d+)$', d.name)
        if match:
            numbers.append(int(match.group(1)))
    return (max(numbers) + 1) if numbers else 1


def main():
    parser = argparse.ArgumentParser(description='Create a new exercise session.')
    parser.add_argument('course', nargs='?', default=None, help='Course folder name.')
    parser.add_argument('--from-file', default=None,
                        help='A file in the course (e.g. the lecture you are editing).')
    parser.add_argument('--title', default='',
                        help='Exercise title (default: a language-aware '
                             '"Problem Set N" / "Übungsserie N").')
    args = parser.parse_args()

    course = get_course(args.course, args.from_file)
    if course is None:
        return 1

    n = next_number(course)
    project = course.exercises_dir / f'ex_{n:02d}'
    if project.exists():
        print(f'{project} already exists.')
        return 1

    (project / 'figures').mkdir(parents=True)

    # The default title is built by the template from the number, so it localizes
    # at compile time (Problem Set / Übungsserie); an explicit --title is used
    # verbatim after the course name.
    title = args.title.strip()
    title_arg = f'title: {typst_content(title)}' if title else f'number: {n}'
    (project / 'main.typ').write_text(
        EXERCISE_TEMPLATE.format(
            course_import=course.lectures.course_import(project),
            title_arg=title_arg,
        ),
        encoding='utf-8',
    )

    print(f'Created exercise {n} in {course.name}:')
    print(f'  {project / "main.typ"}')
    print('Drop the problem set in as sheet.pdf; write solutions with '
          '#exercise(n)[...] / #subexercise("a")[...] / #subsubexercise("i")[...].')
    return 0


if __name__ == '__main__':
    sys.exit(main())
