#!/bin/bash

# Path to the package-lock.json
FROM_STRING=$(echo "$1" | sed -e 's/\./\\./g' -e 's/\:/\\:/g')
TO_STRING="$2"
FILE_PATH="$3"

# Use jq to replace $FROM_STRING with $TO_STRING and overwrite the original file
jq --arg from "$FROM_STRING" --arg to "$TO_STRING" 'walk(if type == "string" then gsub($from; $to) else . end)' "$FILE_PATH" > "${FILE_PATH}.tmp"

# Print the changed lines
diff --unchanged-line-format="" --old-line-format="FIXED: %l\n" --new-line-format="" "$FILE_PATH" "${FILE_PATH}.tmp" | tee changes.txt

# Print the summary of changed lines
echo "$(wc -l < changes.txt) lines changed"

# Overwrite the original file with the changes
mv "${FILE_PATH}.tmp" "$FILE_PATH"

# Clean up
rm changes.txt
