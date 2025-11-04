#!/bin/sh
#
# Launch the buildmaster
TAG=$1

usage() {
    echo "Usage: ./launch.sh <tag>"
    exit 1
}

if [ "$1" = "" ]; then
    usage
fi

docker container stop buildmaster
docker container rm buildmaster

# use DOCKER_OPTS=-it for interactive usage
DOCKER_OPTS="${DOCKER_OPTS:--d}"

docker container run $DOCKER_OPTS --name buildmaster --restart unless-stopped --volume /var/lib/repos:/var/lib/repos --mount source=buildmaster,target=/var/lib/buildbot/masters/default/persistent --network buildbot-net --publish 8010:8010 --publish 9989:9989 openvpn_community/buildmaster:$TAG

sleep 5

echo startup logs:
docker logs buildmaster
