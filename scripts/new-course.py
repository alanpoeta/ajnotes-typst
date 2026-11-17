#!/usr/bin/env python3
"""Create a new course: a folder with course.typ and an initialised notes/main.typ.

Usage:
    python scripts/new-course.py "Special Relativity"
    python scripts/new-course.py "Special Relativity" --folder relativity --language german

The folder name defaults to a slug of the title (e.g. "special-relativity").
The title and language are written into course.typ (the course's settings,
read by the notes and every exercise). The document language defaults to English.
"""
import argparse
import sys

from config import PACKAGE, ROOT
from courses import Course
from utils import typst_string, unbeautify


COURSE_TEMPLATE = '''// «{title}»: the course's settings and macros, shared by the notes and
// every exercise. Each document of the course imports this file with one line
// at its top, which also brings in the ajnotes package, so anything defined
// here is written once and available everywhere — figure labels included.
#import "{package}": *

#let course = (
  title: {title_literal},
  language: "{language}", // "german" | "english"
)

// --- Course macros -----------------------------------------------------------
// For example:
//   #let Lor = math.op("Lor")
//   #let fourvec(x) = math.underline(x)
//
// `mode` tells the notes and a problem sheet apart, if a macro should differ:
//   #let hint(body) = context if mode.get() == "notes" [#body]
'''


def main():
    parser = argparse.ArgumentParser(description='Create a new course.')
    parser.add_argument('title', help='Course title (shown on the PDF title page).')
    parser.add_argument('--folder', default=None,
                        help='Folder name (default: a slug derived from the title).')
    parser.add_argument('--language', default='english', choices=['english', 'german'],
                        help='Document language (default: english).')
    args = parser.parse_args()

    folder_name = args.folder or unbeautify(args.title)
    course_path = ROOT / folder_name

    if course_path.exists():
        print(f'A folder named {folder_name!r} already exists at {course_path}.')
        return 1

    course_path.mkdir(parents=True)
    (course_path / 'course.typ').write_text(COURSE_TEMPLATE.format(
        title=args.title,
        title_literal=typst_string(args.title),
        language=args.language,
        package=PACKAGE,
    ), encoding='utf-8')

    # init_main creates notes/ (and lectures/, figures/) and the main.typ that
    # makes this folder recognisable as a course.
    Course(course_path).lectures.init_main()

    print(f'Created course {folder_name!r} ({args.language}) at {course_path}')
    print('Add lectures with:  python scripts/new-lecture.py ' + folder_name)
    return 0


if __name__ == '__main__':
    sys.exit(main())
