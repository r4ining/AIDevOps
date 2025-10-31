#!/bin/bash
set -ex

# 服务化多机配套变量

# export MIES_CONTAINER_IP=容器ip地址
cp -fv /app/rank-table.json /rank-table.json

# 当前服务器IP
export MIES_CONTAINER_IP=10.1.2.11 # 本机ip，两台机器不同
# 满血版本：32，量化版本：16
export WORLD_SIZE=16
# MindIE 2.0.T9/T11需要修改为export RANKTABLEFILE =
export RANK_TABLE_FILE=/rank-table.json # rank table文件路径
chmod 640 ${RANK_TABLE_FILE}

# 准备 mindie 配置文件
cp -fv /app/mindie-config.json /usr/local/Ascend/mindie/latest/mindie-service/conf/config.json
chmod 640 /usr/local/Ascend/mindie/latest/mindie-service/conf/config.json
chmod 750 -R /root/mindie

source /usr/local/Ascend/ascend-toolkit/set_env.sh
source /usr/local/Ascend/mindie/set_env.sh
source /usr/local/Ascend/mindie/latest/mindie-service/set_env.sh
source /usr/local/Ascend/mindie/latest/mindie-llm/set_env.sh
source /usr/local/Ascend/nnal/atb/set_env.sh

export MINDIE_LOG_TO_STDOUT=1
export ASDOPS_LOG_TO_STDOUT=1
export ASDOPS_LOG_LEVEL=ERROR
export ATB_LLM_HCCL_ENABLE=1
export ATB_LLM_COMM_BACKEND="hccl"
export HCCL_CONNECT_TIMEOUT=7200
export HCCL_EXEC_TIMEOUT=0
export PYTORCH_NPU_ALLOC_CONF="expandable_segments:True"

# 集合通信优化：AIV
export HCCL_OP_EXPANSION_MODE="AIV"
# 算子下发队列优化等级：2
export TASK_QUEUE_ENABLE=2
# CPU绑核：细粒度
export CPU_AFFINITY_CONF=2
# python高并发：10
export OMP_NUM_THREADS=10
# 内存最大使用比例：0.96，过大会有Failed to get engine response报错风险
export NPU_MEMORY_FRACTION=0.96


echo "================================================================================================================"
npu-smi info
echo "================================================================================================================"


cd /usr/local/Ascend/mindie/latest/mindie-service
ls -l conf
# chmod o-r conf/config.json
echo "================================================================================================================"
echo "Begin start"
echo "================================================================================================================"
./bin/mindieservice_daemon