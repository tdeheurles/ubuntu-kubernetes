#! /bin/bash
set -euo pipefail

. ./config.sh

./generate_certificates.sh
sudo mkdir -p ${SSL_PATH}
sudo mv ${TEMP_SSL_PATH}/* ${SSL_PATH}/

sudo mkdir -p ${KUBERNETES_FOLDER}
cd ${KUBERNETES_FOLDER}

DOCKER_SERVICE=(kubelet kube-apiserver kube-proxy kube-scheduler kube-controller)
for SERVICE in "kubectl" 
do
    sudo curl -O https://storage.googleapis.com/kubernetes-release/release/v${VERSION}/bin/linux/amd64/${SERVICE}
    sudo chmod 755 ${SERVICE}
done

cat <<EOF >> ~/.zshrc

# KUBERNETES
# ==========

export PATH="\${PATH}:${KUBERNETES_FOLDER}"
EOF

# API SERVER
cat <<EOF >> kube-apiserver.service
[Unit]
Description=Kubernetes apiserver
Documentation=https://github.com/kubernetes/kubernetes
Requires=flanneld.service
After=flanneld.service

[Service]
ExecStart=${KUBERNETES_FOLDER}/kube-apiserver                \
    --bind-address=0.0.0.0                                   \
    --etcd_servers=${ETCD_CLIENT}                            \
    --allow-privileged=true                                  \
    --service-cluster-ip-range=${SERVICE_IP_RANGE}           \
    --secure_port=443                                        \
    --advertise-address=${PUBLIC_IP}                         \
    --tls-cert-file=${SSL_PATH}/apiserver.pem                \
    --tls-private-key-file=${SSL_PATH}/apiserver-key.pem     \
    --client-ca-file=${SSL_PATH}/ca.pem                      \
    --service-account-key-file=${SSL_PATH}/apiserver-key.pem \
    --cloud-provider=                                        \
    --admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF 

# KUBELET
cat <<EOF >> kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
Requires=flanneld.service
After=flanneld.service

[Service]
ExecStartPre=/usr/bin/mkdir -p ${KUBERNETES_MANIFEST_FOLDER}
ExecStart=${KUBERNETES_FOLDER}/kubelet     \
    --api-servers=http://127.0.0.1:8080    \
    --register-node=true                   \
    --allow-privileged=true                \
    --config=${KUBERNETES_MANIFEST_FOLDER} \
    --hostname-override=${PUBLIC_IP}       \
    --cluster_dns=${DNS_SERVICE_IP}        \
    --cluster_domain=cluster.local         \
    --cadvisor-port=${CADVISOR_PORT}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF 

# PROXY
cat <<EOF >> kube-proxy.service
[Unit]
Description=Kubernetes proxy
Documentation=https://github.com/kubernetes/kubernetes
Requires=flanneld.service
After=flanneld.service

[Service]
ExecStart=${KUBERNETES_FOLDER}/kube-proxy \
    --master=https://127.0.0.1:8080       \
    --kubeconfig=/etc/kubernetes/worker-kubeconfig.yml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF 

# CONTROLLER MANAGER
cat <<EOF >> kube-controller.service
[Unit]
Description=Kubernetes controller-manager
Documentation=https://github.com/kubernetes/kubernetes
Requires=flanneld.service
After=flanneld.service

[Service]
ExecStart=${KUBERNETES_FOLDER}/kube-controller                       \
    --master=http://127.0.0.1:8080                                   \
    --service-account-private-key-file=${SSL_PATH}/apiserver-key.pem \
    --root-ca-file=${SSL_PATH}/ca.pem
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF 

# SCHEDULER
cat <<EOF >> kube-scheduler.service
[Unit]
Description=Kubernetes scheduler
Documentation=https://github.com/kubernetes/kubernetes
Requires=flanneld.service
After=flanneld.service

[Service]
ExecStart=${KUBERNETES_FOLDER}/kube-scheduler \
    --master=http://127.0.0.1:8080
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# KUBECONFIG
cat <<EOF >> worker-kubeconfig.yml
apiVersion: v1
kind: Config
clusters:
- name: local
  cluster:
    certificate-authority: ${SSL_PATH}/ca.pem
users:
- name: kubelet
  user:
    client-certificate: ${SSL_PATH}/worker.pem
    client-key: ${SSL_PATH}/worker-key.pem
contexts:
- context:
    cluster: local
    user: kubelet
  name: kubelet-context
current-context: kubelet-context
EOF
