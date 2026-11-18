#!/usr/bin/env bats

setup() {
    PROJECT_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

    source "$PROJECT_DIR/lib/config_validation.sh"
    source "$PROJECT_DIR/config/monitor.conf"
}

@test "valid configuration passes validation" {
    run validate_monitor_config

    [ "$status" -eq 0 ]
}

@test "non-numeric CPU load threshold is rejected" {
    CPU_LOAD_THRESHOLD="invalid"

    run validate_monitor_config

    [ "$status" -eq 1 ]
    [[ "$output" == *"CPU_LOAD_THRESHOLD must be numeric"* ]]
}

@test "percentage above 100 is rejected" {
    MEMORY_WARNING_THRESHOLD=110

    run validate_monitor_config

    [ "$status" -eq 1 ]
    [[ "$output" == *"MEMORY_WARNING_THRESHOLD must be between 0 and 100"* ]]
}

@test "warning threshold greater than critical is rejected" {
    CPU_WARNING_THRESHOLD=95
    CPU_CRITICAL_THRESHOLD=80

    run validate_monitor_config

    [ "$status" -eq 1 ]
    [[ "$output" == *"CPU warning threshold must be lower than critical threshold"* ]]
}

@test "equal warning and critical thresholds are rejected" {
    DISK_WARNING_THRESHOLD=90
    DISK_CRITICAL_THRESHOLD=90

    run validate_monitor_config

    [ "$status" -eq 1 ]
    [[ "$output" == *"DISK warning threshold must be lower than critical threshold"* ]]
}

@test "missing inode threshold is rejected" {
    unset INODE_CRITICAL_THRESHOLD

    run validate_monitor_config

    [ "$status" -eq 1 ]
    [[ "$output" == *"INODE_CRITICAL_THRESHOLD must be numeric"* ]]
}
