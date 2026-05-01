# 1. Manifesto do Service Account
resource "kubernetes_manifest" "arc_runner_admin_sa" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "ServiceAccount"
    "metadata" = {
      "name"      = "arc-runner-admin-sa"
      "namespace" = "arc-systems"

      "labels" = {
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
  }
}

# 2. Manifesto do ClusterRoleBinding
resource "kubernetes_manifest" "arc_runner_admin_binding" {
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "ClusterRoleBinding"
    "metadata" = {
      "name" = "arc-runner-admin-binding"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind"     = "ClusterRole"
      "name"     = "cluster-admin"
    }
    "subjects" = [
      {
        "kind"      = "ServiceAccount"
        "name"      = "arc-runner-admin-sa"
        "namespace" = "arc-systems"
      }
    ]
  }

  # Garante que o SA seja criado antes do Binding para evitar erros de consistência
  depends_on = [kubernetes_manifest.arc_runner_admin_sa]
}
