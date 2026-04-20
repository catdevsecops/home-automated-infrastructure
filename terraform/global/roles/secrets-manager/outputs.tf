output "access_ssm_operator_id" {
  value = aws_iam_access_key.k8s_user_key.id
}

output "access_ssm_operator_key" {
  sensitive = true
  value     = aws_iam_access_key.k8s_user_key.secret
}
