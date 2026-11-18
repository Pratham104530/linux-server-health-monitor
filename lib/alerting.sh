#!/bin/bash

# Write a timestamped warning or critical alert.
send_alert() {
    local level="$1"
    local message="$2"

    local alert_dir="${PROJECT_DIR}/logs"
    local alert_file="$alert_dir/alerts.log"
    local timestamp

    # Validate alert severity.
    case "$level" in
        WARNING|CRITICAL)
            ;;
        *)
            echo "ERROR: Invalid alert level: $level" >&2
            return 1
            ;;
    esac

    # Validate project directory.
    if [[ -z "$PROJECT_DIR" ]]; then
        echo "ERROR: PROJECT_DIR is not set" >&2
        return 1
    fi

    # Create alert directory if required.
    if ! mkdir -p "$alert_dir"; then
        echo "ERROR: Unable to create alert directory" >&2
        return 1
    fi

    timestamp="$(date '+%Y-%m-%d %H:%M:%S')" || {
        echo "ERROR: Unable to generate timestamp" >&2
        return 1
    }

    # Append alert entry.
    if ! printf '[%s] [%s] %s\n' \
        "$timestamp" "$level" "$message" >> "$alert_file"; then
        echo "ERROR: Unable to write alert" >&2
        return 1
    fi
}
