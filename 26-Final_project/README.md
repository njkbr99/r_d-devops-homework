# Trainings Tracker — DevOps Final Project

> Go REST API · AWS · Terraform · Ansible · GitHub Actions · Docker · Prometheus · Grafana · Loki

## Architecture

[![Architecture Diagram](screenshots/01_diagram.png)](https://lucid.app/lucidchart/765a6940-90fa-40e6-870d-b193ba11bf11/edit?viewport_loc=27%2C-1717%2C2459%2C1419%2C0_0&invitationId=inv_16311c6f-78d0-4e35-9594-e727170b81ff)

> Click the diagram to open the interactive version in Lucidchart.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Repositories](#repositories)
- [Infrastructure](#infrastructure)
- [CI/CD](#cicd)
- [Monitoring](#monitoring)
- [App Demo](#app-demo)
- [How to Run From Scratch](#how-to-run-from-scratch)

---

## Project Overview

Trainings Tracker is a fitness tracking platform with a Go REST API backend and a React Native mobile frontend. This repo documents the full DevOps setup: infrastructure provisioning, configuration management, CI/CD pipelines, and monitoring.

**Tech stack:**

| Layer | Technology |
|---|---|
| Cloud | AWS (eu-north-1) |
| IaC | Terraform |
| Config management | Ansible |
| CI/CD | GitHub Actions |
| Artifact registry | Amazon ECR |
| App runtime | Docker on EC2 |
| Database | Amazon RDS MySQL |
| Monitoring | Prometheus + Grafana + Loki |
| Log shipping | Promtail |

---

## Repositories

| Repo | Description |
|---|---|
| `trainings-tracker` | Go backend + React Native mobile app + GitHub Actions workflows |
| `trainings-tracker-infra` | Terraform + Ansible for all infrastructure |

---

## Infrastructure

### AWS Resources

**VPC layout:**

| Subnet | CIDR | AZ | Contents |
|---|---|---|---|
| public-a | 10.2.1.0/24 | eu-north-1a | App EC2, ALB |
| public-b | 10.2.2.0/24 | eu-north-1b | Monitoring EC2 |
| private-a | 10.2.3.0/24 | eu-north-1a | RDS MySQL |
| private-b | 10.2.4.0/24 | eu-north-1b | RDS standby subnet |

**EC2 instances:**

| Name | Type | OS | Role |
|---|---|---|---|
| anat-trainings-tracker-app | t3.small | Amazon Linux 2023 | Backend API |
| anat-trainings-tracker-monitoring | t3.small | Ubuntu 24.04 | Prometheus, Grafana, Loki |

![AWS EC2 instances](screenshots/02_aws_ec2.png)

**Other resources:**
- ALB `trainings-tracker-alb` — HTTP:80 → EC2:3000
- RDS MySQL `trainings-tracker-mysql` — db.t3.micro, private subnet
- Elastic IP on monitoring EC2 — stable Grafana URL
- S3 `trainings-tracker-tf-state` — Terraform remote state
- ECR `trainings-tracker/backend` — Docker image registry
  
![AWS ECR instances](screenshots/03_aws_ecr.png)

![AWS S3 instances](screenshots/04_aws_s3.png)

![AWS LB instances](screenshots/05_aws_lb.png)

![AWS LB2 instances](screenshots/06_aws_lb2.png)

<details>
<summary>📝 Note to myself: Terraform setup and commands</summary>

### First time setup (bootstrap)

Before running Terraform for the first time, run the bootstrap script once to create the S3 bucket and ECR repo:

```bash
cd trainings-tracker-infra
bash scripts/bootstrap.sh
```

This creates:
- S3 bucket `trainings-tracker-tf-state` for Terraform remote state
- ECR repository `trainings-tracker/backend` for Docker images

These are created manually because Terraform can't store its own state before the bucket exists (chicken-and-egg), and ECR shouldn't be destroyed by `terraform destroy`.

### Terraform commands (run from `terraform/` directory)

```bash
# First time or after backend config changes
terraform init

# Format code
terraform fmt

# Validate syntax
terraform validate

# Preview changes
terraform plan

# Apply (creates/updates resources)
terraform apply

# Destroy everything
terraform destroy
```

### Remote state locking

Uses native S3 locking (`use_lockfile = true`) introduced in Terraform 1.10. No DynamoDB table needed. The lock file is stored alongside the state in S3.

### After terraform apply

Copy the outputs — you'll need them for Ansible vars and GitHub secrets:
- `app_instance_public_ip` → GitHub secret `EC2_HOST`
- `app_url` → GitHub secret `ALB_DNS` (strip the `http://`)
- `rds_endpoint` → GitHub secret `DB_HOST` and Ansible `vars.yml`
- `monitoring_instance_private_ip` → Ansible `vars.yml` `monitoring_private_ip`
- `app_instance_private_ip` → Ansible `vars.yml` `app_private_ip`
- `grafana_url` → bookmark for Grafana access

### Key design decisions

- App EC2 has an IAM role with `AmazonEC2ContainerRegistryReadOnly` — no stored AWS credentials needed to pull Docker images
- RDS is in private subnets — not reachable from the internet, only from the app EC2 via security group rule
- ALB spans both public subnets (required by AWS) — stable DNS entry point for the API
- Monitoring EC2 has an Elastic IP — Grafana URL stays stable across restarts

</details>

---

### Ansible

Ansible configures both EC2 instances after Terraform provisions them. Uses dynamic inventory via `amazon.aws.aws_ec2` plugin — automatically discovers instances by the `Project: trainings-tracker` tag.

```bash
# Run from ansible/ directory
ansible-playbook site.yml
```

**What it installs:**

| Instance | Role | What gets installed |
|---|---|---|
| app | docker | Docker, docker-compose |
| app | node_exporter | Node Exporter as systemd service |
| app | promtail | Promtail as systemd service |
| app | app | ECR login, docker-compose deploy |
| monitoring | monitoring | Prometheus, Grafana, Loki via Docker |

<details>
<summary>📝 Note to myself: Ansible setup</summary>

### Prerequisites

```bash
pip install boto3 botocore ansible
ansible-galaxy collection install amazon.aws
```

### SSH key

The key pair `anat-trainings-tracker-key.pem` must exist at `~/.ssh/anat-trainings-tracker-key.pem` with correct permissions:

```bash
chmod 400 ~/.ssh/anat-trainings-tracker-key.pem
```

On Windows use icacls:
```
icacls anat-trainings-tracker-key.pem /inheritance:r /grant:r "%USERNAME%:R"
```

### Dynamic inventory

The inventory plugin auto-discovers EC2 instances tagged with `Project: trainings-tracker`. It sets the correct SSH user per instance:
- `ec2-user` for Amazon Linux (app EC2)
- `ubuntu` for Ubuntu (monitoring EC2)

To test the inventory:
```bash
ansible-inventory --list
```

### Vault

Secrets (`db_password`, `jwt_secret`) are stored in `group_vars/all/vault.yml` encrypted with Ansible Vault.

To edit:
```bash
ansible-vault edit group_vars/all/vault.yml
```

To run playbook with vault:
```bash
ansible-playbook site.yml --ask-vault-pass
```

### Vars that need updating after terraform apply

In `group_vars/all/vars.yml`:
- `db_host` — RDS endpoint from Terraform output
- `monitoring_private_ip` — from Terraform output
- `app_private_ip` — from Terraform output


</details>

---

## CI/CD

Two GitHub Actions workflows handle the full delivery pipeline.

### Flow

```
Push to any branch
        │
        ▼
Open PR → r_d_final_project_prod
        │
        ▼ pr.yml triggers
  lint + test + build
  push image to ECR :commit-hash
        │
        ▼
Click Merge
        │
        ▼ main.yml triggers
  bump minor version (semver.py)
  commit version + git tag
  build + push to ECR :version + :latest
        │
        ▼
Manual approval gate (GitHub environment: production)
        │
        ▼
SSH to EC2 → stop old container → pull new image → run app
        │
        ▼
Print app URL to job summary
```

> Direct push to `r_d_final_project_prod` is blocked at the repository level — all changes must go through a PR.

Current downtime is approximately 30-60 seconds during container replacement. 
This is acceptable for a course project, but if I would launch this app to production right now, I would implement "blue-green" deployment using the ALB. 
Starting the new container alongside the old one, waiting for the health check to pass, then switching the ALB target and stopping the old container. This would bring downtime to zero and have no riscs of users being affected with the current state of my app

### PR pipeline screenshot

![GitHub PR pipeline result](screenshots/07_git_pr_pipeline.png)

![GitHub PR pipeline result2](screenshots/08_git_pr_pipeline2.png)

### Main pipeline screenshot

![GitHub Main pipeline result](screenshots/09_git_main_pipeline.png)

![GitHub Main pipeline result2](screenshots/09_git_main_pipeline2.png)

![GitHub Main pipeline result3](screenshots/09_git_main_pipeline3.png)

<details>
<summary>📝 Note to myself: GitHub Actions setup</summary>

### Required GitHub secrets

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `EC2_HOST` | App EC2 public IP (from Terraform output) |
| `EC2_SSH_KEY` | Contents of `anat-trainings-tracker-key.pem` |
| `DB_HOST` | RDS endpoint (from Terraform output) |
| `DB_USER` | RDS username |
| `DB_PASSWORD` | RDS password |
| `JWT_SECRET` | JWT signing secret |
| `ALB_DNS` | ALB DNS name without `http://` (from Terraform output `app_url`) |

### Branch protection

In GitHub repo settings → Branches → Add rule for `r_d_final_project_prod`:
- ✅ Require a pull request before merging
- ✅ Require status checks to pass → select `lint-test-build`

### Manual approval gate

The `deploy` job uses `environment: production`. Set this up in GitHub repo settings → Environments → production → add yourself as a required reviewer. The pipeline will pause after build and wait for your approval before deploying.

### Semver versioning

`scripts/semver.py` reads the `VERSION` file, bumps the minor version, writes it back, and prints the new version. The pipeline commits this back to the branch and creates a Git tag.

Example: `1.4.0` → `1.5.0` → `1.6.0`

### ECR image tags

| Pipeline | Tag |
|---|---|
| PR | `:a1b2c3d` (short commit hash) |
| Main | `:1.6.0` + `:latest` |

</details>

P.S. How so the issue with credentials in GitHub Actions is not a solved problem that pops-up first in search...

![Main pipeline fail fiesta](screenshots/10_git_many_failed_main_pipelines.png)

---

## Monitoring

Monitoring runs on the dedicated `anat-trainings-tracker-monitoring` EC2 (Ubuntu 24.04) via Docker Compose.

| Service | Port | Purpose |
|---|---|---|
| Prometheus | :9090 | Metrics collection |
| Grafana | :3000 | Dashboards |
| Loki | :3100 | Log aggregation |

On the app EC2, two systemd services run alongside the app container:
- **Node Exporter** `:9100` — VM metrics (CPU, memory, disk, network)
- **Promtail** `:9080` — ships Docker container logs to Loki

### Grafana dashboard

<!-- TODO: Add screenshot of Grafana dashboard showing VM metrics -->

### Prometheus targets

<!-- TODO: Add screenshot of Prometheus targets page showing all targets UP -->

<details>
<summary>📝 Note to myself: Monitoring setup and access</summary>

### Access URLs

- Grafana: `http://<monitoring-eip>:3000` (default login: admin / admin123)
- Prometheus: `http://<monitoring-eip>:9090`

The monitoring EIP is stable — it won't change on EC2 restart. Get it from `terraform output grafana_url`.

### What Prometheus scrapes

Defined in `ansible/roles/monitoring/templates/prometheus.yml.j2`:
- `localhost:9090` — Prometheus itself
- `<app-private-ip>:9100` — Node Exporter (VM metrics)
- `<app-private-ip>:3000/api/metrics` — App metrics endpoint

### Log flow

```
App container stdout
      ↓
Docker JSON logs (/var/lib/docker/containers/*/*-json.log)
      ↓
Promtail (reads log files)
      ↓
Loki :3100 (on monitoring EC2, via private IP)
      ↓
Grafana (Loki datasource)
```

### Data persistence

All monitoring data is stored in Docker named volumes on the monitoring EC2:
- `prometheus_data` — metrics history
- `grafana_data` — dashboards and settings
- `loki_data` — log history

⚠️ If the monitoring EC2 is terminated and recreated, all history is lost. For production, mount an EBS volume or use remote storage (S3 for Loki, Thanos for Prometheus).

### Restarting the monitoring stack

```bash
ssh ubuntu@<monitoring-eip>
cd /opt/monitoring
docker-compose restart
```

</details>

---

## App Demo

### Before deployment — initial state

<!-- TODO: Add GIF of app running before the test deployment (login, browse) -->

### After test deployment — new version live

<!-- TODO: Add GIF of app after CI/CD deployment showing new version or change -->

---

## How to Run From Scratch

> Full setup from zero to running app.

### Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform >= 1.10
- Ansible + `amazon.aws` collection
- SSH key pair created in AWS as `anat-trainings-tracker-key`

### Step 1 — Bootstrap (once only)

```bash
cd trainings-tracker-infra
bash scripts/bootstrap.sh
```

### Step 2 — Provision infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Note the outputs — you'll need them in the next steps.

### Step 3 — Configure instances

Update `ansible/group_vars/all/vars.yml` with IPs and RDS endpoint from Terraform outputs, then:

```bash
cd ansible
ansible-playbook site.yml --ask-vault-pass
```

### Step 4 — Configure GitHub secrets

Add all secrets listed in the CI/CD section above to the GitHub repository.

### Step 5 — Deploy the app

Push a change to a feature branch → open a PR to `r_d_final_project_prod` → wait for checks to pass → merge → approve the deployment in GitHub Actions.

### Step 6 — Verify

```bash
# App health check
curl http://<alb-dns>/api/health

# Grafana
open http://<monitoring-eip>:3000
```

### Teardown

```bash
cd terraform
terraform destroy
```

> Note: S3 bucket and ECR repository are NOT destroyed — they were created by `bootstrap.sh` and must be deleted manually if needed.