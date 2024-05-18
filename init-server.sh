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

whoami > ~/whoami

apt-get update
apt_wait
apt-get install -y \
  software-properties-common \
  add-apt-key \
  sshguard

echo "0" >> ~/whoami

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

echo "1" >> ~/whoami

add-apt-repository -y \
  "deb [arch=arm64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

echo "2"

apt_wait

echo "2.0"

apt-get update -y
apt_wait
echo "2.1"
apt-get install -y docker-ce docker-ce-cli containerd.io 2>&1 >> ~/whoami
echo "2.2"
#sudo NEEDRESTART_MODE=a apt-get upgrade -y

# enable automatic reboots and package pruning 
# to keep disk usage in check

echo "3" >> ~/whoami

#sed \
#  -e 's/\/\/Unattended-Upgrade::Automatic-Reboot/Unattended-Upgrade::Automatic-Reboot/' \
#  -e 's/\/\/Unattended-Upgrade::Remove-Unused-Kernel-Packages/Unattended-Upgrade::Remove-Unused-Kernel-Packages/' \
#  -e 's/\/\/Unattended-Upgrade::Remove-New-Unused-Dependencies/Unattended-Upgrade::Remove-New-Unused-Dependencies/' \
#  < /etc/apt/apt.conf.d/50unattended-upgrades \
#  > /tmp/50unattended-upgrades
#mv /tmp/50unattended-upgrades /etc/apt/apt.conf.d/
 
echo "4 before" >> ~/whoami

echo $DOCKER_CONFIG >> ~/whoami

DOCKER_CONFIG=${DOCKER_CONFIG:-~/.docker}

echo "5 after"
echo $HOME >> ~/whoami
echo $DOCKER_CONFIG >> ~/whoami

mkdir -p $DOCKER_CONFIG/cli-plugins 2>&1 >> ~/whoami

DOCKER_COMPOSE=$DOCKER_CONFIG/cli-plugins/docker-compose
echo "6" >> ~/whoami
curl -SL https://github.com/docker/compose/releases/download/v2.6.1/docker-compose-linux-aarch64 -o $DOCKER_COMPOSE

echo "7" >> ~/whoami
chmod +x $DOCKER_COMPOSE

#reboot
