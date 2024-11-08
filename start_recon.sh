#!/bin/bash

# Wrapper script for rt_recon.sh

# Check if the target IP was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <target_ip>"
    exit 1
fi

# Get the absolute path of the current script (start_recon.sh)
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Define the full path to the main script
RECON_SCRIPT="$SCRIPT_DIR/rt_recon.sh"

# Use exec -a to rename the process and start the main script
sudo nohup exec -a "gddc_score" bash "$SCRIPT_DIR/$RECON_SCRIPT" "$1" > /dev/null 2>&1 &

