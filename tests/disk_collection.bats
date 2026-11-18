#!/usr/bin/env bats

setup() {
    PROJECT_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

    source "$PROJECT_DIR/lib/disk_health.sh"

    DISK_WARNING_THRESHOLD=80
    DISK_CRITICAL_THRESHOLD=95
    INODE_WARNING_THRESHOLD=80
    INODE_CRITICAL_THRESHOLD=95

    OVERALL_STATUS=0

    set_status() {
        local new_status="$1"
        if (( new_status > OVERALL_STATUS )); then
            OVERALL_STATUS="$new_status"
        fi
    }

    FAKE_BIN="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$FAKE_BIN"

    cat > "$FAKE_BIN/df" <<'EOF'
#!/bin/bash

if [[ "${FAKE_DF_FAIL:-0}" == "1" ]]; then
    echo "Simulated df failure" >&2
    exit 1
fi

if [[ " $* " == *" -iP "* ]]; then
    cat <<'DATA'
Filesystem Inodes IUsed IFree IUse% Mounted on
/dev/mock1 100000 17000 83000 17% /
/dev/mock2 100000 85000 15000 85% /data
DATA
else
    cat <<'DATA'
Filesystem 1024-blocks Used Available Capacity Mounted on
/dev/mock1 100000 66000 34000 66% /
/dev/mock2 100000 85000 15000 85% /data
/dev/mock3 100000 96000 4000 96% /backup
DATA
fi
EOF

    chmod +x "$FAKE_BIN/df"
    export PATH="$FAKE_BIN:$PATH"
}

@test "disk collection detects warning and critical filesystems" {
    check_disk_health > "$BATS_TEST_TMPDIR/output"

    grep -q "WARNING: /data disk usage is 85%" \
        "$BATS_TEST_TMPDIR/output"

    grep -q "CRITICAL: /backup disk usage is 96%" \
        "$BATS_TEST_TMPDIR/output"

    [ "$OVERALL_STATUS" -eq 2 ]
}

@test "inode collection detects warning filesystem" {
    check_inode_health > "$BATS_TEST_TMPDIR/output"

    grep -q "WARNING: /data inode usage is 85%" \
        "$BATS_TEST_TMPDIR/output"

    [ "$OVERALL_STATUS" -eq 1 ]
}

@test "disk collection handles df command failure" {
    export FAKE_DF_FAIL=1

    if check_disk_health > "$BATS_TEST_TMPDIR/output" 2>&1; then
        result=0
    else
        result=$?
    fi

    [ "$result" -eq 1 ]

    grep -q "ERROR: Unable to read disk usage" \
        "$BATS_TEST_TMPDIR/output"

    [ "$OVERALL_STATUS" -eq 1 ]
}

@test "inode collection handles df command failure" {
    export FAKE_DF_FAIL=1

    if check_inode_health > "$BATS_TEST_TMPDIR/output" 2>&1; then
        result=0
    else
        result=$?
    fi

    [ "$result" -eq 1 ]

    grep -q "ERROR: Unable to read inode usage" \
        "$BATS_TEST_TMPDIR/output"

    [ "$OVERALL_STATUS" -eq 1 ]
}

