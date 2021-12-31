#!/usr/bin/env bash

CONTAINER=$1

if [ -z "$CONTAINER" ]; then
    if [ -z "$PRE_COMMIT_DOCKER_CONTAINER" ]; then
        echo "No PRE_COMMIT_DOCKER_CONTAINER env variable set.  try "
        echo "export PRE_COMMIT_DOCKER_CONTAINER=development_users-api.api_1"
        exit 1
    else
        echo "Using ENV Based Container $PRE_COMMIT_DOCKER_CONTAINER"
    fi
else
    PRE_COMMIT_DOCKER_CONTAINER=$CONTAINER
    echo "Using ARGS Based Container $PRE_COMMIT_DOCKER_CONTAINER"
fi

docker exec -i ${PRE_COMMIT_DOCKER_CONTAINER} ./manage.py makemigrations --check --dry-run
