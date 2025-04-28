FROM jenkins/jenkins:lts

USER root

# Install kubectl (v1.29.3 — can update later)
RUN curl -LO "https://dl.k8s.io/release/v1.29.3/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Install Helm
RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Set group ID to match host Docker group (replace if needed)
ARG DOCKER_GID=130

# Create docker group with correct GID and add jenkins to it
RUN groupadd -g ${DOCKER_GID} docker && \
    usermod -aG docker jenkins

# Install Docker CLI and git
RUN apt-get update && \
    apt-get install -y docker.io git

# Switch to jenkins user
USER jenkins

