locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars     = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-fargate-task-role"
}

dependency "postgres_rds_secrets" {
  config_path = "${dirname(get_original_terragrunt_dir())}/postgres-rds-secrets"
}

dependency "rabbit_mq_secrets" {
  config_path = "${dirname(get_original_terragrunt_dir())}/rabbit-mq-secrets"
}

inputs = {
  name = "sataxi-fargate-task-role-${local.env_vars.locals.environment}"
  policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetEncryptionConfiguration"]
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = [dependency.postgres_rds_secrets.outputs.secret_arn, dependency.rabbit_mq_secrets.outputs.secret_arn]
      },
      {
        Effect   = "Allow",
        Action   = ["ssm:GetParameters", "ssm:GetParameter"],
        Resource = "arn:aws:ssm:${local.region_vars.locals.aws_region}:${local.account_vars.locals.aws_account_id}:parameter/${local.env_vars.locals.environment}/*"
      },
      {
        Effect   = "Allow",
        Action   = ["logs:DescribeLogStreams"]
        Resource = "*"
      }
    ]
  }
}
