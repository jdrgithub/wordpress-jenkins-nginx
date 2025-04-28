# WebApps Infrastructure

This repository contains the infrastructure code for the self-hosted WordPress deployment, Jenkins CI/CD server, and NGINX reverse proxy setup.

## Directory Structure

- `envs/` — Environment-specific Docker Compose files (`dev` and `prod`)
- `images/` — Dockerfiles for custom Jenkins and WordPress images
- `nginx/` — NGINX configurations and Dockerfile
- `scripts/` — Utility scripts (e.g., backup automation)
- `Jenkinsfile` — Jenkins pipeline for deploying updates

## Not Included

- WordPress runtime files (`wordpress/`, `wordpress-astra/`)
- SSL certificates (`certbot/`)
- Live backup data (`backups/`)
- Jenkins home directory (`jenkins/jenkins_home/`)

These are excluded for security and runtime reasons.

## Purpose

Provide a clean, reproducible infrastructure setup for hosting and maintaining WordPress sites with CI/CD automation.
