
# WebApps Infrastructure

This repository contains the infrastructure code for a self-hosted WordPress deployment, powered by a Jenkins-driven CI/CD pipeline and fronted by a hardened NGINX reverse proxy. This system is designed for local or private hosting, with modern automation and observability best practices.

## 🔧 Architecture Overview

This setup provides:

- **Self-hosted WordPress** with environment separation (`dev` and `prod`)
- **Custom Docker images** for both WordPress and Jenkins
- **Automated deployment pipeline** using GitHub webhooks and Jenkins multibranch pipelines
- **Version-controlled infrastructure** with rollback-ready image tagging and database promotion
- **NGINX reverse proxy** with TLS support and access restrictions
- **Local backups** of database, content, and configuration

### ⚙️ Directory Structure

```
envs/
  dev/           # Dev-specific docker-compose and environment config
  prod/          # Prod-specific docker-compose and environment config

images/
  wordpress/     # Dockerfile for custom WordPress image
  jenkins/       # Dockerfile for Jenkins with Docker, Helm, kubectl

nginx/           # Custom nginx.conf for dev/prod, Dockerfile for reverse proxy
scripts/         # Backup, restore, and utility scripts

deployment-logs/ # Auto-generated JSON logs of each production deployment
Jenkinsfile      # Declarative Jenkins pipeline
```

### 🗃️ Not Included in Repo

These are excluded to keep the repo secure and portable:

- WordPress runtime files (wp-content, themes, plugins)
- Jenkins home data (`jenkins/jenkins_home`)
- SSL/TLS certificates (`certbot/` or `nginx/certs/`)
- Persistent database data and production backups

## 🚀 CI/CD Workflow

1. ✅ Developer pushes a commit to the `main` branch
2. ✅ GitHub webhook triggers Jenkins automatically
3. ✅ Jenkins:
   - Builds and tags a new Docker image
   - Pushes image to Docker Hub (`jdrdock/wordpress-astra`)
   - Rsyncs `wp-content` from `dev` to `prod`
   - Promotes the database (with URL rewrites)
   - Deploys the updated container stack in production
   - Appends a JSON log to `deployment-logs/`

All deployments are logged weekly by timestamp and build tag.

## 💡 Design Goals

- **Local-first infrastructure** — suitable for personal or home-lab hosting
- **No secrets in source control** — uses Jenkins credentials store and `.env` files
- **Atomic promotion** — Dev is the source of truth for content and config
- **Rollback-ready** — Every Docker image is tagged with `build-<number>` and logged
- **Demo-friendly** — Meant to be browsed, forked, and customized

## 📁 How to Use

This repository is designed to run from `/opt/webapps/` with Docker Compose and Jenkins installed. You can replicate the system using:

```bash
cd /opt/webapps/envs/dev
docker compose up -d
```

Then access:

- Dev site: `https://dev.yourdomain.local`
- Prod site: `https://yourdomain.com`
- Jenkins: `https://yourdomain.com/jenkins`

## 🔒 Security Considerations

- Admin endpoints restricted to LAN IPs
- TLS enabled via mkcert or Let's Encrypt
- Fail2ban, UFW, and IP whitelisting are recommended in production

## 🧪 Future Enhancements

- Prometheus/Grafana integration for monitoring
- Loki or syslog forwarding for log aggregation
- Optional Vault integration for secret management

---

**Live Demo:**  
[https://nimbledev.io](https://nimbledev.io)

**Project Repo:**  
[https://github.com/jdrgithub/wordpress-jenkins-nginx](https://github.com/jdrgithub/wordpress-jenkins-nginx)

---

