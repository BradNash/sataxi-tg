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
  repository_name = "insurance-service"
}

inputs = {
  source_repo_name                = local.repository_name
  source_repo_branch              = "master"
  source_repo_arn                 = "arn:aws:codecommit:eu-west-1:665316528893:sataxi-common"
  codebuild_environment_variables = include.pipelines_common.locals.codebuild_environment_variables
  additional_pipelines_stages = [
    {
      name = "Deploy"
      actions = [
        {
          name            = "Deploy-Sataxi-Common"
          namespace       = "sataxi-common-dev"
          category        = "Invoke"
          owner           = "AWS"
          version         = "1"
          provider        = "Lambda"
          run_order       = 1
          input_artifacts = ["BuildOutput"]
          configuration = {

          }
        },
      ]
    }
  ]
}
