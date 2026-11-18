#!/usr/bin/env bats

setup() {
    PROJECT_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$PROJECT_DIR/lib/swap_health.sh"
}

@test "swap usage below warning threshold returns OK" {
    run classify_swap_usage 50 80 95
    [ "$status" -eq 0 ]
    [ "$output" = "OK" ]
}

@test "swap usage at warning threshold returns WARNING" {
    run classify_swap_usage 80 80 95
    [ "$status" -eq 0 ]
    [ "$output" = "WARNING" ]
}

@test "swap usage at critical threshold returns CRITICAL" {
    run classify_swap_usage 95 80 95
    [ "$status" -eq 0 ]
    [ "$output" = "CRITICAL" ]
}

@test "invalid swap usage returns error code 2" {
    run classify_swap_usage invalid 80 95
    [ "$status" -eq 2 ]
}

@test "swap usage calculation returns a valid percentage" {
    run get_swap_usage
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

@test "swap usage calculation stays between 0 and 100" {
    run get_swap_usage
    [ "$status" -eq 0 ]
    awk -v usage="$output" 'BEGIN {
        exit !(usage >= 0 && usage <= 100)
    }'
}

