#!/bin/bash

# Path to the package-lock.json
FROM_STRING=$(echo "$1" | sed -e 's/\./\\./g' -e 's/\:/\\:/g')
TO_STRING="$2"
FILE_PATH="$3"

printf "FILE_PATH=%s" "$FILE_PATH"
printf "FROM_STRING=%s" "$FROM_STRING"
printf "TO_STRING=%s" "$TO_STRING"

# Use jq to replace $FROM_STRING with $TO_STRING and overwrite the original file
jq --arg from "$FROM_STRING" --arg to "$TO_STRING" 'walk(if type == "string" then gsub($from; $to) else . end)' "$FILE_PATH" > "${FILE_PATH}.tmp" && mv "${FILE_PATH}.tmp" "$FILE_PATH"
