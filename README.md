# Linux Server Health Monitor

A Bash-based DevOps project that collects basic Linux server
health information for system monitoring and troubleshooting.

## Features

- Hostname and current date/time
- System uptime
- CPU information
- Memory usage
- Disk usage
- Network interfaces and IP addresses
- Listening TCP and UDP ports
- Timestamped health reports

## Technologies

- Linux
- Bash scripting
- Git
- GitHub

## Project Structure

linux-server-health-monitor/
├── health_check.sh
├── README.md
├── .gitignore
└── reports/

## Requirements

- Linux system
- Bash
- Standard Linux utilities: uptime, lscpu, free, df, ip, ss

## Usage

Clone the repository or download the project.

Make the script executable:

    chmod +x health_check.sh

Run the health check:

    ./health_check.sh

The script prints the system information and saves a timestamped
report in the reports/ directory.

Generated reports are excluded from Git using .gitignore.

## Purpose

This project demonstrates basic Linux administration,
Bash scripting, network inspection, and Git workflow skills.
