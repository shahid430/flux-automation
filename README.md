# CICD Pipeline for Minikube Cluster on Local Machine

## 1. Start a New Minikube Cluster

Start Minikube with specific resources and API server options:

```sh
minikube start \
  --driver=docker \                           # Use Docker as the VM driver
  --cpus=4 --memory=8192 \                    # Allocate 4 vCPUs and 8GB RAM to the cluster
  --kubernetes-version=v1.31.0 \              # Specify Kubernetes version (change as needed)
  --extra-config=apiserver.authorization-mode=Node,RBAC \ # Enable Node & RBAC authorization modes
  --extra-config=apiserver.enable-admission-plugins=MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,LimitRanger,NamespaceLifecycle,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds \
  --extra-config=apiserver.audit-log-path=/var/log/kube-apiserver-audit.log \   # Path for API server audit logs
  --extra-config=apiserver.audit-log-maxage=5 \         # Keep audit logs for 5 days
  --extra-config=apiserver.audit-log-maxsize=100        # Max size of each audit log file (MB)
```

## 2. Enable Useful Minikube Addons (Optional)

Enable addons as per your requirements:

```sh
minikube addons enable metrics-server     # Metrics server for resource metrics (used by HPA, etc.)
minikube addons enable dashboard          # Kubernetes Dashboard UI
minikube addons enable ingress            # NGINX ingress controller
```

## 3. Validate the Cluster and Addons

```sh
kubectl get nodes
# Check that the Minikube node is ready

kubectl get pods -A
# Check that all system and addon pods are running

minikube addons list | grep -E 'metrics-server|dashboard|ingress|registry'
# Verify that the required addons are enabled
```

Check your Minikube IP to use it for NodePort services:

```sh
minikube ip
# Get Minikube cluster IP
```

---

## ✅ Completed Kubernetes Cluster Deployment

Let's build the applications now with FluxCD automation.

---

## 4. Release Automation with FluxCD

### Step 1: Install Flux CRDs Using Bootstrap Command

```sh
flux bootstrap github \
  --token-auth \
  --owner=XXXXXXXXXXX \              # This is your GitHub username
  --repository=flux-automation \
  --branch=main \
  --path=clusters/staging \          # Define your cluster path to store source files which will trigger your charts, helmreleases.
  --personal \
  --components-extra=image-reflector-controller,image-automation-controller
# These are extra controllers used to automate image versions and policies.
```

### Step 2: Create Your Git Repository and Kustomization

Create a Git source:

```sh
flux create source git flux-automation \
  --url https://github.com/shahid430/flux-automation \
  --branch main \
  --timeout 10s \
  --export > security-source.yml
```

Create a Kustomization:

```sh
flux create kustomization \
  --source GitRepository/flux-automation \
  --prune true \
  --interval 10s \
  --target-namespace main \
  --path manifests/<deployment-name>.yml \
  --export > <ks-name>.yml
```

### Step 3: Create Your First HelmRelease

```sh
flux create hr kube-prometheus-stack \
  --chart=./manifests/dev/monitoring/kube-prometheus-stack \
  --interval=10s \
  --target-namespace=monitoring \
  --source=GitRepository/infra \
  --export > helmrelease-prometheus.yml
```

---

## Example: Helm Release Deployment Using Helm Repository

### Deploy Sealed-Secrets

Create HelmRepository source:

```sh
flux create source helm sealed-secrets \
  --interval=1m0s \
  --url="https://bitnami-labs.github.io/sealed-secrets" \
  --export > sealed-secrets-helmrepo.yml
```

Create HelmRelease:

```sh
flux create helmrelease sealed-secrets \
  --source=HelmRepository/sealed-secrets \
  --chart=sealed-secrets \
  --interval=1m0s \
  --target-namespace=sealed-secrets \
  --release-name=sealed-secrets \
  --export > sealed-secrets-helmrelease.yml
```
