#!/bin/bash

# Check failed SSH login attempts.
check_failed_ssh_logins() {
    echo "----- FAILED SSH LOGIN ATTEMPTS -----"

    local failed_logins

    failed_logins="$(
        journalctl -u ssh --since "24 hours ago" \
            --no-pager 2>/dev/null |
            grep -Ei 'failed password|invalid user|authentication failure' || true
    )"

    if [[ -n "$failed_logins" ]]; then
        printf '%s\n' "$failed_logins"
    else
        echo "No failed SSH login attempts found"
    fi

    echo
}

# Display recent system errors.
show_system_errors() {
    echo "----- RECENT SYSTEM ERRORS -----"

    journalctl -p err --since "24 hours ago" \
        --no-pager 2>/dev/null | tail -n 15

    echo
}

# Display network interface statistics.
show_network_diagnostics() {
    echo "----- NETWORK DIAGNOSTICS -----"

    ip -s link

    echo
}
