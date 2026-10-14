
#!/bin/bash

# Linux Server Health Monitor
# Checks CPU load, memory, disk, SSH, network and DNS.
# Saves a timestamped report and returns an exit status.

set -o pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="$PROJECT_DIR/reports"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
REPORT_FILE="$REPORT_DIR/health_report_$TIMESTAMP.txt"

CPU_LOAD_THRESHOLD=1
MEMORY_THRESHOLD=80
DISK_THRESHOLD=80
OVERALL_STATUS=0
set_status() {
    local new_status="$1"

    if (( new_status > OVERALL_STATUS )); then
        OVERALL_STATUS="$new_status"
    fi
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

# CPU information
echo "----- CPU INFORMATION -----"
if ! lscpu | grep -E '^CPU\(s\):|^Model name:'; then
    echo "WARNING: CPU details could not be read"
    set_status 1
fi
echo

# Memory check
echo "----- MEMORY USAGE -----"
free -h
echo

echo "----- MEMORY HEALTH CHECK -----"

TOTAL_MEM="$(free -b | awk '/^Mem:/ {print $2}')"
AVAILABLE_MEM="$(free -b | awk '/^Mem:/ {print $7}')"

if [[ "$TOTAL_MEM" =~ ^[0-9]+$ ]] &&
   [[ "$AVAILABLE_MEM" =~ ^[0-9]+$ ]] &&
   (( TOTAL_MEM > 0 && AVAILABLE_MEM <= TOTAL_MEM )); then

    USED_MEM=$((TOTAL_MEM - AVAILABLE_MEM))
    MEMORY_USAGE=$((USED_MEM * 100 / TOTAL_MEM))

    echo "Memory usage: ${MEMORY_USAGE}%"

    if (( MEMORY_USAGE >= MEMORY_THRESHOLD )); then
        echo "WARNING: Memory usage is ${MEMORY_USAGE}%"
        set_status 1
    else
        echo "OK: Memory usage is ${MEMORY_USAGE}%"
    fi
else
    echo "ERROR: Unable to calculate memory usage"
    set_status 1
fi
echo

# Disk check
echo "----- DISK USAGE -----"

if ! df -hP -x tmpfs -x devtmpfs -x squashfs -x iso9660; then
    echo "ERROR: Unable to read disk usage"
    set_status 1
fi
echo




# Disk health check with severity levels
echo "----- DISK HEALTH CHECK -----"

while read -r MOUNT USAGE; do
    [[ "$USAGE" =~ ^[0-9]+$ ]] || continue

    if (( USAGE >= 95 )); then
        echo "CRITICAL: $MOUNT disk usage is ${USAGE}%"
        set_status 2
    elif (( USAGE >= DISK_THRESHOLD )); then
        echo "WARNING: $MOUNT disk usage is ${USAGE}%"
      
            set_status 1
        
    else
        echo "OK: $MOUNT disk usage is ${USAGE}%"
    fi
done < <(
    df -hP -x tmpfs -x devtmpfs -x squashfs -x iso9660 |
    awk 'NR > 1 {
        usage = $5
        gsub(/%/, "", usage)
        print $6, usage
    }'
)
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

echo "Report: $REPORT_FILE"
echo "======================================"
echo "       HEALTH CHECK COMPLETE"
echo "======================================"

exit "$OVERALL_STATUS"
