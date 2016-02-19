#!/bin/bash
set -euo pipefail

ETCD_VERSION="2.2.5"
ETCD="etcd-v${ETCD_VERSION}-linux-amd64"
ETCD_FOLDER="/opt/${ETCD}"

# DOWNLOAD
cd /opt
sudo curl -L  https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/${ETCD}.tar.gz \
  -o ${ETCD}.tar.gz
sudo tar xzvf ${ETCD}.tar.gz
sudo rm ${ETCD}.tar.gz

# SET AS A SERVICE
cd ${ETCD_FOLDER}
cat <<EOF > etcd.service
[Unit]
Description=etcd

[Service]
Restart=always
ExecStart=/opt/${ETCD}/etcd

[Install]
WantedBy=multi-user.target
EOF

sudo cp etcd.service /etc/systemd/system/etcd.service
sudo systemctl enable etcd
sudo systemctl start etcd

# ADD TO PATH
cat <<EOF >> ~/.zshrc

# ETCD
# ====
export PATH="\${PATH}:${ETCD_FOLDER}"
EOF
