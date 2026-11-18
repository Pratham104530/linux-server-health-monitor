#!/usr/bin/env bats

setup() {
    PROJECT_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$PROJECT_DIR/lib/memory_health.sh"
}

@test "memory usage below warning threshold returns OK" {
    run classify_memory_usage 50 80 95
    [ "$status" -eq 0 ]
    [ "$output" = "OK" ]
}

@test "memory usage at warning threshold returns WARNING" {
    run classify_memory_usage 80 80 95
    [ "$status" -eq 0 ]
    [ "$output" = "WARNING" ]
}

@test "memory usage at critical threshold returns CRITICAL" {
    run classify_memory_usage 95 80 95
    [ "$status" -eq 0 ]
    [ "$output" = "CRITICAL" ]
}

@test "invalid memory usage returns error code 2" {
    run classify_memory_usage invalid 80 95
    [ "$status" -eq 2 ]
}

@test "memory usage calculation returns a valid percentage" {
    run get_memory_usage
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

@test "memory usage calculation does not exceed 100 percent" {
    run get_memory_usage
    [ "$status" -eq 0 ]
    awk -v usage="$output" 'BEGIN { exit !(usage >= 0 && usage <= 100) }'
}
