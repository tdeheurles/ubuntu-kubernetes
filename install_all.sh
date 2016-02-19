#!/bin/bash
set -euo pipefail

sudo apt-get update
sudo apt-get install curl -y

URL="TO_DEFINE"

./install_zsh.sh
./install_etcd.sh
./install_flannel.sh
./install_docker.sh
./install_kubernetes.sh
