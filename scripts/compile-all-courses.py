#!/usr/bin/env python3
"""Compile every course's notes under the root."""
import sys

from courses import courses_or_enclosing

failed = []
for course in courses_or_enclosing():
    if course.lectures.compile_main() == 0:
        print(f'Compiled {course.name}')
    else:
        failed.append(course.name)

if failed:
    print('Failed: ' + ', '.join(failed))
sys.exit(1 if failed else 0)
