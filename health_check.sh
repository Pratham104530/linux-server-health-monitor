#!/bin/bash

# Linux Server Health Monitor
# Checks CPU load, memory, disk, SSH, network and DNS.
# Saves a timestamped report and returns an exit status.

set -o pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROJECT_DIR/lib/cpu_health.sh"
source "$PROJECT_DIR/lib/memory_health.sh"
source "$PROJECT_DIR/lib/process_health.sh"
source "$PROJECT_DIR/lib/disk_health.sh"
source "$PROJECT_DIR/lib/logging.sh"
source "$PROJECT_DIR/lib/alerting.sh"
source "$PROJECT_DIR/lib/swap_health.sh"
source "$PROJECT_DIR/lib/system_diagnostics.sh"

set -o pipefail
write_log INFO "Monitoring system started"

# Load monitoring configuration
CONFIG_FILE="$PROJECT_DIR/config/monitor.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE" >&2
    exit 1
fi

# shellcheck source=config/monitor.conf
source "$CONFIG_FILE"

# Load configuration validation module
source "$PROJECT_DIR/lib/config_validation.sh"

# Validate configuration before starting monitoring
if ! validate_monitor_config; then
    write_log ERROR "Invalid monitoring configuration"
    echo "ERROR: Invalid monitoring configuration. Exiting." >&2
    exit 1
fi

REPORT_DIR="$PROJECT_DIR/reports"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
REPORT_FILE="$REPORT_DIR/health_report_$TIMESTAMP.txt"



OVERALL_STATUS=0
set_status() {
    local new_status="$1"

    if (( new_status > OVERALL_STATUS )); then
        OVERALL_STATUS="$new_status"
    fi
}
get_cpu_usage() {
    local total1 idle1 total2 idle2

    read -r total1 idle1 < <(
        awk '/^cpu / {
            idle = $5 + $6
            total = 0

            for (i = 2; i <= 9; i++)
                total += $i

            print total, idle
        }' /proc/stat
    )

    sleep 1

    read -r total2 idle2 < <(
        awk '/^cpu / {
            idle = $5 + $6
            total = 0

            for (i = 2; i <= 9; i++)
                total += $i

            print total, idle
        }' /proc/stat
    )

    awk -v t1="$total1" -v i1="$idle1" \
        -v t2="$total2" -v i2="$idle2" '
        BEGIN {
            total_diff = t2 - t1
            idle_diff = i2 - i1

            if (total_diff <= 0 || idle_diff < 0)
                exit 1

            printf "%.2f", (total_diff - idle_diff) / total_diff * 100
        }
    '
}
mkdir -p "$REPORT_DIR" || {
    echo "ERROR: Cannot create report directory: $REPORT_DIR" >&2
    exit 2
}

# Save output to both terminal and report.
exec > >(tee "$REPORT_FILE") 2>&1

echo "======================================"
echo "       LINUX SERVER HEALTH"
echo "======================================"
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo

# System uptime
echo "----- SYSTEM UPTIME -----"
uptime || set_status 1
echo

# CPU load check
echo "----- CPU LOAD HEALTH CHECK -----"

CPU_COUNT="$(nproc 2>/dev/null)"
LOAD_1MIN="$(awk '{print $1}' /proc/loadavg 2>/dev/null)"

if [[ "$CPU_COUNT" =~ ^[1-9][0-9]*$ ]] &&
   [[ "$LOAD_1MIN" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "CPU cores: $CPU_COUNT"
    echo "1-minute load: $LOAD_1MIN"

    if awk -v load="$LOAD_1MIN" -v cores="$CPU_COUNT" \
        -v threshold="$CPU_LOAD_THRESHOLD" \
        'BEGIN { exit !(load > cores * threshold) }'; then
        echo "WARNING: Load exceeds the configured threshold"
        set_status 1
    else
        echo "OK: System load is within the basic threshold"
    fi
else
    echo "ERROR: Unable to read CPU load information"
    set_status 1
fi
echo

# Actual CPU utilization check
echo "----- CPU UTILIZATION HEALTH CHECK -----"

if CPU_USAGE="$(get_cpu_usage)" &&
   [[ "$CPU_USAGE" =~ ^[0-9]+([.][0-9]+)?$ ]]; then

    echo "CPU utilization: ${CPU_USAGE}%"

    CPU_STATUS="$(classify_cpu_usage \
        "$CPU_USAGE" \
        "$CPU_WARNING_THRESHOLD" \
        "$CPU_CRITICAL_THRESHOLD")"

    case "$CPU_STATUS" in
        OK)
            echo "OK: CPU utilization is within normal limits"
            ;;
        WARNING)
            echo "WARNING: CPU utilization is elevated"
            set_status 1
            ;;
        CRITICAL)
            echo "CRITICAL: CPU utilization is high"
            set_status 2
            ;;
        *)
            echo "ERROR: Unable to classify CPU utilization"
            set_status 1
            ;;
    esac

else
    echo "ERROR: Unable to calculate CPU utilization"
    set_status 1
