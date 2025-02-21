locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  base_source_url = "tfr:///cloudposse/security-group/aws?version=1.0.1"
}

dependency "data" {
  config_path = "${dirname(get_original_terragrunt_dir())}/data"
}

dependency "fargate_private_alb_sg" {
  config_path = "${dirname(get_original_terragrunt_dir())}/fargate-private-alb-sg"
}

dependency "lambda_proxy_sg" {
  config_path = "${dirname(get_original_terragrunt_dir())}/lambda-proxy-sg"
}

inputs = {
  vpc_id           = dependency.data.outputs.vpc_id
  description      = "Allows access to Fargate Tasks"
  attributes       = ["fargate-task-sg-${local.env_vars.locals.environment}"]
  allow_all_egress = true


  rule_matrix = [{
    cidr_blocks               = []
    ipv6_cidr_blocks          = []
    source_security_group_ids = [dependency.fargate_private_alb_sg.outputs.id, dependency.lambda_proxy_sg.outputs.id]

    rules = [
      {
        description = "Allows TCP traffic on port 8080"
        protocol    = "tcp"
        type        = "ingress"
        from_port   = 8080
        to_port     = 8080
        self        = true
      },
      {
        description = "Allows TCP traffic on port 80"
        protocol    = "tcp"
        type        = "ingress"
        from_port   = 80
        to_port     = 80
        self        = true
      },
      {
        description = "Allows TCP traffic on port 4318 for otel collector"
        protocol    = "tcp"
        type        = "ingress"
        from_port   = 4318
        to_port     = 4318
        self        = true
      },
      {
        description = "Allows TCP traffic on port 13133 for otel collector health checks"
        protocol    = "tcp"
        type        = "ingress"
        from_port   = 13133
        to_port     = 13133
        self        = true
      }
    ]
  }]
}
