# Requirements
- A running Kubernetes cluster (with a kubeconfig file installed at `.kube/config`)
- A registered domain name and access to DNS configuration

# Features

- Highly-available Postgres database
    - Automatic daily backups
    - Zero-downtime upgrades
    - Integrated monitoring & dashboard
- NodeJS backend
    - Integrated monitoring & Grafana dashboard
- Observability
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

Install dependencies:
```bash
brew install terragrunt helm
```

1. Fork this repository and clone it locally
2. Create an GitHub repository secret named KUBECONFIG (`Settings` > `Secrets & Variables` > `Actions` > `New repository secret`) with the contents of your kubeconfig file
3. Create a Personal access token (PAT) with `read:packages` permission (https://github.com/settings/tokens)
4. Copy the file `infrastructure/terraform.tfvars.skel` to `infrastructure/terraform.tfvars` and fill it in with your email, the PAT and your GitHub username
5. Create a DNS A record with the value[1] pointing to the ingress IP address (you can find it with `kubectl get svc -n nginx-ingress nginx-ingress-ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}'`) and set the domain name in `infratructure/root.hcl`
6. Run `terragrunt run-all apply` in the `infrastructure` directory
8. Push an empty commit to trigger deployment of the API service (`git commit --allow-empty -m "initial commit"`)

[1] I.e. enter `mycluster` as value to access the cluster at mycluster.example.com, given that example.com is the domain name.

# FAQ

## How do I access Grafana?

Grafana is accessible at <DOMAIN_NAME>/grafana.

Log in with username `admin` and password from the `grafana-password` secret in the `monitoring` namespace, you can get it with kubectl:

```bash
kubectl get secret -n monitoring grafana-password --template={{.data.password}} | base64 -d
```

## How do I access the backend over HTTPS?

The backend API is accessable at `<DOMAIN_NAME>/api` where the domain name is the value you put in the `terraform.tfvars` file. Or using curl:

```bash
curl https://<DOMAIN_NAME>/api
```

## How do I access the postgres CLI?

```bash
kubectl exec -it svc/main-database-rw psql
```
