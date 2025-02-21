locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-batch-job"
}

dependency "fargate_task_execution_role" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/fargate-task-execution-role"
}

dependency "eventbridge_submit_job_role" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/eventbridge-submit-job-role"
}

dependency "batch_compute_environment" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/batch-compute-environment"
}


inputs = {
  name                      = "rewards-escalations"
  environment               = local.env_vars.locals.environment
  execution_role_arn        = dependency.fargate_task_execution_role.outputs.role_arn
  enable_cron_scheduling    = true
  schedule_expression       = "cron(25 07 ? * MON-FRI *)"
  batch_submit_job_role_arn = dependency.eventbridge_submit_job_role.outputs.role_arn
  batch_queue_arn           = dependency.batch_compute_environment.outputs.batch_queue_arn
}
