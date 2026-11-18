#!/bin/bash

# Validate that a value is a non-negative integer or decimal.
is_numeric() {
    [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

# Validate percentage thresholds.
validate_percentage_threshold() {
    local name="$1"
    local value="$2"

    if ! is_numeric "$value"; then
        echo "ERROR: $name must be numeric"
        return 1
    fi

    if ! awk -v value="$value" \
        'BEGIN { exit !(value >= 0 && value <= 100) }'; then
        echo "ERROR: $name must be between 0 and 100"
        return 1
    fi
}

# Validate warning and critical threshold relationships.
validate_threshold_pair() {
    local name="$1"
    local warning="$2"
    local critical="$3"

    if ! validate_percentage_threshold "${name}_WARNING_THRESHOLD" "$warning"; then
        return 1
    fi

    if ! validate_percentage_threshold "${name}_CRITICAL_THRESHOLD" "$critical"; then
        return 1
    fi

    if ! awk -v warning="$warning" -v critical="$critical" \
        'BEGIN { exit !(warning < critical) }'; then
        echo "ERROR: $name warning threshold must be lower than critical threshold"
        return 1
    fi
}

# Validate all monitoring configuration values.
validate_monitor_config() {
    local valid=0

    if ! is_numeric "${CPU_LOAD_THRESHOLD:-}"; then
        echo "ERROR: CPU_LOAD_THRESHOLD must be numeric"
        valid=1
    fi

    validate_threshold_pair CPU \
        "${CPU_WARNING_THRESHOLD:-}" \
        "${CPU_CRITICAL_THRESHOLD:-}" || valid=1

    validate_threshold_pair MEMORY \
        "${MEMORY_WARNING_THRESHOLD:-}" \
        "${MEMORY_CRITICAL_THRESHOLD:-}" || valid=1

    validate_threshold_pair DISK \
        "${DISK_WARNING_THRESHOLD:-}" \
        "${DISK_CRITICAL_THRESHOLD:-}" || valid=1

    validate_threshold_pair INODE \
        "${INODE_WARNING_THRESHOLD:-}" \
        "${INODE_CRITICAL_THRESHOLD:-}" || valid=1

    validate_threshold_pair SWAP \
    "${SWAP_WARNING_THRESHOLD:-}" \
    "${SWAP_CRITICAL_THRESHOLD:-}" || valid=1

    return "$valid"
}
