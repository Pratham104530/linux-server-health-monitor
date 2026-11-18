#!/bin/bash

# Write a timestamped log entry.
write_log() {
    local level="$1"
    local message="$2"

    local log_dir="${PROJECT_DIR}/logs"
    local log_file="$log_dir/monitor.log"
    local timestamp

    # Validate log severity.
    case "$level" in
        INFO|WARNING|ERROR|CRITICAL)
            ;;
        *)
            echo "ERROR: Invalid log level: $level" >&2
            return 1
            ;;
    esac

    # Validate project directory.
    if [[ -z "$PROJECT_DIR" ]]; then
        echo "ERROR: PROJECT_DIR is not set" >&2
        return 1
    fi

    # Create log directory if required.
    if ! mkdir -p "$log_dir"; then
        echo "ERROR: Unable to create log directory" >&2
        return 1
    fi

    timestamp="$(date '+%Y-%m-%d %H:%M:%S')" || {
        echo "ERROR: Unable to generate timestamp" >&2
        return 1
    }

    # Append the log entry.
    if ! printf '[%s] [%s] %s\n' \
        "$timestamp" "$level" "$message" >> "$log_file"; then
        echo "ERROR: Unable to write to log file" >&2
        return 1
    fi
}

