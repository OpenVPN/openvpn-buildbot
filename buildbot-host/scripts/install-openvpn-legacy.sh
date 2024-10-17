#!/bin/sh
#
# Install OpenVPN 2.5 and 2.6
#
set -e

install_openvpn() {
    RELEASE=$1
    CRYPTO_LIBRARY=$2
    DEST=/opt/openvpn-$RELEASE-$CRYPTO_LIBRARY
    echo "Installing OpenVPN $RELEASE compiled against $CRYPTO_LIBRARY to $DEST"

    CWD=$(pwd)
    cp -a openvpn openvpn-$RELEASE-$CRYPTO_LIBRARY
    cd openvpn-$RELEASE-$CRYPTO_LIBRARY
    git checkout -b release/$RELEASE origin/release/$RELEASE
    autoreconf -vi
    ./configure --with-crypto-library=$CRYPTO_LIBRARY --prefix=/opt/openvpn-$RELEASE-$CRYPTO_LIBRARY
    make
    make install
    # Remove the build directory to save some disk space
    rm -rf openvpn-$RELEASE-$CRYPTO_LIBRARY
    cd $CWD
}

cd /buildbot
git clone https://github.com/OpenVPN/openvpn.git

install_openvpn 2.5 mbedtls
install_openvpn 2.5 openssl
install_openvpn 2.6 mbedtls
install_openvpn 2.6 openssl

