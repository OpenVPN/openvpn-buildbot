#!/bin/bash

. /buildbot_venv/bin/activate
exec twistd --pidfile= --nodaemon --python=buildbot.tac
