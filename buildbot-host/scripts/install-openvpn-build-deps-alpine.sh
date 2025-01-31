#!/bin/sh

set -ex

apk add \
asio-dev \
autoconf \
autoconf-archive \
automake \
bash \
ccache \
cmake \
cmocka-dev \
curl \
dbus-dev \
fping \
g++ \
git \
glib-dev \
iproute2 \
jsoncpp-dev \
libcap-ng-dev \
libnl3-dev \
libpcap-dev \
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
meson \
net-tools \
opensc-dev \
openssh-client \
openssl-dev \
pkgconf \
procps \
protobuf \
protobuf-dev \
protobuf-c-dev \
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
