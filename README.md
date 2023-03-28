# Requirements
- A running Kubernetes cluster (with a kubeconfig file installed at `.kube/config`)
- A registered domain name and access to DNS configuration
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
    - Integrated monitoring & dashboard (TODO)
- NodeJS backend
    - Pre-built Grafana dashboard (TODO)
- Observability stack
    - Distributed tracing with Jaeger
    - Pulls and aggregates metrics from all services
    - Telemetry, databases, tracing connected to Grafana
- CI+CD with GitHub actions
    - Automatic linting, testing on PRs
    - Build, push to GitHub packages
    - Deploy automatically on merge
- Automatic TLS certificates

# Installation

1. Clone this repository
2. Create an GitHub repository secret named KUBECONFIG (`Settings` > `Secrets & Variables` > `Actions` > `New repository secret`)
3. Create a Personal access token (PAT) with `read:packages` permission (https://github.com/settings/tokens)
4. Fill in your email, the PAT and your GitHub username in the file `infrastructure/terraform.tfvars`
5. Run `terragrunt run-all apply` in the `infrastructure` directory
6. Create a DNS A record with the value `*` pointing to the ingress IP address (you can find it with `kubectl get svc -n nginx-ingress nginx-ingress-ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}'`)
7. Push an empty commit to trigger deployment of the API service (`git commit --allow-empty -m "initial commit"`)

# FAQ

## How do I find the password to Grafana?

```bash
kubectl get secret -n prometheus-stack grafana-password --template={{.data.password}} | base64 -d
```

## How do I access the backend over HTTPS?

The backend API is accessable at `api.<DOMAIN_NAME>` where the domain name is the value you put in the `terraform.tfvars` file. Or using curl:

```bash
curl https://api.<DOMAIN_NAME>
```

## How do I access the postgres CLI?

```bash
kubectl exec -it svc/main-database-rw psql
```
