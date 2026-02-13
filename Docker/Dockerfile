# syntax=docker/dockerfile:1
FROM node:20-slim

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user
RUN groupadd -r claude && useradd -r -g claude -G sudo -m -s /bin/bash claude

# Set up sudo for non-root user
RUN echo "claude ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create workspace directory
RUN mkdir -p /workspace && chown -R claude:claude /workspace

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER claude

# Default command
CMD ["bash"]
