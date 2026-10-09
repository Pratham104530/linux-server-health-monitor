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

    echo "----- CPU INFORMATION -----"
    lscpu | grep -E '^CPU\(s\):|^Model name:'
    echo

    echo "----- MEMORY USAGE -----"
    free -h
    echo

    echo "----- DISK USAGE -----"
    df -h
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
