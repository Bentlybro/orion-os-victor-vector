#!/usr/bin/env bash

# Move to repo root
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
echo "Working directory: $DIR"
cd "$DIR"

# === Configuration ===
ROBOT_KEY="/tmp/fixssh/robot_sshkey"
KNOWN_HOSTS="/tmp/fixssh/known_hosts"

# === Sanity Checks ===
if [[ ! -f robot_ip.txt ]]; then
    echo "❌ Error: robot_ip.txt not found. Please run:"
    echo 'echo "192.168.0.xxx" > robot_ip.txt'
    exit 1
fi

if [[ ! -f "$ROBOT_KEY" ]]; then
    echo "❌ Error: SSH key not found at $ROBOT_KEY"
    exit 1
fi

# === Setup SSH known hosts (optional but avoids prompts) ===
ROBOT_IP=$(cat robot_ip.txt)

if [[ ! -f "$KNOWN_HOSTS" ]]; then
    echo "🔐 Creating known_hosts file..."
    mkdir -p "$(dirname "$KNOWN_HOSTS")"
    ssh-keyscan -t ed25519 "$ROBOT_IP" > "$KNOWN_HOSTS" 2>/dev/null
    chmod 600 "$KNOWN_HOSTS"
fi

# === Configure SSH agent ===
eval "$(ssh-agent -s)" >/dev/null
ssh-add "$ROBOT_KEY" >/dev/null

# === Patch ssh + scp ===
export SSH_OPTIONS="-i $ROBOT_KEY -o UserKnownHostsFile=$KNOWN_HOSTS -o StrictHostKeyChecking=no -o PubkeyAcceptedAlgorithms=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa"

alias ssh="ssh $SSH_OPTIONS"
alias scp="scp $SSH_OPTIONS"

# === Run deployment ===
export ANKI_ROBOT_HOST="$ROBOT_IP"
./project/victor/scripts/victor_deploy.sh -c Release -b
./project/victor/scripts/victor_start.sh
