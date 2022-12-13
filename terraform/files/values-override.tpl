controller:
  # If changing the number of replicas you must pass the number as ARGOCD_CONTROLLER_REPLICAS as an environment variable
  replicas: 2
  enableStatefulSet: true


  env:
    - name: "ARGOCD_CONTROLLER_REPLICAS"
      value: "2"
resources:
  limits:
    cpu: 4M
    memory: 4Gi
  requests:
    cpu: 3M
    memory: 3Gi

## Redis
redis:
  enabled: false

redis-ha:
  enabled: true
  # Check the redis-ha chart for more properties
  resources:
    requests:
      memory: 200Mi
      cpu: 100m
    limits:
      memory: 700Mi
  exporter:
    enabled: false

server:
  serviceAccount:
    # -- Create server service account
    create: true
    # -- Server service account name
    name: argocd-server
    # -- Annotations applied to created service account
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::607827849963:role/argocd-get-oci-access-sultan
    # -- Labels applied to created service account
    labels: {}
    # -- Automount API credentials for the Service Account
    automountServiceAccountToken: true

  replicas: 2
  configEnabled: true
  config:
     repositories: |-
       - name: ${repo_name}
         type: git
         url: ${repo_url}
         sshPrivateKeySecret:
           key: sshPrivateKey
           name: github-repo-secret
       - name: sonatype
         type: helm
         url: https://sonatype.github.io/helm3-charts/
       - name: eks
         type: helm
         url: https://aws.github.io/eks-charts
       - name: autoscaler
         type: helm
         url: https://kubernetes.github.io/autoscaler
       - name: external-secrets
         type: helm
         url: https://external-secrets.github.io/kubernetes-external-secrets/
       - name: bitnami
         type: helm
         url: https://charts.bitnami.com/bitnami


  ## Projects
  ## reference: https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/
  additionalProjects:
  - name: tikal
    namespace: argocd
    description: tikal Project
    sourceRepos:
    - "*"
    destinations:
    - namespace: "*"
      server: https://kubernetes.default.svc
    clusterResourceWhitelist:
    - group: '*'
      kind: '*'
    namespaceResourceWhitelist:
    - group: '*'
      kind: '*'

  additionalApplications:
    - name: app-of-apps
      namespace: argocd
      labels:
        group: ${env_name}
      project: tikal
      source:
        repoURL: git@github.com:tikal/tikal_helm_deploy
        path: argocd/app-of-apps
        targetRevision: ${env_name}
      destination:
        server: https://kubernetes.default.svc
        namespace: argocd
      syncPolicy:
        syncOptions:
          - CreateNamespace=true
        automated:
          prune: true
          selfHeal: true
repoServer:
    ## Repo server service account
    ## If create is set to true, make sure to uncomment the name and update the rbac section below
    serviceAccount:
      # -- Create repo server service account
      create: true
      # -- Repo server service account name
      name: "argocd-repo-server"
      # -- Annotations applied to created service account
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::607827849963:role/argocd-get-oci-access-sultan
      labels: { }
      # -- Automount API credentials for the Service Account
      automountServiceAccountToken: true

    # -- Additional containers to be added to the repo server pod
    extraContainers: [ ]

    # -- Repo server rbac rules
    rbac:
     - apiGroups:
       - argoproj.io
       resources:
       - applications
       verbs:
       - get
       - list
       - watch
