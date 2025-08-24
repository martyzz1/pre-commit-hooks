#!/usr/bin/env bash

# Pre-commit hook to generate ghost files for versioned files
# This ensures that pull requests show diffs between versions

set -e

# Process each file individually
for file in "$@"; do
  if [ -n "$file" ]; then
      LC_ALL=en_GB_POSIX /usr/bin/sort -u --ignore-case "$file" -o "$file"
  fi
done

