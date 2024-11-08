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
TARGET_USER="cdo"                      # Username on the target machine
TARGET_IP="$1"                         # IP address of the target machine
TARGET_DIR="/home/cdo/test/dir"        # Directory to send files on target machine

# Setup the logging directory
echo "Creating logging directory $LOG_DIR..."
mkdir -p "$LOG_DIR" || { echo "Failed to create logging directory."; exit 1; }

# Establish ssh connection with target machine
echo "Creating directory on target machine $TARGET_USER@$TARGET_IP:$TARGET_DIR..."
ssh "$TARGET_USER@$TARGET_IP" "mkdir -p '$TARGET_DIR'" || { echo "Failed to create directory on target."; exit 1; }

# Function to log installed software matching defensive tools list
log_installed_software() {
    echo "Logging installed software..."
    > "$SOFTWARE_LOG"  # Clear log file if it exists
    echo "INSTALLED DEFENSIVE TOOLS:" >> "$SOFTWARE_LOG"

    for tool in "${DEFENSIVE_TOOLS[@]}"; do
        dpkg -l | grep -i "$tool" >> "$SOFTWARE_LOG"
    done
}

# Function to log running defensive processes using ps aux w/ grep
log_defensive_processes() {
    echo "Logging running defensive processes..."
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
    log_installed_software
    log_defensive_processes
    log_firewalld_rules
    log_iptables_rules
    scp "$SOFTWARE_LOG" "$PROCESS_LOG" "$FIREWALLD_LOG" "$IPTABLES_LOG" "$TARGET_USER@$TARGET_IP:$TARGET_DIR" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "Files successfully copied to $TARGET_USER@$TARGET_IP:$TARGET_DIR"
    else
        echo "Error copying files to $TARGET_USER@$TARGET_IP:$TARGET_DIR"
    fi

    echo "~~Finished main loop, waiting for cooldown!"
    sleep 35  # Wait for cooldown before the next check
done
