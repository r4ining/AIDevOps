#!/bin/bash

# -------------------------------------------
# 
#     Last Modified: 2025-01-09
#       Description: Server checklist
#       Script Name: precheck.sh
# 
# -------------------------------------------

# NTP 服务器配置文件
NTP_CONF_FILE="/etc/ntp.conf"
# 测试是否可以使用互联网DNS服务器时 ping 的 DNS 服务器
# DNS_TEST_SERV="223.5.5.5"

# 网卡名称, 可获取对应网卡 IP
# interface_name=(
# eth0
# bond0
# )
interface_name=($(ip link | awk '/^[0-9]+:/ && $2 !~ /^(cali|veth|lo|kube|docker|nodelocaldns|br-|cni|usb|flannel)/ {if ($(NF-6) == "UP") {print $2}}' | tr -d ':'))

function echo_blue() {
    echo -e "\033[36m$@\033[0m"
}

function echo_red() {
    echo -e "\033[31m$@\033[0m"
}

function echo_green() {
    echo -e "\033[32m$@\033[0m"
}


# 1. 显示服务器磁盘分区及挂载点（去除tmpfs/overlay/shm类型文件系统）
# 2. 检查服务器挂载点是否都记录到 /etc/fstab
function disk_partition_check() {
    # 服务器磁盘分区及挂载点
    echo_blue "[服务器磁盘分区及挂载点]"
    echo_blue "[[磁盘分区]]"
    df -hT | awk 'NR == 1 || $1 !~ /tmpfs|overlay|shm/'
    echo ""
    lsblk -l | awk 'NR > 1 && $6 == "lvm" {printf "/dev/%s 分区是 lvm \n",$1}'

    # 服务器未记录到 /etc/fstab 的挂载点
    echo_blue "[[挂载点]]"
    declare -a UNWRITE_IN_FSTAB=()
    # 已经记录到 /etc/fstab 的挂载点
    MOUNTPOINTS_IN_FSTAB=($(grep -Ev "^$|^#" /etc/fstab | awk '{print $2}'))
    # 当前已挂载的磁盘分区的挂载点
    MOUNTPOINTS=($(df -h | awk 'NR != 1 && $1 !~ /tmpfs|overlay|shm/ {print $6}'))
    for MNT_POINT in ${MOUNTPOINTS[@]}; do
        # 依次过滤挂载点，如果没有过滤到挂载点，则没有记录到 /etc/fstab 文件内
        { echo "${MOUNTPOINTS_IN_FSTAB[*]}" | grep -w "${MNT_POINT}"; } &> /dev/null
        [ $? -eq 0 ] || {
            UNWRITE_IN_FSTAB=(${UNWRITE_IN_FSTAB[@]} ${MNT_POINT})
        }
    done
    if [ ${#UNWRITE_IN_FSTAB[@]} -ne 0 ]
    then
        echo_red "以下挂载点未写入到 /etc/fstab，请注意检查: "
        for UNWRITE_POINT in ${UNWRITE_IN_FSTAB[@]}; do
            echo_red "- ${UNWRITE_POINT}"
        done
    else
        echo_green "挂载点(${MOUNTPOINTS[@]})均已记录到 /etc/fstab 文件"
    fi

    # # 判断服务器中是否有未挂载的磁盘
    # # 所有的磁盘
    # ALL_DISK=($(lsblk | awk '/^[a-zA-Z]/ && NR != 1 {print "/dev/" $1}'))
    # # 挂载的磁盘
    # MOUNTED_DISK=($(df | awk 'NR != 1 && $1 !~ /overlay|tmpfs|shm|^[0-9]+./  {print $1}'))
    # # 用于存放未挂载的磁盘
    # declare -a UNMOUNTED_DK=()
    # declare -a MOUNTED_DK=()
    # for blk_disk in ${ALL_DISK[@]}; do
    #     echo "${MOUNTED_DISK[@]}" | grep -E "${blk_disk}" &> /dev/null
    #     if [ "$?" -eq 1 ]; then
    #         UNMOUNTED_DK=("${UNMOUNTED_DK[@]}" "$blk_disk")
    #     else
    #         MOUNTED_DK=("${MOUNTED_DK}" "$blk_disk")
    #     fi
    # done
    # if [ "${#MOUNTED_DK}" -ne 0 ]; then
    #     echo "已挂载的磁盘:"
    #     counter=0
    #     for mnt_blk in ${MOUNTED_DK[@]}; do
    #         let counter++
    #         printf "  %3d. %s\n" "$counter" "$mnt_blk"
    #     done
    # fi
    # if [ "${#UNMOUNTED_DK}" -ne 0 ]; then
    #     echo_red "以下磁盘未挂载: "
    #     counter=0
    #     for unmnt_blk in ${UNMOUNTED_DK[@]}; do
    #         let counter++
    #         printf "  %3d. %s\n" "$counter" "${unmnt_blk}"
    #     done
    # fi

    echo ""
}


# 服务器基本信息总览，包括操作系统版本、内核版本、主机名
# 服务器 CPU、内存、磁盘、显卡、信息
# 是否支持 avx/avx2/bmi2 指令集
function resource_overview() {
    echo ""
    echo_blue "[服务器信息]"
    echo_red "请确认系统版本/内核版本/主机名是否符合要求"

    # 操作系统版本、内核版本、系统主机名
    echo -e "服务器操作系统版本: `awk -F '[="]*' '/PRETTY_NAME/ {print $2}' /etc/os-release`"
    echo -e "服务器内核版本:     `uname -r`"
    echo -e "服务器主机名:       `hostname`"
    echo -e "服务器架构:         `arch`"
    echo "服务器网卡 IP:"
    for iface in ${interface_name[@]}; do
        iface_ip="$(ip a s ${iface} | awk -F '[/ ]*' '$2 ~ /^inet$/ {printf "%s ",$3}')"
        if [ x"${iface_ip}" != x"" ]; then
            echo "- ${iface}: ${iface_ip}"
        else
            echo_red "- ${iface}: (! 无法获取 IP 信息)"
        fi
    done
    # 服务器是否为物理机
    # dmidecode | grep -EA 2 "^System Information"

    echo ""
    echo_blue "[服务器资源]"
    echo_red "请确认服务器资源是否可以达到产品需求"
    echo_blue "[[CPU]]"
    # CPU 核数
    CPU_MODEL=$(lscpu | sed -nr '/^Model name/s/Model name:\s*//p')
    CPU_CORES=$(nproc)
    # printf "CPU 核数: %s\n" "$CPU_CORES"
    echo "CPU 核数: $CPU_CORES"
    echo "CPU 型号: $CPU_MODEL"
    # 判断是否支持 avx/avx2/bmi2 指令
    cat /proc/cpuinfo | grep -w avx &> /dev/null && echo_green "机器CPU支持 avx 指令" || echo_red "机器CPU不支持 avx 指令"
    cat /proc/cpuinfo | grep -w avx2 &> /dev/null && echo_green "机器CPU支持 avx2 指令" || echo_red "机器CPU不支持 avx2 指令"
    cat /proc/cpuinfo | grep -w bmi2 &> /dev/null && echo_green "机器CPU支持 bmi2 指令" || echo_red "机器CPU不支持 bmi2 指令"

    # 服务器内存
    echo_blue "[[内存]]"
    MEM_INFO=$(free -h | awk '/^Mem/ {print $2}')
    printf "内存大小: %s\n" "$MEM_INFO"

    # 服务器硬盘数量/大小
    echo_blue "[[磁盘]]"
    lsblk | {
        awk 'BEGIN{
                DISK_NUM=0
                printf "服务器磁盘及大小: \n"
            }
            /^[a-zA-Z]/ && NR != 1 && $1 !~ /sr0|loop/ {
                DISK_NUM++
                printf "  %3d. /dev/%s    %s\n",DISK_NUM,$1,$4
            } END {
                printf "磁盘总数量: %s\n",DISK_NUM
        }'
    }

    # 判断是否存在 lspci 命令, 如果不存在就提示
    echo_blue "[[显卡]]"
    command -v lspci &> /dev/null || echo_red "[!] 没有 lspci 命令无法查看 GPU 卡信息"
    has_lspci=$?

    # 如果有 lspci 命令就检查
    if [ "$has_lspci" -eq 0 ]
    then
        # 判断是否有 NVIDIA 显卡，如果有就显示显卡信息，如果没有就输出提示
        lspci | grep NVIDIA &> /dev/null
        if [ $? -eq 0 ]
        then
            echo "NVIDIA 显卡信息: "
            echo '参考命令: lspci | grep NVIDIA'
            lspci | grep NVIDIA
        else
            echo_red "[!] 该机器没有 NVIDIA 显卡，请确认该产品是否需要 GPU 资源"
        fi
    fi

    echo ""
}


