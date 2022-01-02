#!/bin/bash

. "$HOME/.bk-conf"

function log {
    echo "[$(date "+%Y.%m.%d-%H.%M.%S")] $*"
}
    
function count_volumes {
    num_volumes=`diskutil list | grep -i "$1" | wc -l`
    echo $num_volumes
}

function get_volume_id {
    volume_id=`diskutil list | grep -i "$1" | sed -n -e 's/^.* //p'`
    echo $volume_id
}

function bk-mount {
    volume_name="$1"
    log "(re)mounting $1"
    num_volumes=`count_volumes "$volume_name"`
    log "found $num_volumes volumes matching '$volume_name'"
    case $num_volumes in
        0)
            log "exiting"
            exit 11
            ;;
        1)
            volume_id=`get_volume_id "$volume_name"`
            log "mounting: $volume_id"
            diskutil mount "$volume_id" | sed "s/^/    /"
            exit $?
            ;;
        *)
            log "NOT mounting any drives"
            log "exiting"
            exit 11
            ;;
    esac
}

function bk-unmount {
    volume_name="$1"
    log "unmounting $1"
    volume_id=`get_volume_id "$volume_name"`
    log "mounting: $volume_id"
    diskutil unmount "$volume_id" | sed "s/^/    /"
    exit $?
}

