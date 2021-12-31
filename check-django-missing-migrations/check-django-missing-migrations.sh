#!/usr/bin/env bash

MIGRATIONS_DIRECTORIES="$(find . -type d -iname migrations)"
UNTRACKED_MIGRATIONS="$(git ls-files --exclude-standard --others -- $MIGRATIONS_DIRECTORIES | egrep '(.*)[.]py$')"

if test -z "$UNTRACKED_MIGRATIONS"; then
  # If there are no untracked .py files in the migrations directory, do nothing, allow commit.
  exit 0
else
  # If there are untracked files in the migrations directory print a warning message.
  echo "Warning -- there are untracked files in your migrations directory"
  echo "Please add the below migrations to your commit"
  echo "Or work out if deleting them will cause armageddon"
  echo
  echo "$UNTRACKED_MIGRATIONS"
  exit 1
fi
