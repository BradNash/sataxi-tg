include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/bbdsoftware/terraform-service-modules.git//aws-iam-role-and-policy?ref=main"
}

inputs = {
  name        = "codepipeline-deploy-lamdba-crossaccount-role"
  description = "Role for codepipeline lambda functions in dev account to assume"
  policy = {
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:ListTaskDefinitions",
          "ecs:DescribeTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:RunTask",
          "ecs:StopTask",
          "ecs:DescribeTasks",
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
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
        Action   = ["ssm:PutParameter"],
        Effect   = "Allow",
        Resource = "arn:aws:ssm:af-south-1:743730760644:parameter/prod/*"
      },
      {
        Action = [
          "batch:DescribeJobs",
          "batch:DescribeJobDefinitions",
          "batch:RegisterJobDefinition",
          "batch:DeregisterJobDefinition",
          "batch:SubmitJob",
          "batch:TagResource"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "events:ListTargetsByRule",
          "events:PutTargets"
        ],
        Resource = "*"
      }
    ]
  }
  assume_role_policy = {
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          "AWS" : "*" # TODO: Change to only allow lambdas
        }
        Effect = "Allow"
      }
    ]
  }
}
