#!/bin/bash

# Calculate memory utilization percentage.
get_memory_usage() {
    local total available

    read -r total available < <(
        awk '/^Mem:/ {
            print $2, $7
        }' < <(free -b)
    )

    if [[ ! "$total" =~ ^[0-9]+$ ]] ||
       [[ ! "$available" =~ ^[0-9]+$ ]] ||
       (( total <= 0 || available > total )); then
        return 1
    fi

    awk -v total="$total" -v available="$available" '
        BEGIN {
            printf "%.2f", (total - available) / total * 100
        }
    '
}

# Classify memory utilization.
classify_memory_usage() {
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
