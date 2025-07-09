# Tailscale Bastion Host

A Docker container that acts as a bastion host for accessing other nodes on a Tailscale network. This container runs Tailscale in userspace networking mode, making it ideal for deployment in containerized environments where traditional networking might be restricted.

## Features

- **Userspace Networking**: Uses Tailscale's userspace networking mode for maximum compatibility
- **SSH Access**: Includes SSH server for secure remote access to the Tailscale network
- **Lightweight**: Based on Debian bookworm-slim for minimal footprint
- **Graceful Shutdown**: Handles container signals properly for clean shutdowns
- **Route Acceptance**: Automatically accepts subnet routes from other Tailscale nodes

## Quick Start

### Prerequisites

- Docker or compatible container runtime
- Tailscale account and auth key
- Access to the Tailscale network you want to connect to

### Running the Container

```bash
docker run -d \
  --name tailscale-bastion \
  -e TS_AUTHKEY="your-tailscale-auth-key" \
  -e TS_HOSTNAME="bastion-host" \
  ghcr.io/glueops/tailscale-bastion:latest
```

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `TS_AUTHKEY` | Yes | - | Tailscale authentication key |
| `TS_HOSTNAME` | Yes | - | Hostname for this node on the Tailscale network |
| `TS_STATE_DIR` | No | `/var/lib/tailscale` | Directory to store Tailscale state |
| `TS_EXTRA_ARGS` | No | - | Additional arguments to pass to tailscaled |

### Using the Bastion Host

Once the container is running and connected to your Tailscale network, you can:

1. **SSH into the bastion**: Use the Tailscale IP of the bastion host
2. **Access internal resources**: From the bastion, access other nodes on your Tailscale network using `tailscale ssh`
3. **Route traffic**: The bastion accepts routes from other Tailscale nodes automatically

```bash
# From within the bastion, access other Tailscale nodes
tailscale ssh user@<internal-node-tailscale-ip>
```

## Building from Source

```bash
git clone https://github.com/glueops/tailscale-bastion.git
cd tailscale-bastion
docker build -t tailscale-bastion .
```

## Container Architecture

The container includes:
- **Debian bookworm-slim** base image
- **Tailscale** client with userspace networking
- **OpenSSH server** for bastion access
- **Graceful shutdown** handling via signal traps
- **Multi-architecture support** (amd64, arm64) via GitHub Actions

## Configuration

### Tailscale Auth Keys

Generate an auth key from your Tailscale admin console:
1. Go to https://login.tailscale.com/admin/settings/keys
2. Generate a new auth key
3. Use the key as the `TS_AUTHKEY` environment variable

### Network Access

The container:
- Connects to your Tailscale network using the provided auth key
- Accepts subnet routes from other Tailscale nodes (`--accept-routes`)
- Disables DNS acceptance to avoid conflicts (`--accept-dns=false`)
- Runs in userspace networking mode for container compatibility
- Provides SSH access for bastion functionality