resource "aws_ssm_parameter" "k8s_app_secret" {
  name        = "/k8s/traefik"
  description = "cloudflare token info"
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


resource "kubernetes_manifest" "cloudflare_external_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "cloudflare-api-token"
      namespace = "traefik"
    }
    spec = {
      refreshInterval = "12h"
      secretStoreRef = {
        name = "aws-ssm-store"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "cloudflare-api-token"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "token"
          remoteRef = { key = "/k8s/traefik", property = "token" }
        },
      ]
    }
  }
}
