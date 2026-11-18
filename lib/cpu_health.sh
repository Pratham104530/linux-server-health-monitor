#!/bin/bash

# Classify CPU utilization using configurable thresholds.
classify_cpu_usage() {
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

