# Requirements
- A running Kubernetes cluster (with a kubeconfig file installed at `.kube/config`)
- Terragrunt
- Helm

Install dependencies:

```bash
brew install terragrunt helm
```

# Features

- Highly-available Postgres database
    - Automatic daily backups
    - Zero-downtime upgrades
    - Integrated monitoring & dashboard
- Microservice applications
    - Pre-built Grafana dashboard
- Observability stack
    - Distributed tracing with Jaeger
    - Pulls and aggregates metrics from all services
    - Telemetry, databases, tracing connected to Grafana
- CI
    - Automatic linting, testing on PRs
- CD
    - Build, push to GitHub packages
    - Deploy automatically to Kubernetes
- Automatic TLS certificates

# Installation

1. Clone this repository
2. Create an GitHub repository secret named KUBECONFIG (`Settings` > `Secrets & Variables` > `New repository secret`)
3. Create a Personal access token (PAT) with `read:packages` permission (https://github.com/settings/tokens)
4. Fill in your email, the PAT and your GitHub username in the file `infrastructure/terraform.tfvars`
5. Run `terragrunt run-all apply` in the `infrastructure` directory
6. Set your repository name in `app/chart/values.yaml`
6. Push your changes

# FAQ

## How do I find the password to Grafana?

```bash
kubectl get secret -n prometheus-stack grafana-password --template={{.data.password}} | base64 -d
```

## How do I access the postgres CLI?

```bash
kubectl exec -it svc/main-database-rw psql
```

## How do I tear down all resources created by this project?

```bash
kubectl exec -it svc/main-database-rw psql
```
