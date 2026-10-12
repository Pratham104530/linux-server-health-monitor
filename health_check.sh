#!/bin/bash

# Linux Server Health Monitor
# Collects system health information and saves a report.

set -o pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="$PROJECT_DIR/reports"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
REPORT_FILE="$REPORT_DIR/health_report_$TIMESTAMP.txt"

mkdir -p "$REPORT_DIR" || exit 1

{
    echo "=================================="
    echo "      LINUX SERVER HEALTH"
    echo "=================================="
    echo "Hostname: $(hostname)"
    echo "Date: $(date)"
    echo

    echo "----- SYSTEM UPTIME -----"
    uptime
    echo

    echo "----- CPU LOAD HEALTH CHECK -----"

CPU_COUNT=$(nproc)
LOAD_1MIN=$(awk '{print $1}' /proc/loadavg)

echo "CPU cores: $CPU_COUNT"
echo "1-minute load: $LOAD_1MIN"

if awk -v load="$LOAD_1MIN" -v cores="$CPU_COUNT" \
    'BEGIN { exit !(load > cores) }'; then
    echo "WARNING: System load is higher than CPU core count"
else
    echo "OK: System load is within the basic threshold"
fi
echo

    echo "----- CPU INFORMATION -----"
    lscpu | grep -E '^CPU\(s\):|^Model name:'
    echo

    echo "----- MEMORY USAGE -----"
    free -h
    echo

echo "----- MEMORY HEALTH CHECK -----"
MEMORY_THRESHOLD=80

TOTAL_MEM=$(free -b | awk '/^Mem:/ {print $2}')
AVAILABLE_MEM=$(free -b | awk '/^Mem:/ {print $7}')

if [ "$TOTAL_MEM" -gt 0 ]; then
    USED_MEM=$((TOTAL_MEM - AVAILABLE_MEM))
    MEMORY_USAGE=$((USED_MEM * 100 / TOTAL_MEM))

    if [ "$MEMORY_USAGE" -ge "$MEMORY_THRESHOLD" ]; then
        echo "WARNING: Memory usage is ${MEMORY_USAGE}%"
    else
        echo "OK: Memory usage is ${MEMORY_USAGE}%"
    fi
else
    echo "ERROR: Unable to read total memory"
fi
echo

    echo "----- DISK USAGE -----"
df -hP -x tmpfs -x devtmpfs -x squashfs -x iso9660
echo

echo "----- DISK HEALTH CHECK -----"
THRESHOLD=80

df -hP -x tmpfs -x devtmpfs -x squashfs -x iso9660 |
awk 'NR > 1 {
    usage = $5
    gsub(/%/, "", usage)
    print $6, usage
}' |
while read -r mount usage; do
    if [ "$usage" -ge "$THRESHOLD" ]; then
        echo "WARNING: $mount disk usage is ${usage}%"
    else
        echo "OK: $mount disk usage is ${usage}%"
    fi
done
echo    

    echo "----- NETWORK INTERFACES -----"
    ip -br addr
    echo

    echo "----- LISTENING PORTS -----"
    ss -tuln
    echo

    echo "=================================="
    echo "       HEALTH CHECK COMPLETE"
    echo "=================================="
} | tee "$REPORT_FILE"

echo
echo "Report saved to: $REPORT_FILE"
