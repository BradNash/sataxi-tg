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
  source_repo_arn    = "arn:aws:codecommit:af-south-1:743730760644:sataxi-vanguard-ui"
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
