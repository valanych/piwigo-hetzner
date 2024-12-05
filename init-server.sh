#!/bin/bash

apt_wait () {
  while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
    sleep 1
  done
  while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
    sleep 1
  done
  if [ -f /var/log/unattended-upgrades/unattended-upgrades.log ]; then
    while sudo fuser /var/log/unattended-upgrades/unattended-upgrades.log >/dev/null 2>&1 ; do
      sleep 1
    done
  fi
}

apt-get update
apt_wait
apt-get install -y \
  software-properties-common \
  add-apt-key \
  sshguard \
  mc

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository -y \
  "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

apt_wait

apt-get update -y
apt_wait
apt-get install -y docker-ce docker-ce-cli containerd.io
sudo NEEDRESTART_MODE=a apt-get upgrade -y
apt_wait
# enable automatic reboots and package pruning 
# to keep disk usage in check

DOCKER_CONFIG=${DOCKER_CONFIG:-~/.docker}

mkdir -p $DOCKER_CONFIG/cli-plugins

DOCKER_COMPOSE=$DOCKER_CONFIG/cli-plugins/docker-compose
ARCH=`uname -m`
curl -SL https://github.com/docker/compose/releases/download/v2.31.0/docker-compose-linux-${ARCH} -o $DOCKER_COMPOSE

chmod +x $DOCKER_COMPOSE
