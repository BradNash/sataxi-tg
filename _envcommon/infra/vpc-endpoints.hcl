locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "git::https://github.com/bbdsoftware/terraform-service-modules.git//aws-vpc-endpoints"
}

dependency "data" {
  config_path = "${dirname(get_original_terragrunt_dir())}/data"
}

dependency "vpc_endpoints_sg" {
  config_path = "${dirname(get_original_terragrunt_dir())}/vpc-endpoints-sg"
}

inputs = {
  vpc_id             = dependency.data.outputs.vpc_id
  security_group_ids = [dependency.vpc_endpoints_sg.outputs.id]
  endpoints = {
    ecr_api = {
      service             = "ecr.api"
      service_type        = "Interface"
      subnet_ids          = dependency.data.outputs.private_subnet_ids
      private_dns_enabled = true
      tags                = { Name = "ecr-api-vpc-endpoint-${local.env_vars.locals.environment}" }
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      service_type        = "Interface"
      subnet_ids          = dependency.data.outputs.private_subnet_ids
      private_dns_enabled = true
      tags                = { Name = "ecr-dkr-vpc-endpoint-${local.env_vars.locals.environment}" }
    }
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = dependency.data.outputs.private_route_table_ids
      tags            = { Name = "s3-vpc-endpoint-${local.env_vars.locals.environment}" }
      policy = jsonencode({
        Version = "2008-10-17"
        "Statement" : [
          {
            "Action" : "*",
            "Effect" : "Allow",
            "Resource" : "*",
            "Principal" : "*"
          }
        ]
      })
    },
    ssm = {
      service             = "ssm"
      service_type        = "Interface"
      subnet_ids          = dependency.data.outputs.private_subnet_ids
      private_dns_enabled = true
      tags                = { Name = "ssm-vpc-endpoint-${local.env_vars.locals.environment}" }
    }
    cw_logs = {
      service             = "logs"
      service_type        = "Interface"
      subnet_ids          = dependency.data.outputs.private_subnet_ids
      private_dns_enabled = true
      tags                = { Name = "cloudwatch-vpc-endpoint-${local.env_vars.locals.environment}" }
    }
    ec2_messages = {
      service             = "ec2messages"
      service_type        = "Interface"
      subnet_ids          = dependency.data.outputs.private_subnet_ids
      private_dns_enabled = true
      tags                = { Name = "ec2-msg-vpc-endpoint-${local.env_vars.locals.environment}" }
    }
    ssm_messages = {
      service             = "ssmmessages"
      service_type        = "Interface"
      subnet_ids          = dependency.data.outputs.private_subnet_ids
      private_dns_enabled = true
      tags                = { Name = "ssm-msg-vpc-endpoint-${local.env_vars.locals.environment}" }
    }
    xray = {
      service             = "xray"
      service_type        = "Interface"
      subnet_ids          = dependency.data.outputs.private_subnet_ids
      private_dns_enabled = true
      tags                = { Name = "xray-msg-vpc-endpoint-${local.env_vars.locals.environment}" }
    }
    secrets_manager = {
      service             = "secretsmanager"
      service_type        = "Interface"
      subnet_ids          = dependency.data.outputs.private_subnet_ids
      private_dns_enabled = true
      tags                = { Name = "secretsmanager-vpc-endpoint-${local.env_vars.locals.environment}" }
    }
  }
}
