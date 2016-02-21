#!/bin/bash
set -euo pipefail

# ====================== CERTIFICATES ======================
# ==========================================================

# INFO: this script is an implementation of that page :
#   https://coreos.com/kubernetes/docs/latest/openssl.html

# control usage
if [[ ! -f config.sh ]]; then
        echo "you need to fill the config.sh file first"
        exit 1
fi

# some declaration

testfile() {
        if [[ -e $1 ]]; then
                echo -e " \e[92m==>\e[39m $1 generated"
        else
                echo -e "\e[91merror with $1\e[39m"
                exit 1
        fi
}

# import configuration
. ./config.sh

# ========== ARCHIVE PREVIOUS STUFF ============
# ==============================================
echo -e "\e[92mClean previous certificates\e[39m"
mkdir -p ${TEMP_SSL_PATH}
[ "$(ls -A ${TEMP_SSL_PATH})" ] \
 && rm ${TEMP_SSL_PATH}/*
cd ${TEMP_SSL_PATH}

# ========== Create a Cluster Root CA ==========
# ==============================================
echo -e "\e[92m\nCreate cluster Root CA\e[39m"
openssl genrsa -out $CA_KEY_PEM_NAME 2048
testfile $CA_KEY_PEM_NAME

openssl req -x509 -new -nodes -key $CA_KEY_PEM_NAME \
    -days 10000 -out $CA_PEM_NAME -subj "/CN=kube-ca"
testfile $CA_PEM_NAME



# ======= Generate the API Server Keypair ======
# ==============================================
echo -e "\e[92m\n\nGenerate the API Server Keypair\e[39m"
cat <<EOF > $OPENSSL_CNF_NAME
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
IP.1 = ${K8S_SERVICE_IP}
IP.2 = ${MASTER_IP}
EOF

testfile $OPENSSL_CNF_NAME


openssl genrsa -out $APISERVER_KEY_PEM_NAME 2048
testfile $APISERVER_KEY_PEM_NAME

openssl req -new -key $APISERVER_KEY_PEM_NAME         \
  -out $APISERVER_CSR_NAME -subj "/CN=kube-apiserver" \
  -config $OPENSSL_CNF_NAME

testfile $APISERVER_CSR_NAME

openssl x509 -req -in $APISERVER_CSR_NAME               \
  -CA $CA_PEM_NAME -CAkey $CA_KEY_PEM_NAME -CAcreateserial   \
  -out $APISERVER_PEM_NAME -days 365 -extensions v3_req \
  -extfile $OPENSSL_CNF_NAME
testfile $APISERVER_PEM_NAME




# ======= Generate the Kubernetes Worker Keypair ======
# =====================================================
echo -e "\e[92m\n\nGenerate the API Server Keypair\e[39m"
openssl genrsa -out $WORKER_KEY_PEM_NAME 2048
testfile $WORKER_KEY_PEM_NAME

openssl req -new -key $WORKER_KEY_PEM_NAME      \
  -out $WORKER_CSR_NAME -subj "/CN=kube-worker"
testfile $WORKER_CSR_NAME

openssl x509 -req -in $WORKER_CSR_NAME                \
  -CA $CA_PEM_NAME -CAkey $CA_KEY_PEM_NAME -CAcreateserial \
  -out $WORKER_PEM_NAME -days 365
testfile $WORKER_PEM_NAME




# ==== Generate the Cluster Administrator Keypair ====
# ====================================================
echo -e "\e[92m\n\nGenerate the Cluster Administrator Keypair\e[39m"
openssl genrsa -out $ADMIN_KEY_PEM_NAME 2048
testfile $ADMIN_KEY_PEM_NAME

openssl req -new -key $ADMIN_KEY_PEM_NAME     \
  -out $ADMIN_CSR_NAME -subj "/CN=kube-admin"
testfile $ADMIN_CSR_NAME

openssl x509 -req -in $ADMIN_CSR_NAME                 \
  -CA $CA_PEM_NAME -CAkey $CA_KEY_PEM_NAME -CAcreateserial \
  -out $ADMIN_PEM_NAME -days 365
testfile $ADMIN_PEM_NAME
