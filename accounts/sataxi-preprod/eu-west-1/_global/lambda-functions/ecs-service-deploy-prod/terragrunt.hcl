include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/bbdsoftware/terraform-service-modules.git//aws-lambda-function?ref=main"
}

inputs = {
  function_name = "ecs-service-deploy-prod-lambda"
  filename      = "index.js"
  directory     = "${dirname(find_in_parent_folders())}/lambda/ecs-service-deploy"
  handler       = "index.handler"
  timeout       = 10 * 60
  runtime       = "nodejs22.x"
  environment = {
    variables = {
      CROSS_ACCOUNT_ROLE_ARN = "arn:aws:iam::743730760644:role/codepipeline-deploy-lamdba-crossaccount-role" # TODO: Use dependency
    }
  }
  execution_role_enabled = true
  execution_role_policy = {
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:*"
        ],
        Resource = "arn:aws:logs:*:*:*" # TODO: Check if needed?
      },
      {
        Sid    = "PassExecutionRole",
        Effect = "Allow",
        Action = [
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:PassRole",
          "iam:SimulatePrincipalPolicy"
        ],
        Resource = "*"
      },
      {
        Action = [
          "codepipeline:PutJobSuccessResult",
          "codepipeline:PutJobFailureResult"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "codecommit:GetFile",
          "codecommit:GetBranch",
          "codecommit:GetCommit",
        ],
        Effect   = "Allow",
        Resource = "arn:aws:codecommit:eu-west-1:665316528893:*"
      },
      {
        Action   = ["sts:AssumeRole"],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  }
  execution_role_assume_role_policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  }
  execution_role_assume_role_path = "/service-role/"

  tags = {
    "map-migrated" = "d-server-03carvz5colf02"
  }
}
