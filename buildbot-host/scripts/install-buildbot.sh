#!/bin/sh
#
# Install buildbot
#
set -ex

BUILDBOT_VERSION=${BUILDBOT_VERSION:-4.3.0}

# Upgrading pip may or may not work. On Ubuntu 24.04 it may fail with
#
# "ERROR: Cannot uninstall pip 24.0, RECORD file not found. Hint: The package was installed by debian."
#
# Try and if it fails just keep on going
#
pip3 install $PIP_INSTALL_OPTS --upgrade pip || true
pip --no-cache-dir install $PIP_INSTALL_OPTS twisted[tls]
pip --no-cache-dir install $PIP_INSTALL_OPTS buildbot_worker==$BUILDBOT_VERSION

useradd --create-home --home-dir=/var/lib/buildbot buildbot
