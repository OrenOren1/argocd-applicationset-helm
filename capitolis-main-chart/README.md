# tikal ArgoCD
## Confluence directory:
https://tikal.atlassian.net/wiki/spaces/DEP/pages/2880995343/ArgoCD
## What is Argo CD?

Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes.

## Documentation

To learn more about Argo CD [go to the complete documentation](https://argoproj.github.io/argo-cd/).
Check live demo at https://cd.apps.argoproj.io/.

## New env Installation

ArgoCD should be automatically installed on each cluster via Terraform (v2)

1. first make sure that there is in the `secrets manager` ssh private key in the project with the name `argocd/github-ssh`, this will give ArgoCD the ability to pull local repos
> Currently, this key is in eu-west-1 (this is the ssh private key from the Jenkins server)
> Terraform already installs external-secrets to automatically add the ssh key as a secret for ArgoCD

There are two ways to authenticate against ArgoCD
  1. SSO - see valery for more info
  2. Local users
## ArgoCD initial Admin password

1. To get Initial Admin Password
   ArgoCD on creation creates an initial admin password, once change this password is irrelevant
   to retrieve this password please run the next command
```bash
  # Get the first password
  kubectl get secrets -n argocd argocd-initial-admin-secret -o json | jq -r '.data.password' | base64 -d
```

2. now if you want to change local admin password please install ArgoCD CLI tool
```bash
  brew tap argoproj/tap
  brew install argoproj/tap/argocd
```


3. now access the cluster via cli
```bash
  # login to the cluster
  argocd login <ARGOCD_SERVER_url>
  # And change the admin password
  argocd account update-password
```
> If using SSO you can just disable local admin [ArgoCD-cm](helm/infra/templates/custom_resources/argocd-cm.yaml) and have everyone connect only via sso

Now you should have access to the cluster via UI

## New cluster (once per cluster)
If you have a new cluster

1. go to `argocd/app-of-apps`
2. copy one of the yaml files and change its name and contents to the name of the new cluster (i.e `cp qa2.yaml <new_cluster_name>`.yaml)
3. copy a dir and replace configurations based on new envs name (i.e `cp -r qa2 <new_cluster_name>`)
   1. in `infra.yaml` you can choose which users have access and to where, and cluster specific things such as role ARNs and acm arn and sso configurations
   2. in `apps.yaml` you just point to the cluster dir in `argocd/envs/<new_cluster_name>`

## Adding a new namespace ##
To add a new namespace:

1. go to the Desired envs dir - `cd argocd/envs/<desired_env>/`
2. copy one of the files to a new file with the name `<new_namespace_name>.yaml` and change values inside to represent new namespace
3. now `cp argocd/base/values.yaml argocd/envs/states/values-<new_namespace_name>.yaml` applications in base in the new `values-<new_namespace_name>.yaml` # this is the highest and third values override, this overrides the values in argoApp
> Need to verify that db schema is created and available or the pods will crash

## Adding a new Micro-Service
To add a new Micro-Service please follow the following steps

1. Create your new service in the main Helm chart:
   ```bash
   cd helm/apps/<Directory>/<service-name>/
   touch values.yaml
   # Example: cd helm/apps/common/oren-service/values.yaml
   # Copy an already created service, so you'll have the template.
   ```
2. Add the new <service>.yaml files under a couple of directories:
   ```bash
   cd argocd/base/templates/argocdApps-<Directory>/
   touch <service-name>.yaml
   # Example: cd argocd/base/templates/argocdApps-common/oren-service.yaml
   # Again copy from an already created service, and modify to your service.
   ```
3. Add the service to the file: 
   ```bash
   argocd/base/values.yaml
   # Copy from a previous service.
   ```
5. Add the new service to the correct environment.yaml
   ```bash
   cd argocd/envs/states
   # Choose the correct environment, Example: values-edge2-tikal.yaml
   # Add your service and enable it (Copy from a previous service)
   # You can add the service to other envs too, and just disable it.
   # when you'll want to deploy you'll just need to enable.
   ```


## Argocd endpoint
 * Url: `https://argocd-<cluster-name>.tikal.com/applications`
 * User: admin
 * Pass: [initial-password](#argocd-initial-admin-password) / or sso
