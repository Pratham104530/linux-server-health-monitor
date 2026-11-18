# Linux Server Health Monitor

A modular Bash-based Linux server monitoring and diagnostics tool. It collects system health metrics, evaluates configurable thresholds, records timestamped logs and reports, and provides process, SSH, system and network diagnostics.

## Features

### Resource Monitoring
- System uptime and CPU core information
- CPU load average and utilization
- Memory and swap utilization
- Disk space and inode utilization

### Process Monitoring
- Top 5 CPU-consuming processes
- Top 5 memory-consuming processes

### System and Network Diagnostics
- SSH service status
- IPv4 connectivity and DNS checks
- Network interfaces and listening ports
- Failed SSH authentication event lookup
- Recent system journal errors
- Network packet, error and drop statistics

### Configuration and Reporting
- Centralized configuration in `config/monitor.conf`
- Configuration validation
- Configurable warning and critical thresholds
- Timestamped health reports
- Centralized application logging
- Overall health status and exit codes

## Project Structure

```text
linux-server-health-monitor/
├── config/
│   └── monitor.conf
├── lib/
│   ├── config_validation.sh
│   ├── cpu_health.sh
│   ├── disk_health.sh
│   ├── logging.sh
│   ├── memory_health.sh
│   ├── process_health.sh
│   ├── swap_health.sh
│   └── system_diagnostics.sh
├── tests/
│   ├── config_validation.bats
│   ├── disk_collection.bats
│   ├── disk_health.bats
│   ├── health_check.bats
│   ├── logging.bats
│   ├── memory_health.bats
│   └── swap_health.bats
├── reports/
├── logs/
├── health_check.sh
├── .gitignore
└── README.md
```

## Requirements

- Linux with Bash
- Standard Linux utilities: `awk`, `df`, `free`, `getent`, `grep`, `ip`, `lscpu`, `ping`, `ps`, `ss`, `systemctl`, `journalctl`
- Git

### Development Tools
- Bats for automated shell testing
- ShellCheck for static analysis

## Installation

```bash
git clone https://github.com/Pratham104530/linux-server-health-monitor.git
cd linux-server-health-monitor
chmod +x health_check.sh
```

## Configuration

Edit `config/monitor.conf` to adjust thresholds.

Supported threshold categories:
- CPU utilization
- Memory utilization
- Disk utilization
- Inode utilization
- Swap utilization
- CPU load

Warning and critical percentage thresholds are validated before monitoring begins. The warning threshold must be lower than the critical threshold.

Example:

```bash
CPU_WARNING_THRESHOLD=80
CPU_CRITICAL_THRESHOLD=95

MEMORY_WARNING_THRESHOLD=80
MEMORY_CRITICAL_THRESHOLD=95
```

See `config/monitor.conf` for the complete configuration.

## Usage

Run from the repository root:

```bash
./health_check.sh
```

The monitor displays results, generates a timestamped report in `reports/`, and appends execution events to `logs/monitor.log`.

Some system journal entries may require elevated privileges or suitable journal permissions.

## Health Status and Exit Codes

| Exit code | Status | Meaning |
|---:|---|---|
| 0 | OK | Checks are within configured limits |
| 1 | WARNING | A warning threshold was reached or a check could not be completed |
| 2 | CRITICAL | A critical resource threshold was reached |

Check the exit code:

```bash
echo $?
```

## Testing

Run automated tests:

```bash
bats tests/
```

Run syntax validation:

```bash
for file in health_check.sh lib/*.sh; do
    bash -n "$file" || exit 1
done
```

Run ShellCheck:

```bash
shellcheck -x health_check.sh lib/*.sh
```

## Generated Files

- Reports: `reports/`
- Application logs: `logs/monitor.log`

Both generated directories are excluded from Git.

## Current Project Scope

### Implemented
- Modular resource monitoring
- Configuration validation
- Timestamped reports and centralized logging
- CPU and memory process monitoring
- SSH, system journal and network diagnostics
- Automated Bats tests

### Planned
- Scheduled execution and report retention
- Alert notifications
- GitHub Actions CI
- Docker packaging
- Prometheus and Node Exporter
- Grafana dashboards and alerting

## Purpose

This project demonstrates practical Linux administration, Bash automation, modular scripting, system troubleshooting, configuration management, automated testing and Git-based development.
