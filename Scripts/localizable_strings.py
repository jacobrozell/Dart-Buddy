"""Parse and serialize Apple .strings values with Foundation-style escapes."""
from __future__ import annotations

import re

ENTRY_PATTERN = re.compile(r'^"([^"]+)"\s*=\s*"(.*)";\s*$', re.MULTILINE)

_ESCAPE_TO_CHAR = {
    "n": "\n",
    "r": "\r",
    "t": "\t",
    '"': '"',
    "\\": "\\",
}


def unescape_strings_value(value: str) -> str:
    chars: list[str] = []
    index = 0
    while index < len(value):
        char = value[index]
        if char != "\\":
            chars.append(char)
            index += 1
            continue
        index += 1
        if index >= len(value):
            chars.append("\\")
            break
        escaped = value[index]
        chars.append(_ESCAPE_TO_CHAR.get(escaped, escaped))
        index += 1
    return "".join(chars)


def escape_strings_value(value: str) -> str:
    escaped: list[str] = []
    for char in value:
        if char == "\\":
            escaped.append("\\\\")
        elif char == '"':
            escaped.append('\\"')
        elif char == "\n":
            escaped.append("\\n")
        elif char == "\r":
            escaped.append("\\r")
        elif char == "\t":
            escaped.append("\\t")
        else:
            escaped.append(char)
    return "".join(escaped)


def parse_entries(text: str) -> list[tuple[str, str]]:
    return [
        (match.group(1), unescape_strings_value(match.group(2)))
        for match in ENTRY_PATTERN.finditer(text)
    ]


def parse_entry_map(text: str) -> dict[str, str]:
    return dict(parse_entries(text))


def format_entries(entries: list[tuple[str, str]]) -> str:
    lines = [f'"{key}" = "{escape_strings_value(value)}";' for key, value in entries]
    return "\n".join(lines) + "\n"
