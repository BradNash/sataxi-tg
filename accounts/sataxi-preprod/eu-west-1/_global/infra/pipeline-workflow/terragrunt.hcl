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
  repository_name = "workflow-rest-service"
}

inputs = {
  source_repo_name                = local.repository_name
  source_repo_branch              = "master"
  source_repo_arn                 = "arn:aws:codecommit:eu-west-1:665316528893:workflow-rest-service"
  codebuild_environment_variables = include.pipelines_common.locals.codebuild_environment_variables
  additional_pipelines_stages = [
    {
      name = "Deploy-DEV"
      actions = [
        {
          name            = "Deploy-Workflow-Rest-Service"
          namespace       = "workflow-rest-dev"
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
              SERVICE_NAME              = "workflow-rest",
              ENV                       = "dev"
              TASK_DEFINITION_FILE_PATH = "deploy/workflow-rest-service/dev/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/workflow-rest-service/dev/config.yaml"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
            })
          }
        },
        {
          name            = "Deploy-Case-Management-Service"
          namespace       = "case-management-dev"
          category        = "Invoke"
          owner           = "AWS"
          version         = "1"
          provider        = "Lambda"
          run_order       = 2
          input_artifacts = ["BuildOutput"]
          configuration = {
            FunctionName = dependency.ecs_service_deploy_lambda.outputs.lambda_function_name
            UserParameters = jsonencode({
              CLUSTER_NAME              = "vanguard-fargate-cluster-dev",
              SERVICE_NAME              = "case-management",
              ENV                       = "dev"
              TASK_DEFINITION_FILE_PATH = "deploy/case-management-service/dev/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/case-management-service/dev/config.yaml"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
            })
          }
        },
        {
          name            = "Deploy-WF-Monitoring-Batch"
          namespace       = "wf-monitoring-batch-dev"
          category        = "Invoke"
          owner           = "AWS"
          version         = "1"
          provider        = "Lambda"
          run_order       = 2
          input_artifacts = ["BuildOutput"]
          configuration = {
            FunctionName = dependency.ecs_service_deploy_lambda.outputs.lambda_function_name
            UserParameters = jsonencode({
              CLUSTER_NAME              = "vanguard-fargate-cluster-dev",
              SERVICE_NAME              = "wf-monitoring-batch",
              ENV                       = "dev"
              TASK_DEFINITION_FILE_PATH = "deploy/wf-monitoring-batch/dev/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/wf-monitoring-batch/dev/config.yaml"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
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
          name            = "Deploy-Workflow-Rest-Service"
          namespace       = "workflow-rest-qa"
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
              SERVICE_NAME              = "workflow-rest",
              ENV                       = "qa"
              TASK_DEFINITION_FILE_PATH = "deploy/workflow-rest-service/qa/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/workflow-rest-service/qa/config.yaml"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
            })
          }
        },
        {
          name            = "Deploy-Case-Management-Service"
          namespace       = "case-management-qa"
          category        = "Invoke"
          owner           = "AWS"
          version         = "1"
          provider        = "Lambda"
          run_order       = 2
          input_artifacts = ["BuildOutput"]
          configuration = {
            FunctionName = dependency.ecs_service_deploy_lambda.outputs.lambda_function_name
            UserParameters = jsonencode({
              CLUSTER_NAME              = "vanguard-fargate-cluster-qa",
              SERVICE_NAME              = "case-management",
              ENV                       = "qa"
              TASK_DEFINITION_FILE_PATH = "deploy/case-management-service/qa/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/case-management-service/qa/config.yaml"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
            })
          }
        },
        {
          name            = "Deploy-WF-Monitoring-Batch"
          namespace       = "wf-monitoring-batch-qa"
          category        = "Invoke"
          owner           = "AWS"
          version         = "1"
          provider        = "Lambda"
          run_order       = 2
          input_artifacts = ["BuildOutput"]
          configuration = {
            FunctionName = dependency.ecs_service_deploy_lambda.outputs.lambda_function_name
            UserParameters = jsonencode({
              CLUSTER_NAME              = "vanguard-fargate-cluster-qa",
              SERVICE_NAME              = "wf-monitoring-batch",
              ENV                       = "qa"
              TASK_DEFINITION_FILE_PATH = "deploy/wf-monitoring-batch/qa/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/wf-monitoring-batch/qa/config.yaml"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
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
          name            = "Deploy-Workflow-Rest-Service"
          namespace       = "workflow-rest-prod"
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
              SERVICE_NAME              = "workflow-rest",
              ENV                       = "prod"
              TASK_DEFINITION_FILE_PATH = "deploy/workflow-rest-service/prod/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/workflow-rest-service/prod/config.yaml"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
            })
          }
        },
        {
          name            = "Deploy-Case-Management-Service"
          namespace       = "case-management-prod"
          category        = "Invoke"
          owner           = "AWS"
          version         = "1"
          provider        = "Lambda"
          run_order       = 2
          input_artifacts = ["BuildOutput"]
          configuration = {
            FunctionName = dependency.ecs_service_deploy_prod_lambda.outputs.lambda_function_name
            UserParameters = jsonencode({
              CLUSTER_NAME              = "vanguard-fargate-cluster-prod",
              SERVICE_NAME              = "case-management",
              ENV                       = "prod"
              TASK_DEFINITION_FILE_PATH = "deploy/case-management-service/prod/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/case-management-service/prod/config.yaml"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
            })
          }
        },
        {
          name            = "Deploy-WF-Monitoring-Batch"
          namespace       = "wf-monitoring-batch-prod"
          category        = "Invoke"
          owner           = "AWS"
          version         = "1"
          provider        = "Lambda"
          run_order       = 2
          input_artifacts = ["BuildOutput"]
          configuration = {
            FunctionName = dependency.ecs_service_deploy_prod_lambda.outputs.lambda_function_name
            UserParameters = jsonencode({
              CLUSTER_NAME              = "vanguard-fargate-cluster-prod",
              SERVICE_NAME              = "wf-monitoring-batch",
              ENV                       = "prod"
              TASK_DEFINITION_FILE_PATH = "deploy/wf-monitoring-batch/prod/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/wf-monitoring-batch/prod/config.yaml"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
            })
          }
        }
      ]
    },
  ]
}
