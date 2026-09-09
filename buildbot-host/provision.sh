#!/bin/sh
#
# Provision a Docker host for running Buildbot master and workers

# Load default provisioning configuration and custom provisioning
# configuration, if any.

BASEDIR=`dirname "$0"`

test -r "${BASEDIR}/provision-default.env" && . "${BASEDIR}/provision-default.env"
test -r "${BASEDIR}/provision.env" && . "${BASEDIR}/provision.env"

# Do not reprovision unless in Vagrant
if [ -f "${BASEDIR}/.provision.sh-ran" ] && [ "${DEFAULT_USER}" != "vagrant" ]; then
    exit 0
fi

# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
apt-get update
apt-get -y install apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io

CWD=`pwd`

# Create network for buildmaster and the workers
docker network create --driver bridge buildbot-net

# Create volume for storing buildmaster's sqlite database and passwords
docker volume create buildmaster

# Create a directory for local Git repositories shared from the Docker host to
# the buildmaster container
mkdir -p /var/lib/repos

# Add secrets
mkdir -p $VOLUME_DIR/secrets
chmod 700 $VOLUME_DIR/secrets
echo $WORKER_PASSWORD > $VOLUME_DIR/secrets/worker-password
if [ -n "${GITHUB_TOKEN}" ]; then
    echo $GITHUB_TOKEN > $VOLUME_DIR/secrets/github-token
fi
chmod 600 $VOLUME_DIR/secrets/*

# Ensure that "vagrant" user can run Docker commands
usermod -a -G docker $DEFAULT_USER

# Ensure that docker is listening on TCP port (for launching latent docker
# buildslaves)
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/override.conf <<EOL
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H fd:// --containerd=/run/containerd/containerd.sock
EOL

# Ensure that Docker daemon is IPv6-enabled. This is required for t_client
# tests where OpenVPN server pushes IPv6 information to the newly built OpenVPN
# client.
cat > /etc/docker/daemon.json <<EOL
{
    "ipv6": true,
    "fixed-cidr-v6": "fd00::/80"
}
EOL

systemctl daemon-reload
systemctl restart docker

cd $BASEDIR

# Create dummy certificates. Without this - or real certificates - container
# image builds will fail.
#
# Create dummy Authenticode certificate
touch buildmaster/authenticode.pfx

# Create dummy t_client ca.crt
touch t_client/ca.crt

# Create dummy t_client certs and keys.
for WORKERDIR in $(find -maxdepth 1 -type d -name "buildbot-worker*"); do
    touch $WORKERDIR/t_client.crt
    touch $WORKERDIR/t_client.key
done

# Build all worker containers
"${BASEDIR}/rebuild-all.sh"

# Create all volumes
"${BASEDIR}/create-volumes.sh"

touch "${BASEDIR}/.provision.sh-ran"