fi

echo

# Memory check
echo "----- MEMORY USAGE -----"
free -h
echo

# Memory health check
echo "----- MEMORY HEALTH CHECK -----"

if MEMORY_USAGE="$(get_memory_usage)" &&
   [[ "$MEMORY_USAGE" =~ ^[0-9]+([.][0-9]+)?$ ]]; then

    echo "Memory utilization: ${MEMORY_USAGE}%"

    MEMORY_STATUS="$(classify_memory_usage \
        "$MEMORY_USAGE" \
        "$MEMORY_WARNING_THRESHOLD" \
        "$MEMORY_CRITICAL_THRESHOLD")"

    case "$MEMORY_STATUS" in
        OK)
            echo "OK: Memory usage is within normal limits"
            ;;
        WARNING)
            echo "WARNING: Memory usage is elevated"
            set_status 1
            ;;
        CRITICAL)
            echo "CRITICAL: Memory usage is high"
            set_status 2
            ;;
        *)
            echo "ERROR: Unable to classify memory usage"
            set_status 1
            ;;
    esac

else
    echo "ERROR: Unable to calculate memory usage"
    set_status 1
fi

echo

# Swap health check
echo "----- SWAP HEALTH CHECK -----"

if ! SWAP_USAGE="$(get_swap_usage)"; then
    echo "ERROR: Unable to calculate swap usage"
    set_status 1
else
    echo "Swap utilization: ${SWAP_USAGE}%"

    SWAP_STATUS="$(classify_swap_usage \
        "$SWAP_USAGE" \
        "$SWAP_WARNING_THRESHOLD" \
        "$SWAP_CRITICAL_THRESHOLD")"

    case "$SWAP_STATUS" in
        OK)
            echo "OK: Swap usage is within normal limits"
            ;;
        WARNING)
            echo "WARNING: Swap usage is elevated"
            set_status 1
            ;;
        CRITICAL)
            echo "CRITICAL: Swap usage is critically high"
            set_status 2
            ;;
        *)
            echo "ERROR: Unable to classify swap usage"
            set_status 1
            ;;
    esac
fi



# Disk-space and inode health checks
check_disk_health
echo

check_inode_health
echo

# SSH service check
echo "----- SSH SERVICE CHECK -----"

if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet ssh; then
        echo "OK: SSH service is active"
    else
        echo "WARNING: SSH service is not active"
        set_status 1
    fi
else
    echo "ERROR: systemctl is unavailable"
    set_status 1
fi
echo

# Network connectivity check
echo "----- NETWORK CONNECTIVITY -----"

if command -v ping >/dev/null 2>&1 &&
   ping -4 -c 3 -W 2 8.8.8.8; then
    echo "OK: IPv4 connectivity check passed"
else
    echo "WARNING: IPv4 connectivity check failed"
    set_status 1
fi
echo

# DNS resolution check
echo "----- DNS RESOLUTION -----"

if command -v getent >/dev/null 2>&1 &&
   getent ahosts example.com; then
    echo "OK: DNS resolution succeeded"
else
    echo "WARNING: DNS resolution failed"
    set_status 1
fi
echo

# Network interfaces
echo "----- NETWORK INTERFACES -----"

if ! ip -br addr; then
    echo "ERROR: Unable to read network interfaces"
    set_status 1
fi
echo

# Listening ports
echo "----- LISTENING PORTS -----"

if ! ss -tuln; then
    echo "ERROR: Unable to inspect listening ports"
    set_status 1
fi
echo

# Top process monitoring
show_top_cpu_processes

show_top_memory_processes

# System and network diagnostics
check_failed_ssh_logins

show_system_errors

show_network_diagnostics

# Overall health summary
echo "======================================"
echo "           HEALTH SUMMARY"
echo "======================================"

case "$OVERALL_STATUS" in
    0)
        echo "Overall: OK"
        ;;
    1)
        echo "Overall: WARNING"
        ;;
    2)
        echo "Overall: CRITICAL"
        ;;
    *)
        echo "Overall: ERROR"
        OVERALL_STATUS=3
        ;;
esac

# Generate alerts for warning and critical conditions.
case "$OVERALL_STATUS" in
    1)
        send_alert WARNING "Monitoring detected warning conditions. Report: $REPORT_FILE"
        ;;
    2)
        send_alert CRITICAL "Monitoring detected critical conditions. Report: $REPORT_FILE"
        ;;
esac

echo "Report: $REPORT_FILE"
echo "======================================"
echo "       HEALTH CHECK COMPLETE"
echo "======================================"

# Record final monitoring status in the log
case "$OVERALL_STATUS" in
    0)
        write_log INFO "Monitoring completed: Overall status OK"
        ;;
    1)
        write_log WARNING "Monitoring completed: Overall status WARNING"
        ;;
    2)
        write_log CRITICAL "Monitoring completed: Overall status CRITICAL"
        ;;
    *)
        write_log ERROR "Monitoring completed: Overall status ERROR"
        ;;
esac

exit "$OVERALL_STATUS"
