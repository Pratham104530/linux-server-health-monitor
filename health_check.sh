
#!/bin/bash

# Linux Server Health Monitor
# Collects system health information, checks thresholds,
# and saves a timestamped report.

set -o pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="$PROJECT_DIR/reports"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
REPORT_FILE="$REPORT_DIR/health_report_$TIMESTAMP.txt"

DISK_THRESHOLD=80
MEMORY_THRESHOLD=80
OVERALL_STATUS=0

mkdir -p "$REPORT_DIR" || {
    echo "ERROR: Cannot create report directory: $REPORT_DIR" >&2
    exit 2
}

# Print output to the terminal and save it in the report.
exec > >(tee "$REPORT_FILE") 2>&1

echo "======================================"
echo "       LINUX SERVER HEALTH"
echo "======================================"
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo

# System uptime
echo "----- SYSTEM UPTIME -----"
uptime || OVERALL_STATUS=1
echo

# CPU load health check
echo "----- CPU LOAD HEALTH CHECK -----"

CPU_COUNT="$(nproc 2>/dev/null)"
LOAD_1MIN="$(awk '{print $1}' /proc/loadavg 2>/dev/null)"

if [[ "$CPU_COUNT" =~ ^[1-9][0-9]*$ ]] &&
   [[ "$LOAD_1MIN" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "CPU cores: $CPU_COUNT"
    echo "1-minute load: $LOAD_1MIN"

    if awk -v load="$LOAD_1MIN" -v cores="$CPU_COUNT" \
        'BEGIN { exit !(load > cores) }'; then
        echo "WARNING: Load exceeds CPU core count"
        OVERALL_STATUS=1
    else
        echo "OK: System load is within the basic threshold"
    fi
else
    echo "ERROR: Unable to read CPU load information"
    OVERALL_STATUS=1
fi
echo

# CPU information
echo "----- CPU INFORMATION -----"
lscpu | grep -E '^CPU\(s\):|^Model name:' ||
    echo "WARNING: CPU information could not be fully read"
echo

# Memory information and health check
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
        OVERALL_STATUS=1
    else
        echo "OK: Memory usage is ${MEMORY_USAGE}%"
    fi
else
    echo "ERROR: Unable to calculate memory usage"
    OVERALL_STATUS=1
fi
echo

# Disk information and health check
echo "----- DISK USAGE -----"

if ! df -hP -x tmpfs -x devtmpfs -x squashfs -x iso9660; then
    echo "ERROR: Unable to read disk usage"
    OVERALL_STATUS=1
fi
echo

echo "----- DISK HEALTH CHECK -----"

while read -r MOUNT USAGE; do
    [[ "$USAGE" =~ ^[0-9]+$ ]] || continue

    if (( USAGE >= DISK_THRESHOLD )); then
        echo "WARNING: $MOUNT disk usage is ${USAGE}%"
        OVERALL_STATUS=1
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

# Network interfaces
echo "----- NETWORK INTERFACES -----"
if ! ip -br addr; then
    echo "ERROR: Unable to read network interfaces"
    OVERALL_STATUS=1
fi
echo

# Listening ports
echo "----- LISTENING PORTS -----"
if ! ss -tuln; then
    echo "ERROR: Unable to inspect listening ports"
    OVERALL_STATUS=1
fi
echo

# Overall health summary
echo "======================================"
echo "           HEALTH SUMMARY"
echo "======================================"

if (( OVERALL_STATUS == 0 )); then
    echo "Overall: OK"
else
    echo "Overall: WARNING / ERROR"
fi

echo "Report: $REPORT_FILE"
echo "======================================"
echo "       HEALTH CHECK COMPLETE"
echo "======================================"

exit "$OVERALL_STATUS"

