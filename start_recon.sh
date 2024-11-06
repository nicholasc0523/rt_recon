#!/bin/bash

# Wrapper script for rt_recon.sh

# Get the absolute path of the current script (start_recon.sh)
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Define the full path to the main script (recon2.sh)
RECON_SCRIPT="$SCRIPT_DIR/rt_recon.sh"

# Use exec -a to rename the process and start the main script
nohup exec -a "gddc_score" bash "$SCRIPT_DIR/$RECON_SCRIPT" > /dev/null 2>&1 &
