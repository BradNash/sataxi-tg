locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  base_source_url = "git::https://github.com/bbdsoftware/terraform-service-modules.git//aws-iam-role-and-policy"
}

inputs = {
  name        = "eventbridge-batch-job-schedule-${local.env_vars.locals.environment}"
  description = "Role for EventBridge to schedule batch jobs with"
  policy = {
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "batch:SubmitJob",
        Resource = "*"
        Effect   = "Allow"
      }
    ]
  }
  assume_role_policy = {
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          "Service" : "events.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  }
}
