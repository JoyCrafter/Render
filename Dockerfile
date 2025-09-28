# Use an official Ubuntu runtime as a parent image
FROM ubuntu:22.04

# Set environment variable for the port
ENV PORT=8080

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl wget gnupg software-properties-common && \
    curl -fsSL https://code-server.dev/install.sh | sh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Expose the correct port
EXPOSE $PORT

# Start code-server (listen on all interfaces)
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "none"]
