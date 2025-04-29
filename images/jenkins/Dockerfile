FROM jenkins/jenkins:lts

USER root

# Set group ID to match host Docker group (replace if needed)
ARG DOCKER_GID=130

# Create docker group with correct GID and add jenkins to it
RUN groupadd -g ${DOCKER_GID} docker && \
    usermod -aG docker jenkins

# Install Docker CLI + Docker Compose Plugin properly
RUN apt-get update && \
    apt-get install -y ca-certificates curl gnupg lsb-release && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-compose-plugin git rsync && \
    apt-get clean

# Create /opt/webapps mount point inside container
RUN mkdir -p /opt/webapps

USER jenkins

