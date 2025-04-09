#!/bin/sh
#
set -ex

yum -y install \
asio-devel \
autoconf \
autoconf-archive \
automake \
bzip2 \
ccache \
cmake \
crypto-policies-scripts \
dbus-devel \
fping \
gcc \
gcc-c++ \
git \
glib2-devel \
gnutls-devel \
hostname \
iproute \
jsoncpp-devel \
libcap-devel \
libcap-ng-devel \
libcmocka-devel \
libnl3-devel \
libpcap-devel \
libtool \
libuuid-devel \
libxml2 \
lz4-devel \
lzo-devel \
kernel-devel \
make \
mbedtls-devel \
meson \
openssl-devel \
pam-devel \
pkcs11-helper-devel \
pkgconfig \
polkit \
procps \
protobuf \
protobuf-compiler \
protobuf-devel \
python3-devel \
python3-dbus \
python3-docutils \
python3-gobject \
python3-jinja2 \
python3-pip \
python3-pyOpenSSL \
python3-setuptools \
python3-wheel \
selinux-policy-devel \
systemd-devel \
tinyxml2-devel \
which \
xxhash-devel \
zlib-devel

# make our SHA1-signed CA work on Fedora 41 and newer
update-crypto-policies --set FEDORA40

# Hack to ensure that kernel headers can be found from a predictable place
ln -s /usr/src/kernels/$(ls /usr/src/kernels|head -n 1) /buildbot/kernel-headers
# fedora doesn't have fping6 symlink, t_client.sh can't deal
ln -s /usr/sbin/fping /usr/sbin/fping6
