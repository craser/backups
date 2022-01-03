#!/bin/bash

. "$HOME/.bk-conf"

lock_file="$HOME/.bk-lock"
max_log_size_megabytes=5
max_log_age_days=30

function title {
    log "################################################################################"
    log "$1"
    log "################################################################################"
}    

function tstamp {
    date "+%Y.%m.%d-%H.%M.%S"
}

function get_log_size {
    log_megabytes=`du -m ~/.bk.log | sed 's/^\([0-9]*\).*/\1/'`
    echo log_megabytes
}

function delete_old_logs {
    log "deleting old log files"
    for log_file in `find . -maxdepth 1 -name ".bk.log*" -ctime +${max_log_age_days}d 2>/dev/null`; do
        log "DELETING old log file: $log_file"
        rm -f "$log_file"
    done
    log "done deleting old log files"
}

function rotate_logs {
    log "rotating logs"
    log_megabytes=`get_log_size`
    if [ $log_megabytes -gt $max_log_size_megabytes ]; then
        new_log="$backup_log.`tstamp`"
        log "renaming $backup_log to $new_log"
        mv "$backup_log" "$new_log"
        touch "$backup_log"
    fi
    log "done rotating logs"
}

function init_log {
    rotate_logs
    delete_old_logs
}

function log {
    echo "[`tstamp`] $*" | tee -a "$backup_log"
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

function create_lock {
    log "creating lock file: $lock_file"
    if [ -f "$lock_file" ]; then
        log "EXISTING LOCK FILE FOUND: $lock_file"
        log "EXITING"
        exit 20
    else
        log "creating lock file: $lock_file"
        touch "$lock_file"
    fi
}

function delete_lock {
    log "deleting lock file: $lock_file"
    rm -f "$lock_file"
}

function backup_files {
    src_dir=`get_src_dir`
    dst_dir=`get_dst_dir`
    log "src: $src_dir"
    log "dst: $dst_dir"
    mkdir -p "$dst_dir" | sed "s/^/    /" >> "$backup_log"
    log "starting rsync"
    rsync -av --delete --ignore-errors "$src_dir" "$dst_dir" 2>&1 >> "$backup_log"
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

