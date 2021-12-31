#!/usr/bin/env bash
FILE=$1
docker run --rm -t -v $(pwd):/tmp stoplight/spectral lint -F error -D "/tmp/$FILE"
