FROM ubuntu:22.04

# Install dependencies
RUN apt update && \
    apt install -y software-properties-common wget curl git openssh-client tmate python3 && \
    apt clean

# Create a dummy index page to keep the service alive
RUN mkdir -p /app && echo "Tmate Session Running..." > /app/index.html
WORKDIR /app

EXPOSE 6080
EXPOSE 19132/udp

# Start a dummy Python web server to keep Railway service active
# and start tmate session
CMD python3 -m http.server 6080 & \
    tmate -F
