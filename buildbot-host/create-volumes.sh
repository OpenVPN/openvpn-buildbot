#!/bin/sh
#
# Create volumes for all workers. These are needed for t_client tests
if ! [ -r "create-volumes.sh" ]; then
    echo "ERROR: this script must be run in the directory with create-volumes.sh!"
    exit 1
fi

# Check every directory and rebuild if a file starting with Dockerfile is found
for DOCKERFILE in `find -maxdepth 2 -type f -regextype egrep -regex '.*/(Dockerfile|Dockerfile.base)'`; do
    DIR=`echo $DOCKERFILE|cut -d "/" -f 2`
    docker volume inspect $DIR > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        docker volume create $DIR
    fi
done
