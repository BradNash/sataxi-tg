locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "tfr:///cloudposse/security-group/aws?version=0.4.3"
}

dependency "data" {
  config_path = "${dirname(get_original_terragrunt_dir())}/data"
}

dependency "fargate_task_sg" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/fargate-task-sg"
}

dependency "batch_compute_sg" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/batch-compute-sg"
}

inputs = {
  vpc_id           = dependency.data.outputs.vpc_id
  description      = "Allows access to Fargate Tasks and Batch Jobs"
  attributes       = ["vpc-endpoints-sg-${local.env_vars.locals.environment}"]
  allow_all_egress = true

  rule_matrix = [{
    cidr_blocks               = []
    ipv6_cidr_blocks          = []
    source_security_group_ids = [dependency.fargate_task_sg.outputs.id, dependency.batch_compute_sg.outputs.id]

    rules = [
      {
        description = "Allows HTTPS traffic"
        protocol    = "tcp"
        type        = "ingress"
        from_port   = 443
        to_port     = 443
        self        = null
      }
    ]
  }]
}
