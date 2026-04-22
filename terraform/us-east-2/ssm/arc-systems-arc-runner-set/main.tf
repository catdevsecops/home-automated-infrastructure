resource "aws_ssm_parameter" "k8s_app_secret" {
  name        = "/k8s/arc-runner-set"
  description = "actions runner controller info"
  type        = "SecureString"

  value = "secure"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}


resource "kubernetes_manifest" "actions_runner_external_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "arc-runner-set-secret"
      namespace = "arc-systems"
    }
    spec = {
      refreshInterval = "12h"
      secretStoreRef = {
        name = "aws-ssm-store"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "github-app-secret"
      }
      data = [
        {
          secretKey = "github_app_id"
          remoteRef = { key = "/k8s/arc-runner-set", property = "github_app_id" }
        },
        {
          secretKey = "github_app_installation_id"
          remoteRef = { key = "/k8s/arc-runner-set", property = "github_app_installation_id" }
        },
        {
          secretKey = "github_app_private_key"
          remoteRef = { key = "/k8s/arc-runner-set", property = "github_app_private_key" }
        }
      ]
    }
  }
}
