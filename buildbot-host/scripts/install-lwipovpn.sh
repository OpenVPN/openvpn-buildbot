#!/bin/sh
#
# Build and install lwipovpn:
#
# https://github.com/OpenVPN/lwipovpn
#
set -ex

git clone --recursive https://github.com/openvpn/lwipovpn
cmake -B lwipovpnbuild -S lwipovpn
cmake --build lwipovpnbuild
