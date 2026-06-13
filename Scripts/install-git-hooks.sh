#!/bin/sh
# Point this clone at repo-managed git hooks (pre-commit secret guards, etc.).
set -e
root=$(git rev-parse --show-toplevel)
cd "$root"
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
echo "Installed git hooks from .githooks/ (core.hooksPath=.githooks)"
