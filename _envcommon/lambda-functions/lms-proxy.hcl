locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "git::https://github.com/bbdsoftware/terraform-service-modules.git//aws-lambda-function"
}

dependency "data" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/data"
}

dependency "lms_lambda_proxy_sg" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/lms-lambda-proxy-sg"
}

dependency "api_gateway" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/api-gateway"
}

inputs = {
  main_vpc_id   = dependency.data.outputs.vpc_id
  function_name = "lms-proxy-${local.env_vars.locals.environment}"
  description   = "Proxies request body through to insurance service"
  environment = {
    variables = {
      PROXY_URL = "http://insurance.vanguard.${local.env_vars.locals.environment}.sataxi.internal:8080/web_leads"
    }
  }
  filename  = "lms_proxy.py"
  directory = "${dirname(find_in_parent_folders())}/lambda/lms-proxy"
  handler   = "lms_proxy.lambda_handler"
  runtime   = "python3.9"
  vpc_config = {
    security_group_ids = [dependency.lms_lambda_proxy_sg.outputs.id]
    subnet_ids         = dependency.data.outputs.private_subnet_ids
  }
  execution_role_enabled = true
  execution_role_policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:af-south-1:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface"
        ],
        Resource = "*"
      }
    ]
  }
  execution_role_assume_role_policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  }
  execution_role_assume_role_path = "/service-role/"
  lambda_execution_permissions = [
    {
      statement_id   = "AllowAPIGatewayInvoke"
      action         = "lambda:InvokeFunction"
      principal      = "apigateway.amazonaws.com"
      source_arn     = "${dependency.api_gateway.outputs.execution_arn}/*/*/*"
      qualifier      = null
      source_account = null
    }
  ]
}
