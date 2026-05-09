resource "aws_ssm_parameter" "k8s_app_secret" {
  name        = "/k8s/home-assistant"
  description = "cloudflared info"
  type        = "SecureString"

  value = "secure"


  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}


resource "kubernetes_manifest" "home_assistant_external_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "home-assistant-token"
      namespace = "home-assistant"
    }
    spec = {
      refreshInterval = "12h"
      secretStoreRef = {
        name = "aws-ssm-store"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "home-assistant-token"
      }
      data = [
        {
          secretKey = "token"
          remoteRef = { key = "/k8s/home-assistant", property = "token" }
        },
      ]
    }
  }
}
