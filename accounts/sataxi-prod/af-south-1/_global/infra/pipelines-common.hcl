dependency "ecs_service_deploy_lambda" {
  config_path = "${dirname(get_terragrunt_dir())}/../lambda-functions/ecs-service-deploy"
}

dependency "ecs_service_deploy_prod_lambda" {
  config_path = "${dirname(get_terragrunt_dir())}/../lambda-functions/ecs-service-deploy-prod"
}

dependency "ecs_stop_service_tasks_lambda" {
  config_path = "${dirname(get_terragrunt_dir())}/../lambda-functions/ecs-stop-service-tasks"
}

dependency "ecs_stop_service_tasks_lambda_prod" {
  config_path = "${dirname(get_terragrunt_dir())}/../lambda-functions/ecs-stop-service-tasks-prod"
}

dependency "batch_job_deploy_lambda" {
  config_path = "${dirname(get_terragrunt_dir())}/../lambda-functions/batch-job-deploy"
}

dependency "batch_job_deploy_prod_lambda" {
  config_path = "${dirname(get_terragrunt_dir())}/../lambda-functions/batch-job-deploy-prod"
}

dependency "s3_codepipeline_artifacts" {
  config_path = "${dirname(get_terragrunt_dir())}/s3-codepipeline-artifacts"
}

locals {
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-codepipeline"
  codebuild_environment_variables = [
    {
      name  = "ECR_REGISTRY_URI"
      value = "761183306127.dkr.ecr.af-south-1.amazonaws.com"
      type  = "PLAINTEXT"
    }
  ]
}

inputs = {
  artifact_bucket_name = dependency.s3_codepipeline_artifacts.outputs.bucket_id
  codebuild_iam_policy = {
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["ecr:*"],
        Effect   = "Allow",
        Resource = ["*"]
      },
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:GetBucketVersioning"
        ],
        Effect   = "Allow",
        Resource = "${dependency.s3_codepipeline_artifacts.outputs.bucket_arn}/*" # TODO: Use dependency - NEEDED????
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = ["ssm:GetParameters", "ssm:GetParameter"],
        Effect = "Allow",
        Resource = [
          "arn:aws:ssm:af-south-1:743730760644:parameter/cicd/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "codeartifact:GetAuthorizationToken",
          "codeartifact:GetRepositoryEndpoint",
          "codeartifact:ReadFromRepository"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "sts:GetServiceBearerToken",
        Resource = "*",
        Condition = {
          "StringEquals" : {
            "sts:AWSServiceName" : "codeartifact.amazonaws.com"
          }
        }
      },
      {
        Effect   = "Allow",
        Action   = "codeartifact:PublishPackageVersion",
        Resource = "*",
      }
    ]
  }
  codepipeline_iam_policy = {
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ecs:*"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:GetBucketVersioning"
        ],
        Effect   = "Allow",
        Resource = "${dependency.s3_codepipeline_artifacts.outputs.bucket_arn}/*" # TODO: Use dependency
      },
      {
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
          "cloudformation:*",
          "iam:PassRole"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "codecommit:CancelUploadArchive",
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:UploadArchive"
        ],
        Effect   = "Allow",
        Resource = "*" # TODO: Use dependency somehow
      },
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction"
        ],
        Resource = "*" # TODO: Change to ecs deploy lambda arn
      }
    ]
  }

  tags = {
    "map-migrated" = "d-server-03carvz5colf02"
  }
}
