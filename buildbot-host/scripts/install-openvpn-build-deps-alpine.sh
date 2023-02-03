#!/bin/sh

set -ex

apk add \
autoconf \
autoconf-archive \
automake \
bash \
cmake \
cmocka-dev \
curl \
fping \
g++ \
git \
iproute2 \
jsoncpp-dev \
libcap-ng-dev \
libnl3-dev \
libtool \
libuuid \
libxml2-dev \
linux-headers \
linux-lts-dev \
linux-pam-dev \
lz4-dev \
lzo-dev \
make \
mbedtls-dev \
net-tools \
pkgconf \
opensc-dev \
openssl-dev \
python3 \
python3-dev \
py3-dbus \
py3-docutils \
py3-pip \
py3-roman \
py3-setuptools \
py3-wheel \
shadow \
tinyxml2-dev

# Hack to ensure that kernel headers can be found from a predictable place
ln -s /lib/modules/$(ls /lib/modules|head -n 1)/build /buildbot/kernel-headers
# alpine doesn't have fping6 symlink, t_client.sh can't deal
ln -s /usr/sbin/fping /usr/sbin/fping6
