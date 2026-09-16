"""Bump the build number in project.godot.

    python tools/bump_version.py           # alpha 0.0.001 -> alpha 0.0.002
    python tools/bump_version.py --show    # print the current version and stop

The version ends up at the top of every run report, so a tester's file says which
build it came from. Run it before a commit, or wire it to a pre-commit hook:

    git config core.hooksPath .githooks

with .githooks/pre-commit calling this script and `git add project.godot`.
"""
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT = os.path.join(ROOT, "project.godot")
PATTERN = re.compile(r'^(config/version=")([^"]*)(")$', re.MULTILINE)


def read():
    text = io.open(PROJECT, encoding="utf-8").read()
    found = PATTERN.search(text)
    if not found:
        raise SystemExit("no config/version line in project.godot")
    return text, found.group(2)


def bump(version):
    """alpha 0.0.001 -> alpha 0.0.002, rolling 999 into the next field up."""
    label, _, numbers = version.rpartition(" ")
    parts = numbers.split(".")
    if len(parts) != 3 or not all(p.isdigit() for p in parts):
        raise SystemExit("version %r is not <label> <major>.<minor>.<patch>" % version)
    major, minor, patch = (int(p) for p in parts)
    width = len(parts[2])
    patch += 1
    if patch >= 10 ** width:
        patch = 0
        minor += 1
    joined = "%d.%d.%0*d" % (major, minor, width, patch)
    return ("%s %s" % (label, joined)).strip()


def main():
    text, current = read()
    if "--show" in sys.argv:
        print(current)
        return
    new = bump(current)
    io.open(PROJECT, "w", encoding="utf-8", newline="\n").write(
        PATTERN.sub(lambda m: m.group(1) + new + m.group(3), text, count=1)
    )
    print("%s -> %s" % (current, new))


if __name__ == "__main__":
    main()
