#!/bin/bash

# Monitors Defensive Software and Aggregates Firewall Rules
# Usage: ./recon.sh

LOG_DIR="recon_logs"
SOFTWARE_LOG="$LOG_DIR/software_log.txt"
PROCESS_LOG="$LOG_DIR/process_log.txt"
FIREWALLD_LOG="$LOG_DIR/firewalld_rules_log.txt"
IPTABLES_LOG="$LOG_DIR/iptables_rules_log.txt"
DEFENSIVE_TOOLS=("wireshark" "tcpdump" "snort" "zeek" "ossec" "clamd" "firewalld" "auditd" "elk" 
                 "sysmon" "zabbix" "nagios" "ossec" "ufw" "openvas" "tripwire" "security onion" 
                 "aide" "cilium" "fail2ban" "nmap" "rkhunter" "basilisk")

# Check if the target IP was provided
if [ -z "$1" ]; then
    echo "Error: No target IP provided."
    exit 1
fi

# Target machine details
TARGET_USER="$(whoami)"       # Replace with the username on the target machine
TARGET_IP="$1"                # Replace with the IP address of the target machine
TARGET_DIR="/path/to/target/directory" # Replace with the directory on the target machine

# Setup the logging directory
mkdir -p "$LOG_DIR"

# Function to log installed software matching defensive tools list
log_installed_software() {
    # Clear the log file if it exists
    > "$SOFTWARE_LOG"

    echo "INSTALLED DEFENSIVE TOOLS:" >> "$SOFTWARE_LOG"

    for tool in "${DEFENSIVE_TOOLS[@]}"; do
        # Check if the software is installed via dpkg
        dpkg -l | grep -i "$tool" >> "$SOFTWARE_LOG"
    done
}

# Function to log running defensive processes using ps aux w/ grep
log_defensive_processes() {
    # Clear the file if it exists
    > "$PROCESS_LOG"

    echo "RUNNING PROCESSES UTILIZING DEFENSIVE TOOLS:" >> "$PROCESS_LOG"

    # Get the list of running processes
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
    echo "[*] Checking firewalld rules..."
    if systemctl is-active --quiet firewalld; then
        firewall-cmd --list-all > "$FIREWALLD_LOG"
        echo "[+] Firewalld rules logged."
    else
        echo "[-] Firewalld is not active."
    fi
}

# Function to log iptables rules
log_iptables_rules() {
    echo "[*] Checking iptables rules..."
    iptables-save > "$IPTABLES_LOG"
    echo "[+] Iptables rules logged."
}

# Main loop
while true; do
    echo "~~Running the main loop now..."
    echo ""
    log_installed_software
    log_defensive_processes
    log_firewalld_rules
    log_iptables_rules
    echo ""
    echo "~~Finished main loop, waiting for cooldown!!"
    sleep 35  # Wait for 10 minutes before the next check
done

# Create target directory on remote machine if it doesn’t exist, then send logs
ssh "$TARGET_USER@$TARGET_IP" "mkdir -p '$TARGET_DIR'"
scp "$SOFTWARE_LOG" "$PROCESS_LOG" "$FIREWALL_LOG" "$TARGET_USER@$TARGET_IP:$TARGET_DIR" > /dev/null 2>&1
