def beautify(string):
    return string.replace('_', ' ').replace('-', ' ').title()


def unbeautify(string):
    return string.replace(' ', '-').lower()


def typst_string(s):
    """`s` as a Typst string literal."""
    escaped = (s.replace('\\', '\\\\').replace('"', '\\"')
                .replace('\n', '\\n').replace('\r', '').replace('\t', '\\t'))
    return f'"{escaped}"'


def typst_content(s):
    """`s` as a Typst content block. Brackets must balance inside [...], so the
    rare unbalanced title is escaped instead."""
    if s.count('[') != s.count(']'):
        s = s.replace('[', '\\[').replace(']', '\\]')
    return f'[{s}]'
