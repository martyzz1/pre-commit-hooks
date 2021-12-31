#!/usr/bin/env bash

set -e

OPENAPI_FILE=$1
echo "$OPENAPI_FILE"
VERSION_CHANGED="$(git diff --cached $OPENAPI_FILE| grep '  version:' || true)"
echo "$VERSION_CHANGED"

function bump() {

	ver=$(grep '  version:' $1 | egrep -o "([0-9]{1,}\.)+[0-9]{1,}")
	a=( ${ver//./ } )
	if [ ${#a[@]} -ne 3 ]
	then
		echo "Strange Version number $ver detected in $1"
		echo ${#a[@]}
		exit 1
	fi
	((a[2]++))
	new_ver="${a[0]}.${a[1]}.${a[2]}"

	increment_file $1 "version: *$ver" "version: $new_ver"
	echo "openapi version autoincremented from $ver to $new_ver"
	exit 1
}

function increment_file() {

	# echo "Updating $1 from '$2'  to '$3'"
	perl -p -i -e "s/$2/$3/" $1
}

if test -z "$VERSION_CHANGED"; then
  # echo "Warning -- Changes to $OPENAPI_FILE were detected, but the version remains unchanged"
  # echo "Please increment the version number inside $OPENAPI_FILE"
  bump $OPENAPI_FILE
  exit 1
else
  echo "DONE $VERSION_CHANGED For $OPENAPI_FILE"
  exit 0
fi
