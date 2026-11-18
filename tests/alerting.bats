#!/usr/bin/env bats

setup() {
    TEST_DIR="$(mktemp -d)"
    export PROJECT_DIR="$TEST_DIR/project"
    mkdir -p "$PROJECT_DIR/logs"

    source "$BATS_TEST_DIRNAME/../lib/alerting.sh"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "writes a WARNING alert" {
    run send_alert WARNING "CPU usage is high"

    [ "$status" -eq 0 ]
    [ -f "$PROJECT_DIR/logs/alerts.log" ]
    grep -q '\[WARNING\] CPU usage is high' "$PROJECT_DIR/logs/alerts.log"
}

@test "writes a CRITICAL alert" {
    run send_alert CRITICAL "Disk usage is critical"

    [ "$status" -eq 0 ]
    grep -q '\[CRITICAL\] Disk usage is critical' "$PROJECT_DIR/logs/alerts.log"
}

@test "rejects invalid alert severity" {
    run send_alert INFO "Test message"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid alert level"* ]]
}

@test "rejects empty PROJECT_DIR" {
    PROJECT_DIR=""

    run send_alert WARNING "Test message"

    [ "$status" -eq 1 ]
    [[ "$output" == *"PROJECT_DIR is not set"* ]]

}
@test "WARNING status generates a warning alert" {
    OVERALL_STATUS=1

    case "$OVERALL_STATUS" in
        1) run send_alert WARNING "Integration warning test" ;;
        2) run send_alert CRITICAL "Integration critical test" ;;
    esac

    [ "$status" -eq 0 ]
    grep -q '\[WARNING\] Integration warning test' \
        "$PROJECT_DIR/logs/alerts.log"
}

@test "CRITICAL status generates a critical alert" {
    OVERALL_STATUS=2

    case "$OVERALL_STATUS" in
        1) run send_alert WARNING "Integration warning test" ;;
        2) run send_alert CRITICAL "Integration critical test" ;;
    esac

    [ "$status" -eq 0 ]
    grep -q '\[CRITICAL\] Integration critical test' \
        "$PROJECT_DIR/logs/alerts.log"
}
