#!/usr/bin/env bash

# Fail on error or undefined variable
set -eu

# === CONFIGURATION ===
# Set robot IP (edit if needed or use a robot_ip.txt file)
ROBOT_IP=$(cat ./robot_ip.txt)

# Absolute path to your working private key (edit as needed)
SSH_KEY_PATH="$(pwd)/robot_sshkey"

# === FUNCTION TO RUN REMOTE COMMAND ===
robot_sh() {
    ssh -i "$SSH_KEY_PATH" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        root@$ROBOT_IP "$@"
}

# === ENTRY POINT ===
robot_sh "$@"