# 使用函数来检查每个服务
function systemd_service_check(){
    svc="$1"
    systemctl disable --now $svc &> /dev/null
    # 获取 firewalld 状态
    svc_state=$(systemctl is-active $svc)
    svc_enable=$(systemctl is-enabled $svc)
    # 如果 firewalld 状态不是 active, 并且不是开机自启则提示关闭成功
    if [[ "${svc_state}" != "active" && "${svc_enable}" == "disabled" ]]
    then
        echo "$svc 已经关闭且关闭开机自启"
    elif [[ "${svc_state}" == "unknown" ]]; then
        echo_red "$svc 没有该服务, 请手动检查"
    else
        echo_red "$svc 可能还在运行或者会开机自启, 请手动检查"
    fi
}


# 关闭 firewalld/SELinux/NetworkManager
function check_service(){
    echo_blue "[服务检查]"
    echo_red "该过程会关闭 firewalld/SELinux/NetworkManager"
    echo_red "请确保 firewalld/SELinux/NetworkManager 已关闭"
    echo_red "* NetworkManager 可能会造成软死锁、服务器宕机等问题"
    # 关闭 firewalld
    systemd_service_check firewalld

    # 关闭 SELinux
    setenforce 0 &> /dev/null
    sed -ri "/SELINUX/s/(SELINUX=).*/\1disabled/" /etc/selinux/config
    echo "SELinux 当前状态为: $(getenforce)"

    # 关闭 NetworkManager
    systemd_service_check NetworkManager

    echo ""
}


