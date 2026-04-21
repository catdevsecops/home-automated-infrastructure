resource "aws_ssm_parameter" "k8s_app_secret" {
  name        = "/k8s/cloudflared"
  description = "cloudflared info"
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
      name      = "cloudflare-tunnel-secret"
      namespace = "cloudflare"
    }
    spec = {
      refreshInterval = "12h"
      secretStoreRef = {
        name = "aws-ssm-store"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "cloudflare-tunnel-secret"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "TunnelID"
          remoteRef = {
            key      = "/k8s/cloudflared"
            property = "TunnelID"
          }
        },
        {
          secretKey = "TunnelSecret"
          remoteRef = {
            key      = "/k8s/cloudflared"
            property = "TunnelSecret"
          }
        }
      ]
    }
  }
}
