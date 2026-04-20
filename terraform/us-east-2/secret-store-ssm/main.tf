resource "kubernetes_manifest" "aws_ssm_credentials" {
  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "aws-ssm-creds"
      namespace = "external-secrets"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }

    type = "Opaque"
    data = {
      access_key = data.terraform_remote_state.operator.outputs.access_ssm_operator_id
      secret_key = data.terraform_remote_state.operator.outputs.access_ssm_operator_key
    }
  }
}

resource "kubernetes_manifest" "aws_ssm_secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "SecretStore"
    metadata = {
      name      = "aws-ssm-store"
      namespace = "external-secrets" # Onde o operador está instalado
    }
    spec = {
      provider = {
        aws = {
          service = "ParameterStore"
          region  = "us-east-2" # Altere para a sua região da AWS
          auth = {
            secretRef = {
              # Referência às chaves que criamos no Secret anterior
              accessKeyIDSecretRef = {
                name      = "aws-ssm-creds"
                key       = "access_key"
                namespace = "external-secrets" # Namespace onde o Secret foi criado
              }
              secretAccessKeySecretRef = {
                name      = "aws-ssm-creds"
                key       = "secret_key"
                namespace = "external-secrets" # Namespace onde o Secret foi criado
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.aws_ssm_credentials]
}
