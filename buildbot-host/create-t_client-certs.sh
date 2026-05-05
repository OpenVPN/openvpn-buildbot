#!/bin/sh
#
# Create t_client certs for all workers
#

set -eux

: ${BUILDBOT_HOST_DIR:=.}
: ${HOSTNAME:=$(hostname --short)}
: ${SSH_USER:=$USER}
: ${CERT_ALG:=ec}
PREFIX="buildbot-worker"

for worker in $(ls -d1 "${BUILDBOT_HOST_DIR}/$PREFIX-"*)
do
  WORKERNAME=$(basename $worker)

  ssh -l $SSH_USER -p 774 phillip.secure-computing.net /root/generate-client-cert "$CERT_ALG" "${HOSTNAME}-${WORKERNAME}" >$worker/t_client.inline
  chmod 660 $worker/t_client.inline
done
