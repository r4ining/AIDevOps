#!/bin/bash

set -x

export MINDIE_LOG_TO_STDOUT=1

cp -fv /app/mindie-config.json /usr/local/Ascend/mindie/latest/mindie-service/conf/config.json
chmod 640 /usr/local/Ascend/mindie/latest/mindie-service/conf/config.json

cd /usr/local/Ascend/mindie/latest/mindie-service
./bin/mindieservice_daemon