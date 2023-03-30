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

# Automatic Installation

The `install.sh` will run you through the full installation:

```bash
sh ./install.sh
```

# Manual Installation

1. Fork this repository and clone it locally
2. Create an GitHub repository secret named KUBECONFIG (`Settings` > `Secrets & Variables` > `Actions` > `New repository secret`) with the contents of your kubeconfig file
3. Create a Personal access token (PAT) with `read:packages` permission (https://github.com/settings/tokens)
4. Copy the file `infrastructure/terraform.tfvars.skel` to `infrastructure/terraform.tfvars` and fill it in with your email, the PAT and your GitHub username
5. Create a DNS A record with the value `*` pointing to the ingress IP address (you can find it with `kubectl get svc -n nginx-ingress nginx-ingress-ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}'`) and set the domain name in `infratructure/root.hcl`
6. Run `terragrunt run-all apply` in the `infrastructure` directory
8. Push an empty commit to trigger deployment of the API service (`git commit --allow-empty -m "initial commit"`)

# FAQ

## How do I find the password to Grafana?

Log in with username `admin` and password from the `grafana-password` secret in the `monitoring` namespace, you can get it with kubectl:

```bash
kubectl get secret -n monitoring grafana-password --template={{.data.password}} | base64 -d
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
