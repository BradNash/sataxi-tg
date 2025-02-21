include "root" {
  path = find_in_parent_folders()
}

include "pipelines_common" {
  path   = "../pipelines-common.hcl"
  expose = true
}

terraform {
  source = "${include.pipelines_common.locals.base_source_url}?ref=master"
}

locals {
  repository_name = "sataxi-workflow-importer"
}

inputs = {
  source_repo_name                = local.repository_name
  source_repo_branch              = "master"
  source_repo_arn                 = "arn:aws:codecommit:af-south-1:743730760644:sataxi-workflow-importer"
  codebuild_environment_variables = include.pipelines_common.locals.codebuild_environment_variables
  additional_pipelines_stages = [
    {
      name = "PROD-Approval"
      actions = [
        {
          name     = "Approval"
          category = "Approval"
          owner    = "AWS"
          provider = "Manual"
          version  = "1"
        }
      ]
    },
    {
      name = "Deploy-PROD"
      actions = [
        {
          name            = "Deploy-Workflow-Importer-Batch"
          namespace       = "workflow-importer-batch-prod"
          category        = "Invoke"
          owner           = "AWS"
          version         = "1"
          provider        = "Lambda"
          run_order       = 1
          input_artifacts = ["BuildOutput"]
          configuration = {
            FunctionName = dependency.batch_job_deploy_prod_lambda.outputs.lambda_function_name
            UserParameters = jsonencode({
              JOB_QUEUE                      = "sataxi-batch-queue-prod"
              JOB_DEFINITION                 = "workflow-importer-batch-prod"
              CONTAINER_PROPERTIES_FILE_PATH = "deploy/workflow-importer-batch/prod/container-properties.yaml",
              REPOSITORY_NAME                = local.repository_name
              COMMIT_HASH                    = "#{build.COMMIT_HASH}"
              IMAGE_TAG                      = "#{build.IMAGE_TAG}"
            })
          }
        },
        {
          name            = "Bounce-Workflow-Rest-Service"
          namespace       = "bounce-workflow-rest-service-prod"
          category        = "Invoke"
          owner           = "AWS"
          version         = "1"
          provider        = "Lambda"
          run_order       = 2
          input_artifacts = ["BuildOutput"]
          configuration = {
            FunctionName = dependency.ecs_stop_service_tasks_lambda_prod.outputs.lambda_function_name
            UserParameters = jsonencode({
              CLUSTER_NAME = "vanguard-fargate-cluster-prod",
              SERVICE_NAME = "workflow-rest",
              ENV          = "prod"
            })
          }
        },
        {
          name            = "Bounce-WF-Monitoring-Batch"
          namespace       = "bounce-wf-monitoring-batch-prod"
          category        = "Invoke"
          owner           = "AWS"
          version         = "1"
          provider        = "Lambda"
          run_order       = 2
          input_artifacts = ["BuildOutput"]
          configuration = {
            FunctionName = dependency.ecs_stop_service_tasks_lambda_prod.outputs.lambda_function_name
            UserParameters = jsonencode({
              CLUSTER_NAME = "vanguard-fargate-cluster-prod",
              SERVICE_NAME = "wf-monitoring-batch",
              ENV          = "prod"
            })
          }
        },
      ]
    },
  ]
}
