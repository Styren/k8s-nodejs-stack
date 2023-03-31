#!/usr/bin/env bash
bold=$(tput bold)
normal=$(tput sgr0)

set -e

echo "${bold}[Dependencies]${normal}"
echo "Making sure dependencies are installed..."

if which terragrunt; then
  echo "\tTerragrunt ✅"
else
  read -p "\tTerragrunt is not installed — do you want to install it? (y/N) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    brew install terragrunt
  else
    exit 1
  fi

fi

if which kubectl; then
  echo "\tKubectl ✅"
else
  read -p "\tKubectl is not installed — do you want to install it? (y/N) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    brew install kubectl
  else
    exit 1
  fi
fi

if which helm; then
  echo "\tHelm ✅"
else
  read -p "\tHelm is not installed — do you want to install it? (y/N) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    brew install helm
  else
    exit 1
  fi
fi

echo "Checking whether there is an installed kubeconfig file..."

echo "Kubeconfig properly installed ✅"

echo "Installing NGINX ingress..."

pushd infrastructure/modules/nginx-ingress
if terragrunt apply --terragrunt-non-interactive -auto-approve 2>/dev/null; then
  echo "NGINX ingress installed ✅"
else
  echo "Failed to install NGINX ingress ❌"
  exit 1
fi
popd

echo "Waiting for NGINX load balancer to get initialized..."

while ! LB_IPV4=$(kubectl get svc -n nginx-ingress nginx-ingress-ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}'); do sleep 1; done

echo "NGINX load balancer initialized (IPv4 address: $LB_IPV4) ✅"

echo "Configuring parameters..."

echo "${bold}[GitHub Personal Access Token]${normal}"
echo "Create a Personal access token (PAT) with \`write:packages\`+\`read:packages\` permissions (https://github.com/settings/tokens)"

read -p "Enter your PAT: " GITHUB_PAT
read -p "Enter the GitHub username you used to generate the PAT: " GITHUB_USERNAME

echo "Logging in to GitHub package registry..."
echo $GITHUB_PAT | docker login ghcr.io --username $GITHUB_USERNAME --password-stdin
echo "Done ✅"

echo "${bold}[Email]${normal}"
echo "LetsEncrypt require that you register your email address in order to use them to generateTLS certificates, make sure to use your real email as it may otherwise be rejected"
read -p "Enter your email address: " ACME_EMAIL

echo "${bold}[Domain name]${normal}"
echo "Next up is configuring the DNS settings so that requests to your selected domain name will resolve to the IPv4 address for the load balancer"
echo "By creating a wildcard DNS record we can resolve all subdomains to our load balancer address"
echo "Create a CNAME record in your DNS settings with host ${bold}*${normal} and value ${bold}$LB_IPV4${normal}"
echo "${bold}Note:${normal} You can use a subdomain by setting the host to ${bold}*.mysubdomain${normal}, but make sure to include that subdomain in the value entered below"

read -p "Enter your domain name: " DOMAIN_NAME
echo 'Verifying DNS settings...'
DIG_RES=$(dig "*.$DOMAIN_NAME" +short)
if [ "$DIG_RES" = "$LB_IPV4" ]; then
  echo "Record for *.$DOMAIN_NAME: $DIG_RES ✅"
else
  read -p "Record for *.$DOMAIN_NAME: $DIG_RES (wanted $LB_IPV4) ❌ Proceed anyway? (y/N)" -n 1 -r
  echo ""
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

echo "Setting the domain name in the Terraform configuration..."
sed -i -e "s/\  domain.*=.*/  domain = \"$DOMAIN_NAME\"/" infrastructure/root.hcl
echo "Done ✅"

echo "Setting the GitHub and email settings in the Terraform vars file..."
cat <<EOT >infrastructure/terraform.tfvars
# The personal access token (PAT) you created in your GitHub repo settings
github_pat = "$GITHUB_PAT"
# The Username of the GitHub personal access token, in order to be able to access the GitHub package registry
github_username = "$GITHUB_USERNAME"
# An email that will be registered with LetsEncrypt for your TLS certificates
acme_email = "$ACME_EMAIL"
EOT
echo "Done ✅"

echo "Installing all remaining terraform modules"
pushd infrastructure
if terragrunt run-all apply --terragrunt-non-interactive 2>/dev/null; then
  echo "NGINX ingress installed ✅"
else
  echo "Failed to install NGINX ingress ❌"
  exit 1
fi
popd

GITHUB_USERNAME_LOWERCASE=$(echo "$GITHUB_USERNAME" | awk '{print tolower($0)}')
GITHUB_REPO=$(basename `git rev-parse --show-toplevel`)
echo "Building, pushing & deploying API"
pushd api
API_TAG=ghcr.io/$GITHUB_USERNAME_LOWERCASE/$GITHUB_REPO/nodejs-api:initial
docker buildx build --push --platform linux/amd64,linux/arm64 -t "$API_TAG" .
helm upgrade --install nodejs-api --wait --set "image.repository=$API_TAG" ./charts
popd
echo "---"
echo "All done! ✅"
echo "Access Grafana at grafana.$DOMAIN_NAME"
echo "Access API at api.$DOMAIN_NAME"
