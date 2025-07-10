#!/bin/bash
set -e

# Function to handle graceful shutdown
cleanup() {
    echo "Received shutdown signal, cleaning up..."
    if [ -n "$TAILSCALED_PID" ]; then
        echo "Stopping tailscaled (PID: $TAILSCALED_PID)..."
        kill -TERM "$TAILSCALED_PID" 2>/dev/null || true
        wait "$TAILSCALED_PID" 2>/dev/null || true
    fi
    echo "Cleanup complete"
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT SIGQUIT

# Validate required environment variables
if [ -z "$TS_AUTHKEY" ]; then
    echo "ERROR: TS_AUTHKEY environment variable is required"
    exit 1
fi

if [ -z "$TS_HOSTNAME" ]; then
    echo "ERROR: TS_HOSTNAME environment variable is required"
    exit 1
fi

if [ -z "$PUBLIC_SSH_KEY" ]; then
    echo "ERROR: PUBLIC_SSH_KEY environment variable is required"
    exit 1
fi

# Set default values for optional variables
TS_STATE_DIR="${TS_STATE_DIR:-/var/lib/tailscale}"
TS_EXTRA_ARGS="${TS_EXTRA_ARGS:-}"

echo "Adding public SSH key to authorized_keys..."
mkdir -p /root/.ssh
echo "$PUBLIC_SSH_KEY" > /root/.ssh/authorized_keys
echo "Setting secure permissions..."
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

echo "Starting sshd service..."
/usr/sbin/sshd

echo "Starting Tailscale bastion host..."
echo "Hostname: $TS_HOSTNAME"
echo "State directory: $TS_STATE_DIR"

# Start the Tailscale daemon in the background
echo "Starting tailscaled daemon..."
tailscaled \
    --state="$TS_STATE_DIR/tailscaled.state" \
    --tun=userspace-networking \
    $TS_EXTRA_ARGS &

TAILSCALED_PID=$!
echo "tailscaled started with PID: $TAILSCALED_PID"

# Wait for tailscaled to be ready
echo "Waiting for tailscaled to be ready..."
timeout=30
while ! tailscale status --json >/dev/null 2>&1; do
    sleep 1
    timeout=$((timeout - 1))
    if [ $timeout -eq 0 ]; then
        echo "ERROR: tailscaled failed to start within 30 seconds"
        exit 1
    fi
done

# Bring up the Tailscale network interface
echo "Connecting to Tailscale network..."
tailscale up \
    --authkey="$TS_AUTHKEY" \
    --hostname="$TS_HOSTNAME" \
    --accept-routes \
    --accept-dns=false

if [ $? -eq 0 ]; then
    echo "Successfully connected to Tailscale network"
    echo "Node status:"
    tailscale status
else
    echo "ERROR: Failed to connect to Tailscale network"
    exit 1
fi

echo "Tailscale bastion host is ready!"

# Keep the container running and wait for signals
wait "$TAILSCALED_PID"

