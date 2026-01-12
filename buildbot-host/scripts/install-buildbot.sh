#!/bin/sh
#
# Install buildbot
#
set -ex

BUILDBOT_VERSION=${BUILDBOT_VERSION:-4.3.0}

virtualenv /buildbot_venv --python=python3
 . /buildbot_venv/bin/activate

pip install --upgrade pip
pip --no-cache-dir install twisted[tls]
pip --no-cache-dir install buildbot_worker==$BUILDBOT_VERSION

# not directly related to buildbot, but we want to install it
# into the venv, so easiests to put it here.
pip --no-cache-dir install pre-commit

useradd --create-home --home-dir=/var/lib/buildbot buildbot
