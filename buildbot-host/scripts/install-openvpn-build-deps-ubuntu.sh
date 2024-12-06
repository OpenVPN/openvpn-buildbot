#!/bin/sh
#
set -eux

export DEBIAN_FRONTEND=noninteractive

# Install build dependencies. Packages "fping" and "net-tools" are only
# required for t_client tests. Package "iproute2" is useful for debugging
# issues with Docker and OpenVPN.
apt-get update

APT_INSTALL="apt-get install -y -q --no-install-recommends"

$APT_INSTALL \
autoconf \
autoconf-archive \
automake \
build-essential \
ccache \
clang \
cmake \
curl \
debhelper \
dh-autoreconf \
dh-strip-nondeterminism \
dpkg-dev \
dwz \
fakeroot \
fping \
g++ \
git \
groff-base \
intltool-debian \
iproute2 \
libasio-dev \
libcap-dev \
libcap-ng-dev \
libcmocka-dev \
libdbus-1-dev \
libdebconfclient0 \
libdpkg-perl \
libprotobuf-dev \
libfakeroot \
libfile-stripnondeterminism-perl \
libglib2.0-dev \
libjsoncpp-dev \
liblz4-dev \
liblzo2-dev \
libmbedtls-dev \
libnl-genl-3-dev \
libpam-dev \
libp11-kit-dev \
libpkcs11-helper-dev \
libssl-dev \
libsystemd-dev \
libtool \
libtinyxml2-dev \
libxml2-utils \
libxxhash-dev \
make \
meson \
net-tools \
openssh-client \
pkg-config \
po-debconf \
protobuf-compiler \
python3 \
python3-docutils \
python3-dev \
python3-dbus \
python3-docutils \
python3-jinja2 \
python3-minimal \
python3-pip \
python3-roman \
python3-setuptools \
python3-wheel \
uncrustify \
uuid-dev

if [ "${INSTALL_MINGW:-false}" = "true" ] && lscpu|grep -E '^Architecture:[[:space:]]*x86_64$'; then
  # MingW + vcpkg
  $APT_INSTALL \
  man2html-base \
  mingw-w64 \
  ninja-build \
  unzip \
  zip

  cd /opt
  git clone https://github.com/microsoft/vcpkg
  cd vcpkg
  ./bootstrap-vcpkg.sh

  $APT_INSTALL wget software-properties-common
  wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
  dpkg -i packages-microsoft-prod.deb
  rm -f packages-microsoft-prod.deb
  apt-get update
  $APT_INSTALL powershell
fi

# Only for some distros
$APT_INSTALL systemd-dev || true

# Only needed on Ubuntu 24.04 for clang builds and may freely fail elsewhere
$APT_INSTALL libclang-rt-18-dev || true

# policykit-1 is not available in more recent operating systems
$APT_INSTALL policykit-1 || $APT_INSTALL polkitd pkexec

# Install kernel headers for building ovpn-dco. Determining the correct package
# name is challenging, so just try which ones install and which ones don't
$APT_INSTALL linux-headers-generic || $APT_INSTALL linux-headers-amd64

# Hack to ensure that kernel headers can be found from a predictable place
ln -s /lib/modules/$(ls /lib/modules|head -n 1)/build /buildbot/kernel-headers

# Cleanup
rm -rf /var/lib/apt/lists/*
