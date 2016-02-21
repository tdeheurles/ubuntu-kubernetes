#! /bin/bash
set -euo pipefail

. ./helpers.sh

print_title1 "DOCKER"

INSTALL="sudo apt-get install -y"
UPDATE="sudo apt-get update"

${UPDATE}
${INSTALL} apt-transport-https ca-certificates
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 \
    --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-wily main" > /tmp/docker.list
sudo mv /tmp/docker.list /etc/apt/sources.list.d/docker.list

${UPDATE}
sudo apt-get purge lxc-docker || true
sudo apt-cache policy docker-engine || true

${UPDATE}
${INSTALL} linux-image-extra-$(uname -r)
${INSTALL} docker-engine
sudo usermod -aG docker vagrant
sudo systemctl stop docker

cat <<EOF > /tmp/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network.target docker.socket
Requires=docker.socket

[Service]
Type=notify
EnvironmentFile=/run/flannel/subnet.env
ExecStart=/usr/bin/docker daemon -H fd:// --bip=\${FLANNEL_SUBNET} --mtu=\${FLANNEL_MTU}
MountFlags=slave
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
sudo mv /tmp/docker.service /etc/systemd/system/docker.service
sudo systemctl daemon-reload
sudo systemctl start docker

cat <<EOF >> /home/vagrant/.bashrc

# DOCKER
# ======
alias dps="docker ps" 
EOF
