#!/bin/bash
set -euo pipefail

cd /tmp

scripts=(etcd flannel docker kubernetes)
for SCRIPT in ${scripts[@]}
do
    chmod 755 ${SCRIPT}.sh
    ./${SCRIPT}.sh
done
