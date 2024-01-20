#!/bin/sh
#
# Rebuild all containers (master and workers)

set -eux

# Check that we're in the right directory
if ! [ -r "rebuild.sh" ]; then
    echo "ERROR: this script must be run in the directory with rebuild.sh!"
    exit 1
fi

# Check every directory and rebuild if a file starting with Dockerfile is found
for DOCKERFILE in $(find -maxdepth 2 -type f -regextype egrep -regex '.*/(Dockerfile|Dockerfile.base)'); do
    DIR=$(echo "$DOCKERFILE"|cut -d "/" -f 2)
    ./rebuild.sh "$DIR"
done

# clean up dangling images and build cache
docker container prune --force
docker image prune --force
docker buildx prune --force
