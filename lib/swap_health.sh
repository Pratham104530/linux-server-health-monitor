#!/bin/bash

# Calculate swap utilization percentage.
get_swap_usage() {
    local total used

    read -r total used < <(
        awk '/^Swap:/ {
            print $2, $3
        }' < <(free -b)
    )

    if [[ ! "$total" =~ ^[0-9]+$ ]] ||
       [[ ! "$used" =~ ^[0-9]+$ ]] ||
       (( used > total )); then
        return 1
    fi

    if (( total == 0 )); then
        printf '0.00'
        return 0
    fi

    awk -v total="$total" -v used="$used" '
        BEGIN {
            printf "%.2f", (used / total) * 100
        }
    '
}

# Classify swap utilization.
classify_swap_usage() {
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

