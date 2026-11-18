#!/bin/bash

# Classify disk-space utilization.
classify_disk_usage() {
    local usage="$1"
    local warning_threshold="$2"
    local critical_threshold="$3"

    if [[ ! "$usage" =~ ^[0-9]+([.][0-9]+)?$ ]] ||
       [[ ! "$warning_threshold" =~ ^[0-9]+([.][0-9]+)?$ ]] ||
       [[ ! "$critical_threshold" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        return 2
    fi

    awk -v usage="$usage" \
        -v warning="$warning_threshold" \
        -v critical="$critical_threshold" '
        BEGIN {
            if (usage >= critical)
                print "CRITICAL"
            else if (usage >= warning)
                print "WARNING"
            else
                print "OK"
        }
    '
}

# Classify inode utilization.
classify_inode_usage() {
    local usage="$1"
    local warning_threshold="$2"
    local critical_threshold="$3"

    if [[ ! "$usage" =~ ^[0-9]+([.][0-9]+)?$ ]] ||
       [[ ! "$warning_threshold" =~ ^[0-9]+([.][0-9]+)?$ ]] ||
       [[ ! "$critical_threshold" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        return 2
    fi

    awk -v usage="$usage" \
        -v warning="$warning_threshold" \
        -v critical="$critical_threshold" '
        BEGIN {
            if (usage >= critical)
                print "CRITICAL"
            else if (usage >= warning)
                print "WARNING"
            else
                print "OK"
        }
    '
}

# Check disk-space utilization across mounted filesystems.
check_disk_health() {
    local mount usage status df_output

    echo "----- DISK SPACE HEALTH CHECK -----"

    if ! df_output="$(df -P -x tmpfs -x devtmpfs -x squashfs -x iso9660)"; then
        echo "ERROR: Unable to read disk usage"
        set_status 1
        return 1
    fi

    echo "$df_output"

    while read -r _ mount usage; do
        [[ "$usage" =~ ^[0-9]+%$ ]] || continue

        usage="${usage%\%}"

        status="$(classify_disk_usage \
            "$usage" "$DISK_WARNING_THRESHOLD" "$DISK_CRITICAL_THRESHOLD")" || {
            echo "ERROR: Unable to classify disk usage for $mount"
            set_status 1
            continue
        }

        echo "$status: $mount disk usage is ${usage}%"

        case "$status" in
            WARNING) set_status 1 ;;
            CRITICAL) set_status 2 ;;
        esac

    done < <(
        awk 'NR > 1 { print $1, $6, $5 }' <<< "$df_output"
    )
}

# Check inode utilization across mounted filesystems.
check_inode_health() {
    local mount usage status df_output

    echo "----- INODE HEALTH CHECK -----"

    if ! df_output="$(df -iP -x tmpfs -x devtmpfs -x squashfs -x iso9660)"; then
        echo "ERROR: Unable to read inode usage"
        set_status 1
        return 1
    fi

    echo "$df_output"

    while read -r _ mount usage; do
        [[ "$usage" =~ ^[0-9]+%$ ]] || continue

        usage="${usage%\%}"

        status="$(classify_inode_usage \
            "$usage" "$INODE_WARNING_THRESHOLD" "$INODE_CRITICAL_THRESHOLD")" || {
            echo "ERROR: Unable to classify inode usage for $mount"
            set_status 1
            continue
        }

        echo "$status: $mount inode usage is ${usage}%"

        case "$status" in
            WARNING) set_status 1 ;;
            CRITICAL) set_status 2 ;;
        esac

    done < <(
        awk 'NR > 1 { print $1, $6, $5 }' <<< "$df_output"
    )
}
