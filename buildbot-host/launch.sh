#!/bin/sh
#
# Launch a static buildbot worker
DIR=$1

usage() {
    echo "./launch.sh <dir>"
    echo
    echo "Example:"
    echo "  ./launch.sh buildbot-worker-ubuntu-2004"
    echo
    exit 1
}

if [ "$1" = "" ]; then
    usage
fi

# Get image name and version
DOCKERFILE=$DIR/Dockerfile.base
[ ! -f $DIR/Dockerfile ] || DOCKERFILE=$DIR/Dockerfile
IMAGE=`grep MY_NAME $DOCKERFILE|awk 'BEGIN { FS = "\"" }; { print $2 }'`
TAG=`grep MY_VERSION $DOCKERFILE|awk 'BEGIN { FS = "\"" }; { print $2 }'`

docker container stop $IMAGE
docker container rm $IMAGE
docker container run -it --name $IMAGE --network buildbot-net --cap-add NET_ADMIN --sysctl net.ipv6.conf.all.disable_ipv6=0 --env-file=$DIR/env openvpn_community/$IMAGE:$TAG
