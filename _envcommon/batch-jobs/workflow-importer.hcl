locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-batch-job"
}

dependency "fargate_task_execution_role" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../infra/fargate-task-execution-role"
}

inputs = {
  name               = "workflow-importer"
  environment        = local.env_vars.locals.environment
  execution_role_arn = dependency.fargate_task_execution_role.outputs.role_arn
}
