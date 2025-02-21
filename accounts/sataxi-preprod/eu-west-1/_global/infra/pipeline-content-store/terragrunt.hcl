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
  repository_name = "bbd-services-contentstore"
}

inputs = {
  source_repo_name                = local.repository_name
  source_repo_branch              = "master"
  source_repo_arn                 = "arn:aws:codecommit:eu-west-1:665316528893:bbd-services-contentstore"
  codebuild_environment_variables = include.pipelines_common.locals.codebuild_environment_variables
  additional_pipelines_stages = [
    {
      name = "Deploy-DEV"
      actions = [
        {
          name            = "Deploy-Content-Store-Service"
          namespace       = "content-store-dev"
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
              SERVICE_NAME              = "content-store",
              ENV                       = "dev"
              TASK_DEFINITION_FILE_PATH = "deploy/content-store-service/dev/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/content-store-service/dev/config.yaml"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
            })
          }
        },
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
          name            = "Deploy-Content-Store-Service"
          namespace       = "content-store-qa"
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
              SERVICE_NAME              = "content-store",
              ENV                       = "qa"
              TASK_DEFINITION_FILE_PATH = "deploy/content-store-service/qa/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/content-store-service/qa/config.yaml"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
            })
          }
        },
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
          name            = "Deploy-Content-Store-Service"
          namespace       = "content-store-prod"
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
              SERVICE_NAME              = "content-store",
              ENV                       = "prod"
              TASK_DEFINITION_FILE_PATH = "deploy/content-store-service/prod/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/content-store-service/prod/config.yaml"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
            })
          }
        },
      ]
    },
  ]
}
