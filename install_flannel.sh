#!/bin/bash
set -euo pipefail

# USER DEFINED
INTERFACE="enp3s0"
FLANNEL_VERSION="0.5.5"
FLANNEL="flannel-${FLANNEL_VERSION}-linux-amd64"
FLANNEL_URL="https://github.com/coreos/flannel/releases/download/v${FLANNEL_VERSION}/${FLANNEL}.tar.gz"
FLANNEL_FOLDER="/opt/flannel-${FLANNEL_VERSION}"

# DOWNLOAD
cd /opt
sudo curl -L  ${FLANNEL_URL} -o ${FLANNEL}.tar.gz
sudo tar xzvf ${FLANNEL}.tar.gz
sudo rm ${FLANNEL}.tar.gz

# CONFIGURE
etcdctl set flannel/config "{\"Network\": \"10.2.0.0/16\"}"

# SET AS A SERVICE
cd ${FLANNEL_FOLDER}
cat <<EOF > flannel.service
[Unit]
Description=flannel
Require=etcd
After=etcd

[Service]
Restart=always
#ExecStartPre=/bin/sleep 30
ExecStart=${FLANNEL_FOLDER}/flanneld \
  --etcd-prefix flannel

[Install]
WantedBy=multi-user.target
EOF

sudo cp flannel.service /etc/systemd/system/flannel.service
sudo systemctl enable flannel
sudo systemctl daemon-reload
sudo systemctl start flannel
