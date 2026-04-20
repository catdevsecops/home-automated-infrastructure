resource "aws_iam_user" "k8s_user" {
  name = "k8s-ssm-operator-user"
}

resource "aws_iam_access_key" "k8s_user_key" {
  user = aws_iam_user.k8s_user.name
}

resource "aws_iam_user_policy_attachment" "user_ssm_attach" {
  user       = aws_iam_user.k8s_user.name
  policy_arn = aws_iam_policy.ssm_read_policy.arn # Aquela política do passo anterior
}

resource "aws_iam_policy" "ssm_read_policy" {
  name        = "K8sSSMReadPolicy"
  path        = "/"
  description = "Permite leitura de parametros SSM sob o prefixo /k8s/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:DescribeParameters"
        ]
        Resource = [
          "arn:aws:ssm:*:*:parameter/k8s/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = ["*"]
      }
    ]
  })
}
