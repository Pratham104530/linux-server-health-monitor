#!/bin/bash

PROJECT_DIR="$HOME/linux-server-health-monitor"

cd "$PROJECT_DIR" || exit 1

./health_check.sh
