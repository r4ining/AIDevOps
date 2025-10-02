#!/bin/bash

# 同步镜像

# 镜像需要包含镜像仓库, 比如: docker.io/grafana/grafana:12.1.1, 不能是 grafana/grafana:12.1.1
# image_file=${1:-image-list.txt}
image_file="image-list.txt"

REGISTRY="swr.cn-east-3.myhuaweicloud.com/r4in"

images=($(grep -Ev "^#|^$" ${image_file}))

function log {
    echo -e "[$(date +'%F %T')] $@"
}

function usage() {
    cat <<EOF
Usage:
    $0          # 同步镜像
    $0 tags     # 获取同步后的镜像tag
EOF
}

# 同步镜像
function img_sync() {
    log "Image sync..."

    counter=1
    image_num=${#images[@]}

    for img in ${images[@]}; do
        log "[${counter}/${image_num}] ${img}"
        # 提取镜像中间部分(去除镜像中第一个 / 及之前的内容和最后一个/及之后的内容)，用于拼接同步到的目标镜像仓库的镜像名称
        # 比如：docker.io/grafana/grafana:12.1.1, 将会去除 "docker.io/" 和 "/grafana:12.1.1", 仅保留中间的一部分, 即 "grafana"
        # 比如：docker.io/grafana/aaaaa/grafana:12.1.1, 将会去除 "docker.io/" 和 "/grafana:12.1.1", 仅保留中间的一部分, 即 "grafana/aaaaa"
        # 要求镜像必须带有镜像仓库, 比如: docker.io, registry.k8s.io 等
        img_part="$(echo ${img} | sed -En 's|^[^/]*/(.+)/[^/:]+(:.*)?$|\1|p')"

        # skopeo 会自动提取原始镜像的镜像名, 然后拼接到目标镜像
        # 比如: docker.io/grafana/grafana:12.1.1, skopeo 会自动提取到最后的 grafana:12.1.1, 然后加上上面提取的 ${img_part} (在这里就是 grafana), 以及自己的镜像仓库 REGISTRY (比如 swr.cn-east-3.myhuaweicloud.com/xxx 或 harbor.xxx.com), 
        # 那么目标镜像将会是: swr.cn-east-3.myhuaweicloud.com/xxx/grafana/grafana:12.1.1
        skopeo sync --all --src docker --dest docker ${img} ${REGISTRY}/${img_part}

        let counter++
    done
}

# 获取同步后的镜像tag
function img_tags() {
    log "Image tags..."
    (
        echo "Origin_Tag New_Tag"
    for img in ${images[@]}; do
        echo "${img} ${REGISTRY}/${img#*/}"
    done) | column -t
}

function main() {
    case $1 in
    tags)
        img_tags ;;
    -h)
        usage ;;
    *)
        img_sync ;;
    esac
}

main $@
