resource "helm_release" "this" {
  name             = "argo-cd"
  repository       = "oci://ghcr.io/argoproj/argo-helm"
  chart            = "argo-cd"
  version          = "9.5.2"
  namespace        = "argo"
  create_namespace = true


  values = [
    yamlencode({
      global = {
        tolerations = [
          {
            key      = "node-role.kubernetes.io/control-plane"
            operator = "Exists"
            effect   = "NoSchedule"
          }
        ]
        nodeSelector = {
          "node-role.kubernetes.io/control-plane" = ""
        }
      },
      "redis-ha" = {
        enabled = false
      },
      redis = {
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled   = true
            namespace = "prometheus"
          }
        }
      },
      controller = {
        replicas = 1
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled   = true
            namespace = "prometheus"
          }
        }
      },
      server = {
        replicas  = 1
        extraArgs = ["--insecure"]
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled   = true
            namespace = "prometheus"
          }
        }
      },
      repoServer = {
        replicas = 1
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled   = true
            namespace = "prometheus"
          }
        }
      },
      notifications = {
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled   = true
            namespace = "prometheus"
          }
        }
      },
      applicationSet = {
        replicas = 1
      }
      configs = {
        repositories = {
          home = {
            url           = "git@github.com:catdevsecops/home-automated-infrastructure.git"
            sshPrivateKey = aws_ssm_parameter.argocd_private_key.value
          }
        }
      }
    })
  ]
}

resource "aws_ssm_parameter" "argocd_private_key" {
  name  = "/argocd/private_key"
  type  = "SecureString"
  value = "secret"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
