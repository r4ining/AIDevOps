#!/bin/bash

set -ex

CONTAINER_NAME="deepseek-r1-0528"
MANIFEST_DIR_ON_HOST="$(pwd)/conf"
MINDIE_IMAGE="swr.cn-south-1.myhuaweicloud.com/ascendhub/mindie:2.1.RC1-800I-A2-py311-openeuler24.03-lts"


function log {
    echo -e "[$(date +'%F %T')] $@"
}


log "Remove old container"
docker rm -f ${CONTAINER_NAME}

rm -rf logs
mkdir -p logs
chmod 750 -R logs

log "Start MindIE..."
docker run -itd --privileged --name=${CONTAINER_NAME} --net=host --shm-size=500g \
    --device=/dev/davinci0 \
    --device=/dev/davinci1 \
    --device=/dev/davinci2 \
    --device=/dev/davinci3 \
    --device=/dev/davinci4 \
    --device=/dev/davinci5 \
    --device=/dev/davinci6 \
    --device=/dev/davinci7 \
    --device=/dev/davinci_manager \
    --device=/dev/devmm_svm \
    --device=/dev/hisi_hdc \
    -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
    -v /usr/local/Ascend/add-ons/:/usr/local/Ascend/add-ons/ \
    -v /usr/local/sbin/:/usr/local/sbin/ \
    -v /etc/hccn.conf:/etc/hccn.conf \
    -v /model:/model \
    -v /deepseek-r1:/deepseek-r1 \
    -v ${MANIFEST_DIR_ON_HOST}:/app \
    -v $(pwd)/logs:/root/mindie/log \
    ${MINDIE_IMAGE} \
    /bin/bash /app/start.sh

log "Start container complete"
docker ps -a | grep ${CONTAINER_NAME}


docker logs -f ${CONTAINER_NAME}