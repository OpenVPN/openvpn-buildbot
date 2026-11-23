ARG MY_NAME="buildmaster"
ARG MY_VERSION="v3.1.0"
ARG IMAGE=buildbot/buildbot-master:v4.3.0

FROM $IMAGE

LABEL maintainer="OpenVPN Community Project"

EXPOSE 8010/tcp
EXPOSE 9989/tcp

ENV BASEDIR=/var/lib/buildbot/masters/default
RUN mkdir -p $BASEDIR

# Required for latent docker buildslaves
RUN . /buildbot_venv/bin/activate && pip install treq docker || false
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
ADD buildmaster/openvpn-rfc $BASEDIR/openvpn-rfc

WORKDIR $BASEDIR

# Fail the image build if the configuration is broken. The secrets
# directory normally lives on the persistent volume mounted at runtime,
# so provide a temporary empty one for the check. EC2 workers are replaced
# by plain workers since creating them requires AWS credentials.
RUN set -e; \
    mkdir -p persistent/secrets; \
    . /buildbot_venv/bin/activate; \
    BUILDBOT_CHECKCONFIG_ONLY=1 buildbot checkconfig $BASEDIR; \
    rm -rf persistent

CMD dumb-init $BASEDIR/start_buildmaster.sh
