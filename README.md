CICD pipeline for minikube cluster on local machine:

1) Start a new Minikube cluster with specific resources and API server options
minikube start
--driver=docker \ # Use Docker as the VM driver --cpus=4 --memory=8192 \ # Allocate 4 vCPUs and 8GB RAM to the cluster --kubernetes-version=v1.31.0 \ # Specify Kubernetes version (change as needed) --extra-config=apiserver.authorization-mode=Node,RBAC \ # Enable Node & RBAC authorization modes --extra-config=apiserver.enable-admission-plugins=MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,LimitRanger,NamespaceLifecycle,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds \
# Enable key admission controllers in the API server --extra-config=apiserver.audit-log-path=/var/log/kube-apiserver-audit.log \ # Path for API server audit logs --extra-config=apiserver.audit-log-maxage=5 \ # Keep audit logs for 5 days --extra-config=apiserver.audit-log-maxsize=100 # Max size of each audit log file (MB)

2) Enable useful Minikube addons, these are optional based on your requirement.
minikube addons enable metrics-server # Metrics server for resource metrics (used by HPA, etc.) minikube addons enable dashboard # Kubernetes Dashboard UI minikube addons enable ingress # NGINX ingress controller minikube addons enable registry # Local Docker registry inside the cluster

3) Validate the cluster and addons
kubectl get nodes # Check that the Minikube node is ready kubectl get pods -A # Check that all system and addon pods are running minikube addons list | grep -E 'metrics-server|dashboard|ingress|registry' # Verify addons enabled Output:

| dashboard | minikube | disabled | Kubernetes | | ingress | minikube | disabled | Kubernetes | | ingress-dns | minikube | disabled | minikube | | metrics-server | minikube | disabled | Kubernetes | | registry | minikube | disabled | minikube | | registry-aliases | minikube | disabled | 3rd party (unknown) | | registry-creds | minikube | disabled | 3rd party (UPMC Enterprises) |

Check your minikube ip to use it for nodeport services. minikube ip # Get Minikube cluster IP
################## Completed Kubernetes cluster deployment ##################### Lets build the applications now with FluxCD automation.

#1) The first step in release automation is to install flux CRD's using below bootstrap commamnd:

flux bootstrap github
--token-auth
--owner=XXXXXXXXXXX \ # This is your github username --repository=flux-automation
--branch=main
--path=clusters/staging \ # Define your cluster path to store source files which will trigger your charts, helmreleases. --personal
--components-extra=image-reflector-controller,image-automation-controller # These are extra controllers which are used to automate the image versions, policies.

#2) Create your git repository along with kustomation to trigger git repo deployment.

flux create source git flux-automation
--url https://github.com/shahid430/flux-automation
--branch main
--timeout 10s
--export > security-source.yml

flux create kustomization
--source GitRepository/flux-automation
--prune true
--interval 10s
--target-namespace main
--path manifests/<deploymant-name.yml>
--export > <ks-name.yml>

#3) Create your first helmrelease:

flux create hr kube-prometheus-stack
--chart=./manifests/dev/monitoring/kube-prometheus-stack
--interval=10s
--target-namespace=monitoring
--source=GitRepository/infra
--export > helmrelease-prometheus.yml

EXAMPLE OF A HELM RELEASE DEPLOYMENT USING HELM REPOSITORY:

Deploy sealed-secrets
flux create source helm sealed-secrets
--interval=1m0s
--url="https://bitnami-labs.github.io/sealed-secrets"
--export > sealed-secrets-helmrepo.yml flux create helmrelease sealed-secrets
--source=HelmRepository/sealed-secrets
--chart=sealed-secrets
--interval=1m0s
--target-namespace=sealed-secrets
--release-name=sealed-secrets
--export > sealed-secrets-helmrelease.yml
