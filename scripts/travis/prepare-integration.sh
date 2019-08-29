#!/usr/bin/env bash
set -x

if [ "$(whoami)" != 'root' ]; then
	echo 'Please run with sudo'
	exit 2
fi

UBUNTU_VERSION=`lsb_release -a 2>&1 | grep Codename | grep -v "LSB" | awk '{print $2}'`

# Activate the virtualenv created during make requirements phase
source ./virtualenv/bin/activate

# install st2 client
python ./st2client/setup.py develop
st2 --version

# start dev environment in screens
./tools/launchdev.sh start -x

# This script runs as root on Travis which means other processes which don't run
# as root can't write to logs/ directory and tests fail
# This _seems_ to only be used by Mistral, which we are in the process of
# removing, so we either need to create the directory here if it doesn't exist,
# or we need to not bother with this if they don't already exist.
if [[ -d logs ]]; then
	chmod 777 logs/
	chmod 777 logs/*
fi

# Workaround for Travis on Ubuntu Xenial so local runner integration tests work
# when executing them under user "stanley" (by default Travis checks out the
# code and runs tests under a different system user).
# NOTE: We need to pass "--exe" flag to nosetests when using this workaround.
if [ "${UBUNTU_VERSION}" == "xenial" ]; then
	echo "Applying workaround for stanley user permissions issue to /home/travis on Xenial"
	chmod 777 -R /home/travis
fi
