
#!/usr/bin/env bats

setup() {
    PROJECT_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "monitor exits with a recognized health status" {
    run "$PROJECT_DIR/health_check.sh"

    [ "$status" -le 2 ]
}

@test "monitor displays CPU utilization check" {
    run "$PROJECT_DIR/health_check.sh"

    [[ "$output" == *"CPU UTILIZATION HEALTH CHECK"* ]]
}

@test "monitor generates a health report" {
    run "$PROJECT_DIR/health_check.sh"

    report_path="$(printf '%s\n' "$output" |
        sed -n 's/^Report: //p' | tail -n 1)"

    [ -n "$report_path" ]
    [ -f "$report_path" ]
}
@test "CPU usage below warning threshold returns OK" {
    run bash -c 'source "$1"; classify_cpu_usage 50 80 95' _ \
        "$PROJECT_DIR/lib/cpu_health.sh"

    [ "$status" -eq 0 ]
    [ "$output" = "OK" ]
}

@test "CPU usage at warning threshold returns WARNING" {
    run bash -c 'source "$1"; classify_cpu_usage 80 80 95' _ \
        "$PROJECT_DIR/lib/cpu_health.sh"

    [ "$status" -eq 0 ]
    [ "$output" = "WARNING" ]
}

@test "CPU usage at critical threshold returns CRITICAL" {
    run bash -c 'source "$1"; classify_cpu_usage 95 80 95' _ \
        "$PROJECT_DIR/lib/cpu_health.sh"

    [ "$status" -eq 0 ]
    [ "$output" = "CRITICAL" ]
}
