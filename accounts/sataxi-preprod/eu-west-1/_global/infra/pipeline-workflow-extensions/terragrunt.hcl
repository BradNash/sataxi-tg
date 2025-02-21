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
  repository_name = "workflow-extensions-service"
}

inputs = {
  source_repo_name                = local.repository_name
  source_repo_branch              = "master"
  source_repo_arn                 = "arn:aws:codecommit:eu-west-1:665316528893:workflow-extensions-service"
  codebuild_environment_variables = include.pipelines_common.locals.codebuild_environment_variables
  additional_pipelines_stages = [
    {
      name = "Deploy-DEV"
      actions = [
        {
          name            = "Deploy-Workflow-Extensions-Service"
          namespace       = "workflow-extensions-dev"
          category        = "Invoke"
          owner           = "AWS"
          version         = "1"
          provider        = "Lambda"
          run_order       = 1
          input_artifacts = ["BuildOutput"]
          configuration = {
            FunctionName = dependency.ecs_service_deploy_lambda.outputs.lambda_function_name
            UserParameters = jsonencode({
              CLUSTER_NAME              = "vanguard-fargate-cluster-dev",
              SERVICE_NAME              = "workflow-extensions",
              ENV                       = "dev"
              TASK_DEFINITION_FILE_PATH = "deploy/workflow-extensions-service/dev/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/workflow-extensions-service/dev/config.yaml"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
            })
          }
        },
        {
          name            = "Deploy-Escalations-Batch"
          namespace       = "rewards-escalations-dev"
          category        = "Invoke"
          owner           = "AWS"
          version         = "1"
          provider        = "Lambda"
          run_order       = 1
          input_artifacts = ["BuildOutput"]
          configuration = {
            FunctionName = dependency.batch_job_deploy_lambda.outputs.lambda_function_name
            UserParameters = jsonencode({
              JOB_QUEUE                      = "sataxi-batch-queue-dev"
              JOB_DEFINITION                 = "rewards-escalations-batch-dev"
              CONTAINER_PROPERTIES_FILE_PATH = "deploy/escalations-batch/dev/container-properties.yaml",
              REPOSITORY_NAME                = local.repository_name
              COMMIT_HASH                    = "#{build.COMMIT_HASH}"
              IMAGE_TAG                      = "#{build.IMAGE_TAG}"
              CRON_SCHEDULING_ENABLED        = true
            })
          }
        }
      ]
    },
    {
      name = "QA-Approval"
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
      name = "Deploy-QA"
      actions = [
        {
          name            = "Deploy-Workflow-Extensions-Service"
          namespace       = "workflow-extensions-qa"
          category        = "Invoke"
          owner           = "AWS"
          version         = "1"
          provider        = "Lambda"
          run_order       = 1
          input_artifacts = ["BuildOutput"]
          configuration = {
            FunctionName = dependency.ecs_service_deploy_lambda.outputs.lambda_function_name
            UserParameters = jsonencode({
              CLUSTER_NAME              = "vanguard-fargate-cluster-qa",
              SERVICE_NAME              = "workflow-extensions",
              ENV                       = "qa"
              TASK_DEFINITION_FILE_PATH = "deploy/workflow-extensions-service/qa/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/workflow-extensions-service/qa/config.yaml"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
            })
          }
        },
        {
          name            = "Deploy-Escalations-Batch"
          namespace       = "rewards-escalations-qa"
          category        = "Invoke"
          owner           = "AWS"
          version         = "1"
          provider        = "Lambda"
          run_order       = 1
          input_artifacts = ["BuildOutput"]
          configuration = {
            FunctionName = dependency.batch_job_deploy_lambda.outputs.lambda_function_name
            UserParameters = jsonencode({
              JOB_QUEUE                      = "sataxi-batch-queue-qa"
              JOB_DEFINITION                 = "rewards-escalations-batch-qa"
              CONTAINER_PROPERTIES_FILE_PATH = "deploy/escalations-batch/qa/container-properties.yaml",
              REPOSITORY_NAME                = local.repository_name
              COMMIT_HASH                    = "#{build.COMMIT_HASH}"
              IMAGE_TAG                      = "#{build.IMAGE_TAG}"
              CRON_SCHEDULING_ENABLED        = true
            })
          }
        }
      ]
    },
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
          name            = "Deploy-Workflow-Extensions-Service"
          namespace       = "workflow-extensions-prod"
          category        = "Invoke"
          owner           = "AWS"
          version         = "1"
          provider        = "Lambda"
          run_order       = 1
          input_artifacts = ["BuildOutput"]
          configuration = {
            FunctionName = dependency.ecs_service_deploy_prod_lambda.outputs.lambda_function_name
            UserParameters = jsonencode({
              CLUSTER_NAME              = "vanguard-fargate-cluster-prod",
              SERVICE_NAME              = "workflow-extensions",
              ENV                       = "prod"
              TASK_DEFINITION_FILE_PATH = "deploy/workflow-extensions-service/prod/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/workflow-extensions-service/prod/config.yaml"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
            })
          }
        },
        {
          name            = "Deploy-Escalations-Batch"
          namespace       = "rewards-escalations-prod"
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
              JOB_DEFINITION                 = "rewards-escalations-batch-prod"
              CONTAINER_PROPERTIES_FILE_PATH = "deploy/escalations-batch/prod/container-properties.yaml",
              REPOSITORY_NAME                = local.repository_name
              COMMIT_HASH                    = "#{build.COMMIT_HASH}"
              IMAGE_TAG                      = "#{build.IMAGE_TAG}"
              CRON_SCHEDULING_ENABLED        = true
            })
          }
        }
      ]
    }
  ]
}
