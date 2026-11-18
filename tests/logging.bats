
#!/usr/bin/env bats

setup() {
    PROJECT_DIR="$BATS_TEST_TMPDIR/project"
    mkdir -p "$PROJECT_DIR"

    source "$BATS_TEST_DIRNAME/../lib/logging.sh"
}

@test "INFO log entry is written successfully" {
    run write_log INFO "Monitoring started"

    [ "$status" -eq 0 ]
    grep -q '\[INFO\] Monitoring started' \
        "$PROJECT_DIR/logs/monitor.log"
}

@test "WARNING log entry is written successfully" {
    run write_log WARNING "CPU usage elevated"

    [ "$status" -eq 0 ]
    grep -q '\[WARNING\] CPU usage elevated' \
        "$PROJECT_DIR/logs/monitor.log"
}

@test "ERROR log entry is written successfully" {
    run write_log ERROR "DNS resolution failed"

    [ "$status" -eq 0 ]
    grep -q '\[ERROR\] DNS resolution failed' \
        "$PROJECT_DIR/logs/monitor.log"
}

@test "CRITICAL log entry is written successfully" {
    run write_log CRITICAL "Disk usage critical"

    [ "$status" -eq 0 ]
    grep -q '\[CRITICAL\] Disk usage critical' \
        "$PROJECT_DIR/logs/monitor.log"
}

@test "invalid log level is rejected" {
    run write_log INVALID "Invalid message"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid log level"* ]]
}

@test "multiple log entries are appended" {
    write_log INFO "First entry"
    write_log WARNING "Second entry"

    [ "$(wc -l < "$PROJECT_DIR/logs/monitor.log")" -eq 2 ]
}

@test "log entries contain valid timestamps" {
    write_log INFO "Timestamp test"

    grep -Eq \
        '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] \[INFO\]' \
        "$PROJECT_DIR/logs/monitor.log"
}

@test "missing project directory is rejected" {
    PROJECT_DIR=""

    run write_log INFO "Should fail"

    [ "$status" -eq 1 ]
    [[ "$output" == *"PROJECT_DIR is not set"* ]]
}

