#!/bin/sh
#
# Upgrade package cache and do a system upgrade
#
set -ex

yes|pacman -Syu --noconfirm

# Install build dependencies
pacman -S --noconfirm \
asio \
autoconf \
autoconf-archive \
automake \
bzip2 \
ccache \
cmake \
cmocka \
curl \
dbus-python \
fmt \
fping \
gcc \
git \
glib2 \
gnutls \
inetutils \
jsoncpp \
libcap \
libcap-ng \
libnl \
libpcap \
libtool \
linux-headers \
lz4 \
lzo \
make \
mbedtls \
meson \
openssh \
openssl \
pam \
pkcs11-helper \
pkgconf \
polkit \
protobuf \
python \
python-gobject \
python-pip \
python-setuptools \
python-wheel \
tinyxml2 \
which \
xxhash \
zlib

# Hack to ensure that kernel headers can be found from a predictable place
ln -s /lib/modules/$(ls /lib/modules|head -n 1)/build /buildbot/kernel-headers
# arch doesn't have fping6 symlink, t_client.sh can't deal
ln -s /usr/sbin/fping /usr/sbin/fping6
