#!/bin/bash

#set -x
set -e
set -o pipefail

is_calver()
{
    local tag="$1"
    echo "$tag" | grep -q -E "^[0-9]*\.[0-9]*\.[0-9]*"
}

version="${GITHUB_REF_NAME}"
printf "Version: %s\n" "${version}"

if is_calver "$version" && [ "$DOCKER_USERNAME" != "" ] && [ "$DOCKER_PASSWORD" != "" ]; then
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    docker build -t rmud .
    docker images
    image="rmud/rmud"
    version_tag="$image:$version"
    latest_tag="$image:latest"
    docker tag rmud "$version_tag"
    docker tag rmud "$latest_tag"
    docker push "$version_tag"
    docker push "$latest_tag"
else
    docker build -t rmud .
fi

