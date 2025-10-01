# 通用的函数

function log {
    echo -e "[$(date +'%F %T')] $@"
}

# colorized log
function log_error() {
    echo -e "[$(date +'%F %T')] \033[31mERROR\033[0m $@"
    exit 1
}

function log_warn() {
    echo -e "[$(date +'%F %T')] \033[33mWARN\033[0m $@"
}

function log_info() {
    echo -e "[$(date +'%F %T')] INFO $@"
}

function log_debug() {
    if [ ${ENABLE_DEBUG_LOG} == "true" ]; then
        echo -e "[$(date +'%F %T')] DEBUG $@"
    fi
}


# colorized echo
function echo_red {
    echo -e "[$(date +'%F %T')] \033[31m$@\033[0m"
}

function echo_green {
    echo -e "[$(date +'%F %T')] \033[32m$@\033[0m"
}

function echo_yellow {
    echo -e "[$(date +'%F %T')] \033[33m$@\033[0m"
}

function echo_blue {
    echo -e "[$(date +'%F %T')] \033[36m$@\033[0m"
}
