#!/bin/bash

set -x

CONTAINER_NAME="qwen3-30b-a3b"
ENTRYPOINT_FILE="start.sh"
# CONFIG_FILE="mindie-config.json"

docker rm -f ${CONTAINER_NAME}

docker run -itd --privileged --name ${CONTAINER_NAME} --shm-size=50g \
    -p 1025:1025 \
    -e ASCEND_RT_VISIBLE_DEVICES="0,1" \
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
    -v /var/log/npu/slog/:/var/log/npu/slog \
    -v /var/log/npu/profiling/:/var/log/npu/profiling \
    -v /var/log/npu/dump/:/var/log/npu/dump \
    -v /var/log/npu/:/usr/slog \
    -v /etc/hccn.conf:/etc/hccn.conf \
    -v $(pwd):/app \
    -v /deepseek-r1:/deepseek-r1 \
    swr.cn-south-1.myhuaweicloud.com/ascendhub/mindie:2.1.RC1-800I-A2-py311-openeuler24.03-lts \
    /bin/bash /app/${ENTRYPOINT_FILE}

docker ps 
