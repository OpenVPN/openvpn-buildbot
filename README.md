# Introduction

This is CI/CD system built on top of Buildbot using Vagrant, a virtualization
layer (Virtualbox/Hyper-V) and Docker. Here's an overview of the design
(details vary depending on the deployment):

![Buildbot architecture overview](diagrams/buildbot-architecture-overview.png)

The system does not require Vagrant, Virtualbox or Hyper-V  - those are only a
convenience to allow setting up an isolated environment easily on any computer
(Linux, Windows, MacOS).

This system has been tested on:

* Vagrant + Virtualbox on Fedora Linux 34
* Vagrant + Virtualbox Windows 10
* Vagrant + Hyper-V on Windows 10
* Amazon EC2 Ubuntu 20.04 server instance (t3a.large)
* Amazon EC2 Ubuntu 22.04 server instance (t3a.large)
* Amazon EC2 Ubuntu 23.10 server instance (t3a.large)

The whole system is configured to use 8GB of memory. However, it could potentially run in less, because
all the buildbot workers that do the heavy lifting are latent Docker and EC2 workers. 

# Setup in Vagrant

If you use Vagrant with Virtualbox you need to install Virtualbox Guest
Additions to the VMs. The easiest way to do that is with
[vagrant-vbguest](https://github.com/dotless-de/vagrant-vbguest):

    $ vagrant plugin install vagrant-vbguest

Without this plugin Virtualbox shared folders will not work and you will get
errors when you create the VMs.

After that you should be able to just do

    $ vagrant up buildbot-host

and once that has finished you can adapt buildbot configuration to your needs,
rebuild the buildmaster container and start using the system. At that point you
will a fully functional, dockerized buildbot environment inside the
buildbot-host VM.

You can use two providers with the buildbot VMs: *virtualbox* and *hyperv*. Vagrant should be able to select
the correct provider automatically. If you have both VirtualBox and Hyper-V enabled you need to explicitly
define the provider *and* run "vagrant up" as an Administrator. For example:

    $ vagrant up --provider hyperv buildbot-host

After you've provisioned buildbot-host you need to launch the buildmaster container:

    $ vagrant ssh buildbot-host
    $ cd /vagrant/buildbot-host/buildmaster
    $ ./launch.sh v2.0.0

When you restart the VM buildmaster container will come up automatically.

If you're using Virtualbox you can connect to the buildmaster using this address:

* http://192.168.48.114:8010

In case of Hyper-V you need to get the local IP of buildbot-host from output of "vagrant up".
For example:

* http://172.30.55.25:8010

This is because Hyper-V ignores Vagrant's networking settings completely.

To do Windows testing also spin up the Windows worker:

    $ vagrant up buildbot-worker-windows-server-2019

If you're doing this on Hyper-V you need to modify the buildmaster IP in Vagrantfile to match that of
the Buildmaster. In Hyper-V you will also need to pass your current Windows user's credentials to Vagrant
for it to be able to mount the SMB synced folder. You can get a list of valid usernames with Powershell:

    PS> Get-LocalUser

In Virtualbox file sharing between host and guest is handled by with the VirtualBox filesystem. In
either case your openvpn-vagrant directory will get mounted to /vagrant on buildbot-host, and C:\Vagrant
on Windows hosts.

**NOTE:** you can spin up buildbot-host outside of Vagrant. For more details about that and other topics
refer to [buildbot-host/README.md](buildbot-host/README.md).

# Setup outside Vagrant

If you want to create this environment outside of Vagrant first do

    $ cd openvpn-vagrant/buildbot-host
    $ cp provision-default.env provision.env

then modify *provision.env* to look reasonable. For example in AWS EC2 you'd
use something like this:

    VOLUME_DIR=/var/lib/docker/volumes/buildmaster/_data/
    WORKER_PASSWORD=mysecretpassword
    DEFAULT_USER=ubuntu

Then provision the environment:

    /full/path/to/buildbot-host/provision.sh

The provisioning script will create dummy t_client and Authenticode
certificates. This step is required to succesfully build buildbot worker and
master container images. These dummy certificates will suffice unless you are
going to run t_client tests or do Windows code signing.

Note that provisioning is only tested on Ubuntu 20.04 server and is unlikely to
work on any other Ubuntu or Debian version without modifications.

After provisioning you need to create a suitable *master.ini* file based on
*master-default.ini*. In general two changes should be made:

* Ensure that email address are valid or buildmaster will fail to start
* Ensure that repository URLs are pointing to a reasonable place (e.g. your own forks on GitHub)

Once you have configured master.ini build the buildmaster container:

    cd /full/path/to/buildbot-host
    ./rebuild.sh buildmaster

Then launch the buildmaster container, stopping and removing old instances in the process:

    cd /full/path/to/buildbot-host/buildmaster
    ./launch.sh v2.5.0

Buildbot master should now be listening on port 8010.

# Logging into the Windows VMs from Linux

If you're running Vagrant on Linux you're almost certainly using
[FreeRDP](https://www.freerdp.com/). That means you have to accept the Windows
VM's host key before attempting to "vagrant rdp" into it:

    $ xfreerdp /v:127.0.0.1:3389

Once the host key is in FreeRDP's cache you can connect to the instance. For example:

    $ vagrant rdp buildbot-worker-windows-server-2019

# Supported build types

## openvpn

* Basic Unix compile tests using arbitrary, configurable configure options
* Unix connectivity tests using t_client.sh (see OpenVPN Git repository)
* Native Windows builds using MSVC to (cross-)compile for x86, x64 and arm64 plus MSI packaging and signing
* Debian/Ubuntu packaging (partially implemented)

## openvpn3

* Compile tests against OpenSSL and stable release of ASIO

## openvpn3-linux

* Compile tests with standard settings

## ovpn-dco

* Compile tests against the operating system's default kernel

## Relevant files and directories under buildbot-host:

The buildbot-host directory contains a number scripts for settings up a
buildmaster.  The following script are used internally and typically you would
not touch them:

* *provision.sh*: used to set up the Docker host
* *create-volumes.sh*: create or recreate Docker volumes for the buildmaster and workers

Most of the time you'd be using these scripts:

* *rebuild.sh*: rebuild a single Docker image
* *rebuild-all.sh*: rebuild all Docker images
* *buildmaster/launch.sh*: launch the buildmaster

If you want to experiment with static (non-latent) Docker buildbot workers you
may also use:

* *launch.sh*: launch a buildbot worker

Here's a list of relevant directories:

* *buildmaster*: files, directories and configuration related to the buildmaster
    * *authenticode.pfx*: your Windows code signing key (ignored by Git, must be copied to correct place manually)
    * *master-default.ini*: global/buildmaster settings (Git repo URLs etc). Does not get loaded if *master.ini* (below) is present.
    * *master.ini*: local, unversioned config file with which you can override *master-default.ini*.
    * *worker-default.ini*: buildbot worker settings. The \[DEFAULT\] section sets the defaults, which can be overridden on a per-worker basis. Does not get loaded if *worker.ini* (below) is present.
    * *worker.ini*: local, unversioned config file with which you can override *worker-default.ini*.
    * *master.cfg*: buildmaster's "configuration file" that is really just Python code. It is solely responsible for defining what Buildbot and its workers should do.
    * *debian*: this directory contains all the Debian and Ubuntu packaging files arranged by worker name. During Debian packaging builds the relevant files get copied to the Debian/Ubuntu worker.
    * *openvpn*: files containing the build steps for openvpn (OpenVPN 2.x)
    * *openvpn3*: files containing the build steps for openvpn3 (OpenVPN 3.x)
    * *openvpn3-linux*: files containing the build steps for openvpn3-linux
    * *ovpn-dco*: files containing the build steps for ovpn-dco
* *buildbot-worker-\<something\>*: files and configuration related to a worker
    * *Dockerfile.base*: a "configuration file" that contains ARG entries that will drive the logic in the main Dockerfile, *snippets/Dockerfile.common*. Used when provisioning the container.
    * *env*: sets environment variables that are required by the worker container (buildmaster, worker name, worker pass). Used when launching *static* containers. Not needed for *latent* workers. In other words, in most cases you can ignore the *env* file.
    * *ec2.pkr.hcl*: Packer code to build EC2 latent buildbot workers
* *aptly*: files related to Debian/Ubuntu package publishing using aptly; see [buildbot-host/aptly/README.md](buildbot-host/aptly/README.md) for details
* *scripts*: reusable worker initialization/provisioning scripts
* *snippets*: configuration fragments; current only the reusable part of the Dockerfile

# The Docker setup

This Docker-based environment attempts to be stateless and self-contained.
While all the containers have persistent volumes mounted on the host, only
buildmaster actually utilizes the volume for anything (storing the worker
password and the sqlite database). The worker containers are launched on-demand
and get nuked after each build. On next build everything starts from scratch.

Build artefacts can be copied from the workers to the buildmaster before the
worker exits, or copied elsewhere during build.

The containers (master and workers) do not require any data to be present on
the persistent volumes to work. The only exception is the worker password that
needs to be in a file on buildmaster's persistent volume.

# Building and using additional Docker hosts.

It is possible to point the buildmaster to a remote Docker hosts on a
worker-by-worker basis. This can be useful, for example, to add builds for
other processor architectures like arm64.

The remote Docker host can be created like any buildmaster with provision.sh -
we just don't use the buildmaster container for anything. The Docker daemon on
the remote Docker host needs to listen on the appropriate network interface.
This can be accomplished with a systemd override:

```
# /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://10.29.32.2:2375
```

For security reasons access to the Docker daemon should be limited to just the
Buildmaster, e.g. with iptables rules or EC2 security groups.

Once the remote Docker host is ready, you need to configure Buildbot workers.
For each worker you define which Docker host the Buildmaster uses and which
Buildmaster (from its perspective) the worker connects to. Here's an example
from worker.ini:

```
[debian-11-arm64]
# Buildbot worker needs to know where the buildmaster lives
master_fqdn=10.29.32.1

# Buildmaster needs to know which docker host to instantiate the container on
docker_url=tcp://10.29.32.2:2375

# This refers to the name of the image running on this docker host
image=openvpn_community/buildbot-worker-debian-11:v1.0.3
```

The worker-default.ini file has example arm64 workers configured already.

# Configuring build concurrency on Docker hosts

The maximum number of concurrent builds needs to be configured in a JSON
dictionary in master.ini:

```
[docker]
max_builds={ "172.18.0.1": 4, "10.29.32.2": 4 }
```

The keys must be IP addresses or hostnames. Each key must be present in worker.ini
as part of a docker_url. For example:

```
[DEFAULT]
docker_url=tcp://172.18.0.1:2375

[debian-11-arm64]
docker_url=tcp://10.29.32.2:2375
```

# Email notification setup

Buildbot expects a local MTA such as postfix to be configured correctly.
However, there are still several parameters in *master.ini* for configuring
email notification preferences.

You can define an *owner* property for each project separately. It defines an
email address where build failure notifications for that project are sent.

```

# Applies when a project-specific "owner" is missing
[DEFAULT]
owner=buildbot@example.org

[openvpn]
owner=openvpn@example.org

[openvpn3]
owner=openvpn3@example.org

[openvpn3-linux]
owner=openvpn3-linux@example.org

[ovpn-dco]
owner=ovpn-dco@example.org
```

Note that value of *owner* must not be quoted.

Other settings that affect mail delivery are:

```
[email]
# Send email to this address when a worker goes missing. Only affects "always-on" workers.
notify_on_missing=["buildbot@example.org"]

# Additional recipients who should get all build failure emails.
extra_recipients=["buildbot@example.org"]

# Source address for the emails. Should generally match the SMTP username in
# the local MTA configuration.
fromaddr=buildbot@example.org

# Address of the local MTA as seen by the Buildmaster container. Usually the
# Docker host that also runs Buildbot.
relayhost=172.18.0.1
```

# Development

## Defining image version and name

The Dockerfile or Dockerfile.base used to build the images contains some
metadata encoded in Docker's ARG parameter. This allows parameterless
image rebuild and container launch scripts. You should not change the image
metadata unless you have a specific reason for it: reusing the same tag will
simplify things especially in Vagrant.

## Building the docker images

Buildbot depends on pre-built images. To (re)build a worker:

    cd buildbot-host
    ./rebuild.sh <worker-dir>

For example

    ./rebuild.sh buildbot-worker-ubuntu-2004

To build the master:

    ./rebuild.sh buildmaster

To rebuild all containers (master and workers):

    ./rebuild-all.sh

Due to docker caching you can typically rebuild everything in a few seconds if
you're just changing config files.

## Building latent EC2 workers with Packer

Certain workers such as windows-server-2019-latent-ec2 are built with Packer.
Sensitive information like passwords have to be defined on Packer command-line
or in environment variables. Here's an example of the latter approach:

    PKR_VAR_buildbot_windows_server_2019_worker_password=<buildbot-worker-password>
    PKR_VAR_buildbot_windows_server_2019_ec2_region=eu-central-1
    PKR_VAR_buildbot_windows_server_2019_buildbot_user_password=<buildbot-windows-user-password>
    PKR_VAR_buildbot_authenticode_cert=<authenticode-certificate-file-path>
    PKR_VAR_buildbot_authenticode_password=<password-for-authenticode-certificate>
    PKR_VAR_buildmaster_address=<buildmaster-ip-address>
    PKR_VAR_buildbot_windows_server_2019_winrm_password=<windows-admin-password>

To build the image use

    packer build ec2.pkr.hcl

It is assumed of course that you have configured AWS and Packer properly.

## Changing buildmaster configuration

Buildmaster has several configuration files:

* *master.cfg*: this is the Python code that drives logic in Buildbot; it should have as little configuration it is as possible
* *master-default.ini*: the default master configuration, contains Docker and Git settings
* *master.ini*: overrides settings in master-default.ini completely, if present
* *worker-default.ini*: the default worker configuration, contains a list of workers and their settings
* *worker.ini*: overrides settings in worker-default.ini completely, if present

While you can launch a buildmaster with default settings just fine, you
probably want to copy *master-default.ini* and *worker-default.ini* as *master.ini*
and *worker.ini*, respectively, and adapt them to your needs.

It is possible to do rapid iteration of buildmaster configuration. For example:

    vi buildmaster/master.cfg
    docker container stop buildmaster
    ./rebuild.sh buildmaster

Then from the "buildmaster" subdirectory:

    ./launch.sh v2.0.0

# Stable and rolling release distros

Most of the latent Docker workers are based on stable distribution, meaning
that their package versions remain the same and only small patches are applied
on top.  These are what most normal people use.

Some workers are based on rolling release distros, though. If the Docker images
are rebuilt regularly these distros help us spot build issues early on.

# Debugging

## Worker stalling in "Preparing worker" stage

If your workers hang indefinitely at "Preparing worker" stage then the problem
is almost certainly a broken container image. Usually building the Docker image
failed in a way that buildbot did not install properly, which caused the "CMD"
at the end of the Dockerfile to fail. The fix is to nuke the image, fix the problem and
rebuild the image. Get the ID of the image that does not work:

    docker container ls

Remove it:

    docker container rm -f <id>

(Attempt to) Fix the problem. Then rebuild the image and ensure that the process works:

    cd buildbot-host
    ./rebuild.sh buildbot-worker-<something>

The rebuild.sh expect a worker directory as its one and only parameter.

## Debugging build or connectivity test issues

Probably the easiest way debug issues on workers (e.g. missing build
dependencies, failing t_client tests) is to just add a "sleep" build step to
master.cfg right after the failing step. For example:

    factory.addStep(steps.ShellCommand(command=["sleep", "36000"]))

This prevents buildmaster from destroying the latent docker buildslave before
you have had time to investigate. To log in to the container use a command like
this:

    docker container exec -it buildbot-ubuntu-1804-e8a345 /bin/sh

Check "docker container ls" to get the name of the container.

## Simulating always-on buildbot workers

Buildbot launches the docker workers on-demand, so there are only two use-cases for non-latent always-on docker workers:

* Initial image setup: figuring out what needs to be installed etc.
* Simulating always-on workers: this can be useful when developing master.cfg

The always-on dockerized workers get their buildbot settings from \<worker-dir\>/env that
you should modify to look something like this:

    BUILDMASTER=buildmaster
    WORKERNAME=ubuntu-2004-alwayson
    WORKERPASS=vagrant

You also need to modify buildmaster/worker.ini to include a section for your
new always-on worker:

    [ubuntu-2004-static]
    type=normal

Then rebuild and relaunch buildmaster as shown above. Now you're ready to launch your new worker manually:

    cd buildbot-host
    ./launch.sh <worker-dir>

For example:

    ./launch.sh buildbot-worker-ubuntu-2004

## Wiping buildmaster's database

In Vagrant it can be useful to occasionally destroy the buildmaster's database
to clean up the webui:

    sudo rm /var/lib/docker/volumes/buildmaster/_data/libstate.sqlite

You generally don't want to do this in production if you're interested in
retaining the data about old builds.

# Usage

## Launching the buildmaster

Buildmaster uses a separate launch script:

    cd buildbot-host/buildmaster
    ./launch.sh v2.0.0

Note that you need to rebuild the buildmaster image on every configuration
change, but the process is really fast.

## Launching non-latent workers

Right now there is only one and you can launch with Vagrant:

    vagrant up buildbot-worker-windows-server-2019

The worker will automatically connect to the buildmaster if provisioning went
well.  That said, provisioning Windows tends to be way more unreliable than
provisioning Linux, so you may have to destroy and rebuild it a few times. The
main reason for provisioning failures are the reboots that are required:
Vagrant is sometimes unable to re-establish WinRM connectivity when the VM
comes back up.
