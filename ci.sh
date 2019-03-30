#!/bin/bash

#set -x
set -e
set -o pipefail

get_version()
{
    git describe --tags --dirty --always --match="$TRAVIS_TAG"
}

is_calver()
{
    local tag="$1"
    echo "$tag" | grep -q -E "^[0-9][0-9]\.[0-9][0-9]\.[0-9][0-9]*"
}

VERSION="$(get_version)"

if is_calver "$VERSION" && [ "$DOCKER_USERNAME" != "" ] && [ "$DOCKER_PASSWORD" != "" ]; then
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    docker build -t rmud .
    docker images
    tag="rmud/rmud:$VERSION"
    docker tag rmud "$tag"
    docker push "$tag"
else
    docker build -t rmud .
fi

