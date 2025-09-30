FROM debian:bookworm-slim@sha256:7e490910eea2861b9664577a96b54ce68ea3e02ce7f51d89cb0103a6f9c386e0

# Install Tailscale and necessary dependencies (like openssh-server)
RUN apt-get update && apt-get install -y curl ca-certificates openssh-server
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list
RUN apt-get update && apt-get install -y tailscale
RUN mkdir -p /run/sshd

# Create a script to start Tailscale and the SSH server
COPY start.sh /start.sh
RUN chmod +x /start.sh

# This entrypoint will run your start script
ENTRYPOINT ["/start.sh"]