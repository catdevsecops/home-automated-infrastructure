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
      controller = {
        replicas = 1
      },
      server = {
        replicas  = 1
        extraArgs = ["--insecure"]
      },
      repoServer = {
        replicas = 1
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