# 1. 检查时间同步相关信息
# 2. 如果已经开启时间同步，列出配置的时间同步服务器
function time_sync_check() {
    echo_blue "[时间同步]"
    echo_red "注意时间是否同步以及时区"
    # 是否有 NTP 时间同步服务器
    DATE_TIME="$(date "+%Y-%m-%d %H:%M:%S")"
    HW_CLOCK="$(hwclock)"
    HW_CLOCK_DATETIME="$(echo ${HW_CLOCK} | awk -F '.' '{print $1}')"
    echo "服务器当前系统时间为: ${DATE_TIME}"
    echo "服务器当前硬件时间为: ${HW_CLOCK_DATETIME}"

    # 设置语言环境, 避免命令结果为中文, 影响获取到的时间
    export LANG="en_US.UTF-8"
    date_tz="$(date "+%Z")"
    # hwclock_tm="$(hwclock | awk -F '[ :]+' '{if ($8=="AM"){printf "%s%s%s_%d%0*d",$4,$3,$2,$5,2,$6}else{printf "%s%s%s_%d%0*d",$4,$3,$2,($5+12),2,$6}}')"
    # hwclock_tz="$(hwclock | awk '{print $7}')"
    hwclock_tz="$(echo ${HW_CLOCK} | awk -F '+' '{if ($2 == "08:00"){print "CST"}else{print $2}}')"
    if [[ x"${DATE_TIME}" == x"${HW_CLOCK_DATETIME}" ]] && [[ x"${date_tz}" == x"CST" ]] && [[ x"${hwclock_tz}" == x"CST" ]]; then
        echo_green "系统时间与硬件时间相同,且服务器时区为 CST"
    else
        echo_red "系统时间与硬件时间不同或且服务器时区(系统时区与硬件时区)非 CST, 请检查并同步"
        echo "建议:"
        echo "  1. 先检查系统时间是否与时区时间一致, 如果不一致则需要手动同步"
        echo "  2. 使用 'hwclock -w' 命令将系统时间同步到硬件时间"
    fi

    # echo "正在检查是否开启 NTP 同步..."
    # # 清除上一行输出
    # printf "\033[A"
    # timedatectl | {
    #     awk '/^NTP synchronized:/ {
    #         printf "NTP 时间同步(NTPD)是否启用: %s %s\n",$3,"     "
    #     }'
    # }
    # [ -f "${NTP_CONF_FILE}" ] && {
    #     grep -E "^server" "${NTP_CONF_FILE}" &> /dev/null
    # } && {
    #     awk 'BEGIN {
    #             print "已配置的 NTP 服务器(NTPD):"
    #         }
    #         /^server/ {
    #             printf "  - %s\n",$2
    #     }' "${NTP_CONF_FILE}"
    # }

    echo ""
}


function main() {
    resource_overview
    disk_partition_check
    # Ubuntu 22.04 中禁用检查Service功能
    # check_service
    time_sync_check
}


# 调用函数，运行脚本
main
