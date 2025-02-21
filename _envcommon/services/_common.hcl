locals {
  env_vars            = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars         = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  account_vars        = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  services_common_env = read_terragrunt_config(find_in_parent_folders("_common.hcl"))
  base_source_url     = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-fargate-service"
}

dependency "data" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/data"
}

dependency "fargate_cluster" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/fargate-cluster"
}

dependency "fargate_task_sg" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/fargate-task-sg"
}

dependency "fargate_task_execution_role" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/fargate-task-execution-role"
}

dependency "fargate_task_role" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/fargate-task-role"
}

dependency "fargate_service_discovery_namespace" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/fargate-service-discovery-namespace"
}

dependency "fargate_private_alb_listener" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/fargate-private-alb-listener"
}

dependency "sns_topic_alarm_notification" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/sns-topic-alarm-notification"
}

dependency "lambda_proxy_sg" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/lambda-proxy-sg"
}

inputs = {
  environment                       = "${local.env_vars.locals.environment}"
  vpc_id                            = dependency.data.outputs.vpc_id
  subnets                           = dependency.data.outputs.private_subnet_ids
  fargate_cluster_name              = dependency.fargate_cluster.outputs.cluster_name
  fargate_task_sg_id                = dependency.fargate_task_sg.outputs.id
  fargate_task_execution_role_arn   = dependency.fargate_task_execution_role.outputs.role_arn
  fargate_task_role_arn             = dependency.fargate_task_role.outputs.role_arn
  service_discovery_ns_id           = dependency.fargate_service_discovery_namespace.outputs.id
  lb_listner_arn                    = dependency.fargate_private_alb_listener.outputs.vanguard_lb_listner_arn
  cpu                               = 256
  memory                            = 512
  cpu_utilization_low_alarm_actions = [dependency.sns_topic_alarm_notification.outputs.sns_topic.arn]
  # TODO: Check if any manual setup required on sns topic??
  cpu_utilization_high_alarm_actions    = [dependency.sns_topic_alarm_notification.outputs.sns_topic.arn]
  memory_utilization_high_alarm_actions = [dependency.sns_topic_alarm_notification.outputs.sns_topic.arn]
  memory_utilization_low_alarm_actions  = [dependency.sns_topic_alarm_notification.outputs.sns_topic.arn]
  capacity_provider                     = local.services_common_env.locals.capacity_provider
  health_check_interval                 = local.env_vars.locals.environment != "prod" ? 60 : 30
  service_parent_domain                 = local.env_vars.locals.environment != "prod" ? "${local.env_vars.locals.environment}.sataxi-cloud.co.za" : "sataxi-cloud.co.za"
  service_internal_domain               = "vanguard.${local.env_vars.locals.environment}.sataxi.internal"
  lambda_proxy_sg_id                    = dependency.lambda_proxy_sg.outputs.id
  api_gateway_execution_arn             = "arn:aws:execute-api:${local.region_vars.locals.aws_region}:${local.account_vars.locals.aws_account_id}:*"
  enable_execute_command                = true
  tags = {
    "map-migrated" = "d-server-03carvz5colf02"
  }
}
