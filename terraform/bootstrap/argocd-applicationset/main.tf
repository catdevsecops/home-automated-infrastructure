resource "kubernetes_manifest" "argocd_applicationset" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "cluster-apps"
      namespace = "argo"
    }
    spec = {
      generators = [
        {
          git = {
            repoURL  = "git@github.com:catdevsecops/home-automated-infrastructure.git"
            revision = "HEAD"
            directories = [
              {
                path = "k8s/*/*"
              }
            ]
          }
        }
      ]
      template = {
        metadata = {
          name = "{{path[1]}}-{{path[2]}}"
        }
        spec = {
          project = "default"
          source = {
            repoURL        = "git@github.com:catdevsecops/home-automated-infrastructure.git"
            targetRevision = "HEAD"
            path           = "{{path}}"
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "{{path[1]}}"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = [
              "CreateNamespace=true"
            ]
          }
        }
      }
    }
  }
}
