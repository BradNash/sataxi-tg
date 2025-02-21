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
  repository_name = "sataxi-vanguard-ui"
}

inputs = {
  source_repo_name   = local.repository_name
  source_repo_branch = "master"
  source_repo_arn    = "arn:aws:codecommit:eu-west-1:665316528893:sataxi-vanguard-ui"
  codebuild_environment_variables = concat(include.pipelines_common.locals.codebuild_environment_variables, [
    {
      name  = "NPM_USER"
      value = "/cicd/npm/npm_username"
      type  = "PARAMETER_STORE"
    },
    {
      name  = "NPM_PASS"
      value = "/cicd/npm/npm_password"
      type  = "PARAMETER_STORE"
    },
    {
      name  = "NPM_EMAIL"
      value = "/cicd/npm/npm_email"
      type  = "PARAMETER_STORE"
    }
  ])
  additional_pipelines_stages = [
    {
      name = "Deploy-DEV"
      actions = [
        {
          name            = "Deploy-Front-End"
          namespace       = "front-end-dev"
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
              SERVICE_NAME              = "front-end",
              ENV                       = "dev"
              TASK_DEFINITION_FILE_PATH = "deploy/front-end/dev/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/front-end/dev/app.config.json"
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
          name            = "Deploy-Front-End"
          namespace       = "front-end-qa"
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
              SERVICE_NAME              = "front-end",
              ENV                       = "qa"
              TASK_DEFINITION_FILE_PATH = "deploy/front-end/qa/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/front-end/qa/app.config.json"
              REPOSITORY_NAME           = local.repository_name
              COMMIT_HASH               = "#{build.COMMIT_HASH}"
              IMAGE_TAG                 = "#{build.IMAGE_TAG}"
            })
          }
        },
      ]
    },
    {
      name = "PRE-PROD-Approval"
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
      name = "Deploy-PRE-PROD"
      actions = [
        {
          name            = "Deploy-Pre-Front-End"
          namespace       = "pre-front-end-prod"
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
              SERVICE_NAME              = "pre-front-end",
              ENV                       = "prod"
              TASK_DEFINITION_FILE_PATH = "deploy/front-end/prod/pre-task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/front-end/prod/app.config.json"
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
          name            = "Deploy-Front-End"
          namespace       = "front-end-prod"
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
              SERVICE_NAME              = "front-end",
              ENV                       = "prod"
              TASK_DEFINITION_FILE_PATH = "deploy/front-end/prod/task-definition.yaml"
              CONFIG_FILE_PATH          = "deploy/front-end/prod/app.config.json"
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
