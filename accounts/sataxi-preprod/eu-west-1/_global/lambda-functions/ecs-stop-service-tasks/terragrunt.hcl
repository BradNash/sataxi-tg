include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/bbdsoftware/terraform-service-modules.git//aws-lambda-function?ref=main"
}

inputs = {
  function_name          = "ecs-stop-service-tasks-lambda"
  filename               = "index.js"
  directory              = "${dirname(find_in_parent_folders())}/lambda/ecs-stop-service-tasks"
  handler                = "index.handler"
  timeout                = 10 * 60
  runtime                = "nodejs22.x"
  execution_role_enabled = true
  execution_role_policy = {
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:*"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:StopTask",
          "ecs:ListTasks"
        ],
        Resource = "*"
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
