#!/bin/bash

# Monitors Defensive Software and Aggregates Firewall Rules
# Usage: ./recon.sh - to be run on its own without the use of wrapper

LOG_DIR="rt_logs"
SOFTWARE_LOG="$LOG_DIR/software_log.txt"
PROCESS_LOG="$LOG_DIR/process_log.txt"
FIREWALLD_LOG="$LOG_DIR/firewalld_rules_log.txt"
IPTABLES_LOG="$LOG_DIR/iptables_rules_log.txt"
DEFENSIVE_TOOLS=("wireshark" "tcpdump" "snort" "zeek" "ossec" "clamd" "firewalld" "auditd" "elk" 
                 "sysmon" "zabbix" "nagios" "ossec" "ufw" "openvas" "tripwire" "security onion" 
                 "aide" "cilium" "fail2ban" "nmap" "rkhunter" "basilisk")

# Setup the logging directory
mkdir -p "$LOG_DIR"

# Function to log installed software matching defensive tools list
log_installed_software() {
    echo "[%] Logging installed software..."
    > "$SOFTWARE_LOG"  # Clear log file if it exists
    echo "INSTALLED DEFENSIVE TOOLS:" >> "$SOFTWARE_LOG"

    for tool in "${DEFENSIVE_TOOLS[@]}"; do
        dpkg -l | grep -i "$tool" >> "$SOFTWARE_LOG"
    done
}

# Function to log running defensive processes using ps aux w/ grep
log_defensive_processes() {
    echo "[%] Logging running defensive processes..."
    > "$PROCESS_LOG"  # Clear log file if it exists
    echo "RUNNING PROCESSES UTILIZING DEFENSIVE TOOLS:" >> "$PROCESS_LOG"

    ps aux --no-heading | while read -r line; do
        for tool in "${DEFENSIVE_TOOLS[@]}"; do
            if echo "$line" | grep -iq "$tool"; then
                clean_line=$(echo "$line" | awk '{$3=""; $4=""; $5=""; $6=""; print $0}')
                current_time=$(date +"%H:%M:%S")
                echo "$current_time: $clean_line" >> "$PROCESS_LOG"
            fi
        done
    done
}

# Function to log firewalld rules
log_firewalld_rules() {
    echo "[%] Checking firewalld rules..."
    if systemctl is-active --quiet firewalld; then
        firewall-cmd --list-all > "$FIREWALLD_LOG"
        echo "[+] Firewalld rules logged."
    else
        echo "[!] Firewalld is not active."
    fi
}

# Function to log iptables rules
log_iptables_rules() {
    echo "[%] Checking iptables rules..."
    iptables-save > "$IPTABLES_LOG"
    echo "[+] Iptables rules logged."
}

# Main loop
while true; do
    echo "-> Running the main loop now..."
    echo ""
    log_installed_software
    log_defensive_processes
    log_firewalld_rules
    log_iptables_rules
    echo ""
    echo "-> Finished main loop, waiting for cooldown!"
    sleep 35  # Wait for cooldown before the next check
done
