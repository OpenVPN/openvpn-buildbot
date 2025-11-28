ARG IMAGE=debian:9
ARG MY_NAME="buildbot-worker-debian-9"
ARG MY_VERSION="v1.0.0"

FROM $IMAGE
LABEL maintainer="OpenVPN Community Project"
USER root
WORKDIR /buildbot

ENV BUILDBOT_BASEDIR=/build

# Install build dependencies for OpenVPN
RUN mkdir -p /buildbot
RUN sed -i -e 's/deb\.debian\.org/archive.debian.org/g' /etc/apt/sources.list
RUN sed -i -e '/stretch-updates/d' /etc/apt/sources.list
RUN sed -i -e 's/security\.debian\.org/archive.debian.org/g' /etc/apt/sources.list

ENV DEBIAN_FRONTEND=noninteractive
ENV APT_INSTALL="apt-get install -y -q --no-install-recommends"
RUN apt-get update && ${APT_INSTALL} \
autoconf \
autoconf-archive \
automake \
build-essential \
ccache \
curl \
debhelper \
dh-autoreconf \
dh-strip-nondeterminism \
doxygen \
dpkg-dev \
dwz \
fakeroot \
fping \
git \
gnutls-bin \
graphviz \
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
libffi-dev \
libfile-stripnondeterminism-perl \
liblz4-dev \
liblzo2-dev \
libmbedtls-dev \
libnl-genl-3-dev \
libpam-dev \
libpcap-dev \
libp11-kit-dev \
libpkcs11-helper-dev \
libssl1.0-dev \
libsystemd-dev \
libtool \
libxml2-utils \
make \
net-tools \
openssh-client \
pkg-config \
po-debconf \
procps \
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
uuid-dev

RUN rm -rf /var/lib/apt/lists/*

# Install buildbot
ENV BUILDBOT_VERSION=3.11.9
ARG MY_NAME
COPY scripts/install-buildbot.sh t_client/*.crt t_client/*.rc t_client/*.txt ${MY_NAME}/t_client.* ${MY_NAME}/t_server_null.rc /buildbot/
RUN set -ex; \
    /buildbot/install-buildbot.sh; \
    rm -f /buildbot/install-buildbot.sh

COPY buildbot.tac /buildbot/
RUN mkdir -p /home/buildbot

CMD ["twistd", "--pidfile=", "--nodaemon", "--python=buildbot.tac"]
