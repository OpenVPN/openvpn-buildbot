ARG MY_NAME="buildmaster"
ARG MY_VERSION="v2.2.0"
ARG IMAGE=buildbot/buildbot-master:v3.5.0

FROM $IMAGE

LABEL maintainer="OpenVPN Community Project"

EXPOSE 8010/tcp
EXPOSE 9989/tcp

ENV BASEDIR=/var/lib/buildbot/masters/default
RUN mkdir -p $BASEDIR

# Required for latent docker buildslaves
RUN . /buildbot_venv/bin/activate && pip install docker || false
RUN set -ex; \
    apt-get update && apt-get -y install patch || false

COPY buildmaster/buildbot.tac $BASEDIR
COPY buildmaster/start_buildmaster.sh $BASEDIR
COPY buildmaster/*.cfg $BASEDIR/
COPY buildmaster/master*.ini $BASEDIR/
COPY buildmaster/worker*.ini $BASEDIR/
COPY buildmaster/vstudio.py.patch $BASEDIR
COPY buildmaster/build-openvpn-gui.ps1 $BASEDIR
COPY buildmaster/msbuild-x64.bat $BASEDIR
COPY buildmaster/msbuild-x64_x86.bat $BASEDIR
COPY buildmaster/msbuild-x64_arm64.bat $BASEDIR
COPY buildmaster/sign-binaries.bat $BASEDIR
COPY buildmaster/debian-*.sh $BASEDIR/
COPY buildmaster/debian-*.py $BASEDIR/
COPY buildmaster/debian-changelog.tmpl $BASEDIR/
COPY buildmaster/import-signing-cert.ps1 $BASEDIR/
COPY buildmaster/authenticode.pfx $BASEDIR/
ADD buildmaster/openvpn $BASEDIR/openvpn
ADD buildmaster/openvpn3 $BASEDIR/openvpn3
ADD buildmaster/openvpn3-linux $BASEDIR/openvpn3-linux
ADD buildmaster/ovpn-dco $BASEDIR/ovpn-dco

RUN set -ex; \
    patch /buildbot_venv/lib/python3.9/site-packages/buildbot/steps/vstudio.py $BASEDIR/vstudio.py.patch

COPY scripts/ensure-tun-is-present.sh $BASEDIR

WORKDIR $BASEDIR

CMD dumb-init $BASEDIR/start_buildmaster.sh
