ARG MY_NAME="buildmaster"
ARG MY_VERSION="v2.8.0"
ARG IMAGE=buildbot/buildbot-master:v3.11.9

FROM $IMAGE

LABEL maintainer="OpenVPN Community Project"

EXPOSE 8010/tcp
EXPOSE 9989/tcp

ENV BASEDIR=/var/lib/buildbot/masters/default
RUN mkdir -p $BASEDIR

# Required for latent docker buildslaves
RUN . /buildbot_venv/bin/activate && pip install treq docker==5.0.3 || false
# Required for latent EC2 buildslaves
RUN . /buildbot_venv/bin/activate && pip install boto3 || false
RUN set -ex; \
    apt-get update || false

COPY buildmaster/buildbot.tac $BASEDIR
COPY buildmaster/start_buildmaster.sh $BASEDIR
COPY buildmaster/*.cfg $BASEDIR/
COPY buildmaster/master*.ini $BASEDIR/
COPY buildmaster/worker*.ini $BASEDIR/
COPY buildmaster/debian-*.sh $BASEDIR/
COPY buildmaster/debian-*.py $BASEDIR/
COPY buildmaster/debian-changelog.tmpl $BASEDIR/
COPY buildmaster/*.bat $BASEDIR/
COPY scripts/ensure-tun-is-present.sh $BASEDIR
ADD buildmaster/openvpn $BASEDIR/openvpn
ADD buildmaster/openvpn3 $BASEDIR/openvpn3
ADD buildmaster/openvpn3-linux $BASEDIR/openvpn3-linux
ADD buildmaster/ovpn-dco $BASEDIR/ovpn-dco

WORKDIR $BASEDIR

CMD dumb-init $BASEDIR/start_buildmaster.sh
