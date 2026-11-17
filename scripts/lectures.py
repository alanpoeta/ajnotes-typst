#!/usr/bin/env python3
import os
import re
from datetime import datetime

from config import DATE_FORMAT, compile_typst
from utils import typst_content, typst_string


def number2filename(n):
    return 'lec_{0:02d}.typ'.format(n)


def filename2number(s):
    return int(str(s).replace('.typ', '').replace('lec_', ''))


# #lecture(3, "2026-11-17", [Title])  — the title may also be a string.
LECTURE_RE = re.compile(r'#lecture\(\s*(\d+)\s*,\s*"([^"]*)"\s*,\s*(?:\[(.*)\]|"(.*)")\s*\)')


class Lecture():
    def __init__(self, file_path, course):
        match = LECTURE_RE.search(file_path.read_text(encoding='utf-8'))

        date = datetime.today()
        title = ''
        if match:
            # Dates are stored as ISO (locale-independent). Fall back to today if
            # the stored date doesn't parse.
            try:
                date = datetime.strptime(match.group(2), DATE_FORMAT)
            except ValueError:
                pass
            title = match.group(3) if match.group(3) is not None else (match.group(4) or '')

        self.file_path = file_path
        self.date = date
        self.number = filename2number(file_path.stem)
        self.title = title
        self.course = course

    def __str__(self):
        return f'<Lecture {self.course.short} {self.number} "{self.title}">'


class Lectures(list):
    def __init__(self, course):
        self.course = course
        self.root = course.notes_dir
        self.main_file = self.root / 'main.typ'
        self.lectures_dir = self.root / 'lectures'
        list.__init__(self, self.read_files())

    def read_files(self):
        files = self.lectures_dir.glob('lec_*.typ')
        return sorted((Lecture(f, self.course) for f in files), key=lambda lecture: lecture.number)

    def course_import(self, from_dir):
        """The import line for course.typ, relative to a file in `from_dir`."""
        rel = os.path.relpath(self.course.course_file, from_dir).replace(os.sep, '/')
        return f'#import {typst_string(rel)}: *'

    def init_main(self):
        """Create the notes folders and a fresh main.typ.

        Returns True if main.typ was created, or False if it already existed (so
        this is safe to call repeatedly without clobbering existing files). The
        title and language come from course.typ, which the template reads.
        """
        self.root.mkdir(parents=True, exist_ok=True)
        self.lectures_dir.mkdir(exist_ok=True)
        (self.root / 'figures').mkdir(exist_ok=True)

        if self.main_file.exists():
            return False

        lines = [
            self.course_import(self.root),
            '#show: notes.with(course)',
            '',
        ]
        self.main_file.write_text('\n'.join(lines), encoding='utf-8')
        return True

    def include_in_main(self, number):
        """Add `#include "lectures/lec_NN.typ"` to main.typ, right after the last
        lecture include (so anything after the lectures, like a bibliography,
        stays last), or at the end if there is none yet. Every lecture stays
        included: Typst rebuilds only what changed, so there is nothing to gain
        from leaving lectures out, and the preview always shows the whole notes."""
        include = f'#include "lectures/{number2filename(number)}"'
        lines = self.main_file.read_text(encoding='utf-8').splitlines()
        if include in (line.strip() for line in lines):
            return
        last = max((i for i, line in enumerate(lines)
                    if line.strip().startswith('#include "lectures/')), default=None)
        if last is None:
            while lines and not lines[-1].strip():
                lines.pop()
            lines += ['', include]
        else:
            lines.insert(last + 1, include)
        self.main_file.write_text('\n'.join(lines) + '\n', encoding='utf-8')

    def new_lecture(self, title=''):
        if len(self) != 0:
            new_lecture_number = self[-1].number + 1
        else:
            new_lecture_number = 1

        new_lecture_path = self.lectures_dir / number2filename(new_lecture_number)

        # ISO date; #lecture localizes the weekday/month at compile time.
        date = datetime.today().strftime(DATE_FORMAT)

        self.lectures_dir.mkdir(exist_ok=True)
        new_lecture_path.write_text(
            f'{self.course_import(self.lectures_dir)}\n'
            '\n'
            f'#lecture({new_lecture_number}, "{date}", {typst_content(title)})\n'
            '\n',
            encoding='utf-8',
        )

        self.include_in_main(new_lecture_number)

        return Lecture(new_lecture_path, self.course)

    def compile_main(self):
        return compile_typst(self.main_file, self.course.path)
