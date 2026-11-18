#!/usr/bin/env bats

setup() {
    TEST_DIR="$(mktemp -d)"
    export HOME="$TEST_DIR"

    mkdir -p "$HOME/linux-server-health-monitor/reports"
    mkdir -p "$HOME/linux-server-health-monitor/logs"

    PROJECT_DIR="$HOME/linux-server-health-monitor"
    REPORT_DIR="$PROJECT_DIR/reports"
    LOG_DIR="$PROJECT_DIR/logs"

    cp "$BATS_TEST_DIRNAME/../cleanup.sh" "$PROJECT_DIR/cleanup.sh"
    chmod +x "$PROJECT_DIR/cleanup.sh"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "cleanup removes reports older than 7 days" {
    touch -d "10 days ago" "$REPORT_DIR/health_report_old.txt"

    run "$PROJECT_DIR/cleanup.sh"

    [ ! -f "$REPORT_DIR/health_report_old.txt" ]
}

@test "cleanup preserves recent reports" {
    touch "$REPORT_DIR/health_report_recent.txt"

    run "$PROJECT_DIR/cleanup.sh"

    [ -f "$REPORT_DIR/health_report_recent.txt" ]
}

@test "cleanup preserves active log files" {
    touch -d "40 days ago" "$LOG_DIR/cron.log"
    touch -d "40 days ago" "$LOG_DIR/monitor.log"

    run "$PROJECT_DIR/cleanup.sh"

    [ -f "$LOG_DIR/cron.log" ]
    [ -f "$LOG_DIR/monitor.log" ]
}

@test "cleanup removes rotated logs older than 30 days" {
    touch -d "40 days ago" "$LOG_DIR/monitor.log.1"

    run "$PROJECT_DIR/cleanup.sh"

    [ ! -f "$LOG_DIR/monitor.log.1" ]
}
