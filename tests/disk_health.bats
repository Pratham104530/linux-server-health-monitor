#!/usr/bin/env bats

setup() {
    PROJECT_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$PROJECT_DIR/lib/disk_health.sh"
}

@test "disk usage below warning threshold returns OK" {
    run classify_disk_usage 66 80 95
    [ "$status" -eq 0 ]
    [ "$output" = "OK" ]
}

@test "disk usage at warning threshold returns WARNING" {
    run classify_disk_usage 80 80 95
    [ "$status" -eq 0 ]
    [ "$output" = "WARNING" ]
}

@test "disk usage at critical threshold returns CRITICAL" {
    run classify_disk_usage 95 80 95
    [ "$status" -eq 0 ]
    [ "$output" = "CRITICAL" ]
}

@test "invalid disk usage returns error code 2" {
    run classify_disk_usage invalid 80 95
    [ "$status" -eq 2 ]
}

@test "inode usage below warning threshold returns OK" {
    run classify_inode_usage 17 80 95
    [ "$status" -eq 0 ]
    [ "$output" = "OK" ]
}

@test "inode usage at warning threshold returns WARNING" {
    run classify_inode_usage 80 80 95
    [ "$status" -eq 0 ]
    [ "$output" = "WARNING" ]
}

@test "inode usage at critical threshold returns CRITICAL" {
    run classify_inode_usage 95 80 95
    [ "$status" -eq 0 ]
    [ "$output" = "CRITICAL" ]
}

@test "invalid inode usage returns error code 2" {
    run classify_inode_usage invalid 80 95
    [ "$status" -eq 2 ]
}
