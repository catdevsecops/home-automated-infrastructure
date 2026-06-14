plugin "aws" {
  enabled = true
  version = "0.47.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "terraform" {
  enabled = true
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
  version = "0.15.0"
}

config {
  force               = false
  disabled_by_default = false
  call_module_type    = "all"
}

# Regras de Terraform
rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_unused_required_providers" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "terraform_workspace_remote" {
  enabled = true
}

# Regras de Nomeação
rule "terraform_naming_convention" {
  enabled = true

  variable {
    format = "snake_case"
  }

  locals {
    format = "snake_case"
  }

  output {
    format = "snake_case"
  }

  resource {
    format = "snake_case"
  }

  module {
    format = "snake_case"
  }

  type_definition {
    format = "snake_case"
  }
}

# Regras AWS
rule "aws_instance_default_security_group" {
  enabled = true
}

rule "aws_s3_bucket_acl" {
  enabled = true
}

rule "aws_s3_bucket_public_access_block" {
  enabled = true
}

rule "aws_iam_policy_no_statements_with_admin_access" {
  enabled = true
}

rule "aws_iam_role_managed_policy_attachment_on_role_with_inline_policy" {
  enabled = true
}

rule "aws_iam_policy_blacklist_check" {
  enabled = true
  blacklist = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
    "arn:aws:iam::aws:policy/PowerUserAccess"
  ]
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags    = ["Name", "Environment", "Owner", "CostCenter"]
  exclude = [
    "aws_security_group_rule",
    "aws_route",
    "aws_route_table_association",
  ]
}

rule "aws_kms_key_rotation_enabled" {
  enabled = true
}

rule "aws_rds_instance_publicly_accessible" {
  enabled = true
}

rule "aws_rds_instance_backup_retention_period_check" {
  enabled = true
}

rule "aws_s3_bucket_default_lock_enabled" {
  enabled = true
}

rule "aws_dynamodb_point_in_time_recovery_enabled" {
  enabled = true
}

rule "aws_db_instance_deletion_protection" {
  enabled = true
}

rule "aws_db_instance_encrypted" {
  enabled = true
}

rule "aws_security_group_rule_description_empty" {
  enabled = true
}

rule "aws_instance_ebs_encryption" {
  enabled = true
}

rule "aws_cloudtrail_log_file_validation_enabled" {
  enabled = true
}

rule "aws_elb_access_logs" {
  enabled = true
}

rule "aws_alb_access_logs" {
  enabled = true
}

# Regras de Estilo
rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_empty_list_equality" {
  enabled = true
}

rule "terraform_empty_map_equality" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_one_attribute_block_max_line_length" {
  enabled = true
  length  = 120
}

rule "terraform_max_line_length" {
  enabled = true
  length  = 120
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}
