#!/usr/bin/env bash

# Pre-commit hook to sort files case-insensitively
# Works on both macOS (GNU sort) and Linux (BusyBox sort)

set -e

# Detect sort implementation and set appropriate flags
if /usr/bin/sort --version >/dev/null 2>&1; then
    # GNU sort (macOS, most Linux distributions)
    SORT_FLAGS="-u --ignore-case"
else
    # BusyBox sort (Alpine Linux)
    SORT_FLAGS="-u -f"
fi

# Process each file individually
for file in "$@"; do
  if [ -n "$file" ]; then
      LC_ALL=en_GB_POSIX /usr/bin/sort $SORT_FLAGS "$file" -o "$file"
  fi
done

