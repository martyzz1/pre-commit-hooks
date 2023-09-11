#!/bin/bash

# Path to the package-lock.json
FILE_PATH="$1"
FROM_STRING=$(echo "$2" | sed -e 's/\./\\./g' -e 's/\:/\\:/g')
TO_STRING="$3"

# Use jq to replace $FROM_STRING with $TO_STRING and overwrite the original file
jq --arg from "$FROM_STRING" --arg to "$TO_STRING" 'walk(if type == "string" then gsub($from; $to) else . end)' "$FILE_PATH" > "${FILE_PATH}.tmp" && mv "${FILE_PATH}.tmp" "$FILE_PATH"
