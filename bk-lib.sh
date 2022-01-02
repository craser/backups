#!/bin/bash

. "$HOME/.bk-conf"

function title {
    log "################################################################################"
    log "$1"
    log "################################################################################"
}    

function log {
    echo "[$(date "+%Y.%m.%d-%H.%M.%S")] $*" | tee -a "$backup_log"
}
    
function count_volumes {
    num_volumes=`diskutil list | grep -i "$1" | wc -l`
    echo $num_volumes
}

function get_volume_id {
    volume_id=`diskutil list | grep -i "$1" | sed -n -e 's/^.* //p'`
    echo $volume_id
}

function get_dst_dir {
    echo "/Volumes/${backup_drive}/`hostname`/`echo $backup_dir | sed 's/^\///'`"
}

function get_src_dir {
    echo "$backup_dir"
}

function backup_files {
    src_dir=`get_src_dir`
    dst_dir=`get_dst_dir`
    log "src: $src_dir"
    log "dst: $dst_dir"
    mkdir -p "$dst_dir" | sed "s/^/    /" >> "$backup_log"
    log "starting rsync"
    rsync -av --delete "$src_dir" "$dst_dir" 2>&1 >> "$backup_log"
    log "rsync complete: exit $?"
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
            diskutil mount "$volume_id" | sed "s/^/    /" >> "$backup_log"
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
    diskutil unmount "$volume_id" | sed "s/^/    /" >> "$backup_log"
}

