#!/bin/bash

# Linux Server Health Monitor - Retention Cleanup

PROJECT_DIR="$HOME/linux-server-health-monitor"
REPORT_DIR="$PROJECT_DIR/reports"
LOG_DIR="$PROJECT_DIR/logs"

# Delete health reports older than 7 days
find "$REPORT_DIR" -maxdepth 1 -type f \
    -name 'health_report_*.txt' -mtime +7 -print -delete

# Delete rotated log files older than 30 days
find "$LOG_DIR" -maxdepth 1 -type f \
    -name '*.log.*' -mtime +30 -print -delete

echo "Cleanup completed: $(date)"
