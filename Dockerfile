FROM linuxserver/code-server:latest

# Install AWS CLI for RustFS backups
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3-pip \
      groff \
      less \
      && pip3 install --break-system-packages awscli \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

# Copy scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# Copy configs
COPY config/opencode/ /config/opencode/

# Create workspace directories
RUN mkdir -p /workspace/.memory

ENTRYPOINT ["/scripts/init.sh"]
