#!/bin/sh
set -ex

usage() {
  echo "Usage: debian-package.sh -w <workername>"
  echo
  echo "Example: debian-package.sh -w debian-unstable"
}

while getopts "hw:c:s:" arg; do
  case $arg in
    h)
      usage
      exit 0
      ;;
    w)
      WORKERNAME=${OPTARG%%-arm64}
      ;;
  esac
done

TBV=`./debian-get-openvpn-version-tarball.py`
SV=`./debian-get-openvpn-version-sanitized.py`

if [ "$WORKERNAME" = "" ] || [ "$TBV" = "" ] || [ "$SV" = "" ]; then
  usage
  exit 1
fi

rm -fr openvpn-$TBV openvpn-$SV
tar -xf openvpn-$TBV.tar.gz
mv openvpn-$TBV.tar.gz openvpn_$SV.orig.tar.gz
mv openvpn-$TBV openvpn-$SV
cp -a ../openvpn-build/debian-sbuild/openvpn/$WORKERNAME/debian openvpn-$SV/
./debian-generate-changelog.sh $SV
mv debian-changelog openvpn-$SV/debian/changelog

cd openvpn-$SV
dpkg-buildpackage -d -S -uc
dpkg-buildpackage -b
rm -f /home/buildbot/*.deb /home/buildbot/*.ddeb
cp -v ../*deb /home/buildbot/
