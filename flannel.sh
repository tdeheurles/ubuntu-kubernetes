#!/bin/bash
#set -euo pipefail

. ./config.sh

# DOWNLOAD
cd /opt
sudo curl -L  ${FLANNEL_URL} -o ${FLANNEL}.tar.gz
sudo tar xzvf ${FLANNEL}.tar.gz
sudo rm ${FLANNEL}.tar.gz

# CONFIGURE
${ETCD_FOLDER}/etcdctl set flannel/config "{\"Network\": \"10.2.0.0/16\"}"

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
