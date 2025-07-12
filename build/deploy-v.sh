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

# Always refresh the known_hosts file to avoid conflicts
echo "🔐 Refreshing known_hosts file..."
mkdir -p "$(dirname "$KNOWN_HOSTS")"
# Remove any existing entries for this IP
ssh-keygen -f "$KNOWN_HOSTS" -R "$ROBOT_IP" 2>/dev/null || true
# Scan for all available key types
ssh-keyscan -t rsa,dsa,ecdsa,ed25519 "$ROBOT_IP" >> "$KNOWN_HOSTS" 2>/dev/null
chmod 600 "$KNOWN_HOSTS"

# === Configure SSH agent ===
eval "$(ssh-agent -s)" >/dev/null
ssh-add "$ROBOT_KEY" >/dev/null

# === Create SSH config file ===
SSH_CONFIG_FILE="/tmp/fixssh/ssh_config"
mkdir -p "$(dirname "$SSH_CONFIG_FILE")"

cat > "$SSH_CONFIG_FILE" << EOF
Host *
    IdentityFile $ROBOT_KEY
    UserKnownHostsFile $KNOWN_HOSTS
    StrictHostKeyChecking no
    PubkeyAcceptedKeyTypes +ssh-rsa
    HostKeyAlgorithms +ssh-rsa
EOF

# === Export SSH config for deployment scripts ===
export SSH_CONFIG_FILE="$SSH_CONFIG_FILE"

# === Create wrapper scripts that use our SSH config ===
SSH_WRAPPER_DIR="/tmp/fixssh/bin"
mkdir -p "$SSH_WRAPPER_DIR"

cat > "$SSH_WRAPPER_DIR/ssh" << 'EOF'
#!/bin/bash
exec /usr/bin/ssh -F "$SSH_CONFIG_FILE" "$@"
EOF

cat > "$SSH_WRAPPER_DIR/scp" << 'EOF'
#!/bin/bash
exec /usr/bin/scp -F "$SSH_CONFIG_FILE" "$@"
EOF

chmod +x "$SSH_WRAPPER_DIR/ssh" "$SSH_WRAPPER_DIR/scp"

# === Add wrapper directory to PATH ===
export PATH="$SSH_WRAPPER_DIR:$PATH"

# === Run deployment ===
export ANKI_ROBOT_HOST="$ROBOT_IP"
./project/victor/scripts/victor_deploy.sh -c Release -b
./project/victor/scripts/victor_start.sh
