#!/bin/bash

# Display top 5 CPU-consuming processes.
show_top_cpu_processes() {
    echo "----- TOP 5 CPU-CONSUMING PROCESSES -----"

    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6

    echo
}

# Display top 5 memory-consuming processes.
show_top_memory_processes() {
    echo "----- TOP 5 MEMORY-CONSUMING PROCESSES -----"

    ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -n 6

    echo
}
