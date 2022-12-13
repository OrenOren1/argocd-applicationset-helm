
resource "kubernetes_namespace" "argocd" {
  metadata {
    annotations = {
      created-by = "terraform"
      "app.kubernetes.io/managed-by" = "Helm"
    }

    labels = {
      purpose = "ArgoCD-IAC"

    }

    name = "argocd"
  }
}

data "template_file" "values-override" {
  template = "${file("${path.module}/files/values-override.tpl")}"
  vars = {
    repo_name           = "${var.repo_name}"
    repo_url            = "${var.repo_url}"
    argo_ssh_key        = "${var.argo_ssh_key}"
    env_name            = "${var.env_name}"
    helm_repo           = "${var.main_repo}"
  }
}

resource "helm_release" "argocd-ecr-updater" {
  repository    = "files"
  name       = "argocd-ecr-updater"
  chart      = "argocd-ecr-updater"
  version    = "0.1.0"
  namespace  = kubernetes_namespace.argocd.metadata.0.name
  values = [
    file("${path.module}/files/argocd-ecr-updater/values.yaml")
  ]
  depends_on = [
    kubernetes_namespace.argocd
  ]
  lifecycle {
    ignore_changes = [
      status
    ]
    #argo secret pull from secret manager
  }
}
resource "helm_release" "argocd" {
  count      = var.install_argocd ? 1 : 0
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_version
  namespace  = kubernetes_namespace.argocd.metadata.0.name
  values     = [
    data.template_file.values-override.rendered
  ]
  depends_on = [
    kubernetes_namespace.argocd
  ]
  lifecycle {
    ignore_changes = [
      status
    ]
    #argo secret pull from secret manager
  }
}
data "aws_secretsmanager_secret" "argocd-github-ssh" {
  name = "argocd-github-ssh"
}

data "aws_secretsmanager_secret_version" "argocd-github-ssh" {
  secret_id = data.aws_secretsmanager_secret.argocd-github-ssh.id
}

locals {
  argocd_ssh_key_base64 = base64decode(data.aws_secretsmanager_secret_version.argocd-github-ssh.secret_string)
}



resource "kubernetes_secret" "github-repo-secret" {
  metadata {
    name      = "github-repo-secret"
    namespace = kubernetes_namespace.argocd.metadata.0.name

  }
  data = {
    sshPrivateKey = local.argocd_ssh_key_base64
  }
}

