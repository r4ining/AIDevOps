#!/bin/bash

################################################################################
# 
# 检查服务器上可疑挖矿程序
# 检查项：定时任务、使用CPU高的进程、指定路径下的文件、systemd service
# 
################################################################################

# 定时任务过滤关键词, 检查定时任务时将会过滤包含这些关键词的定时任务, 多个关键词通过 `|` 分割
CRONTAB_FILTER_KEYWORDS="curl|wget"
# systemd service 过滤关键词, 检查 systemd service 时将会过滤包含这些关键词的 systemd service, 多个关键词通过 `|` 分割
SYSTEMD_SERVICE_FILTER_KEYWORDS="miner"
# 文件检查路径, 检查指定路径下是否存在可疑的文件
FILEPATH_FILTER=(
/tmp
/var/tmp
)

function log() {
    # echo -e "[$(date +'%F %T')] INFO $@"
    echo -e "[$(date +'%F %T')] \033[36m$@\033[0m"
}

function echo_red {
    echo -e "\033[31m$@\033[0m"
}

function crontab_check() {
    log "检查定时任务"
    log "过滤关键词(通过 CRONTAB_FILTER_KEYWORDS 指定): ${CRONTAB_FILTER_KEYWORDS}"
    log "输出格式 '--- <定时任务文件名>:', 如果没有输出说明没有包含指定关键词的定时任务"
    for p in $(find /var/spool/cron /etc/cron* -type f); do
        if grep -Eiq "${CRONTAB_FILTER_KEYWORDS}" ${p}; then
            echo_red "--- ${p}:"
            grep -Ei "${CRONTAB_FILTER_KEYWORDS}" ${p}
        fi
    done

    # find /var/spool/cron /etc/cron* -type f \( -exec echo "--- {}: " \; \) -a -exec grep -Ei "${CRONTAB_FILTER_KEYWORDS}" {} \;
}

function process_check() {
    log "检查 CPU 使用最高的10个进程"
    ps aux --sort -pcpu | head -n 11

    log "查看内存使用最高的10个进程"
    ps aux --sort -pmem | head -n 11
}

function filepath_check() {
    log "检查指定路径下的文件"
    log "检查路径(通过 FILEPATH_FILTER 指定路径): ${FILEPATH_FILTER[@]}"
    ls -la ${FILEPATH_FILTER[@]}
}

function systemd_service_check() {
    log "检查 systemd service (如果没有输出代表没有找到包含对应关键词的 systemd service)"
    log "过滤关键词(通过 SYSTEMD_SERVICE_FILTER_KEYWORDS 指定): ${SYSTEMD_SERVICE_FILTER_KEYWORDS}"
    systemctl list-unit-files --type=service | grep -Ei "${SYSTEMD_SERVICE_FILTER_KEYWORDS}"
}


function main() {
    crontab_check
    process_check
    filepath_check
    systemd_service_check
    log "检查完成"
}

main
