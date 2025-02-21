include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-ecr-repos?master"
}

inputs = {
  ecr_repo_names = [
    "sataxi/workflow-rest-service",
    "sataxi/case-management-service",
    "sataxi/reporting-service",
    "sataxi/workflow-importer",
    "sataxi/workflow-classification", # TODO: Delete -> Not used anymore
    "sataxi/identity-service",
    "sataxi/principal-service",
    "sataxi/content-store-service",
    "sataxi/front-end",
    "sataxi/accounts-service", # TODO: Delete -> Not used anymore
    "sataxi/hive-integration-service", # Depricated
    "sataxi/insurance-service",
    "sataxi/popi-integration-service",
    "sataxi/savana-integration-service", # Depricated
    "sataxi/telephony-service",
    "sataxi/vanguard-integration-service", # TODO: Delete -> Not used anymore
    "sataxi/base-python",
    "sataxi/base-python-postgres",
    "sataxi/base-python-sqlserver",
    "sataxi/finance-service",
    "sataxi/workflow-monitoring-batch",
    "sataxi/config-loader",
    "sataxi/workflow-extensions-service",
    "sataxi/reporting-batch",
    "swaggerapi/swagger-codegen-cli-v3",
    "si-gen/jportal2",
    "sataxi/correspondence-importer",
    "sataxi/zaka-leads-batch", # TODO: Delete -> Not used anymore
    "sataxi/vehicle-service",
    "sataxi/base-python-postgres-sqlserver",
    "sataxi/lms-leads-batch", # TODO: Delete -> Not used anymore
    "sataxi/workflow-event-node",
    "sataxi/python-tox",
    "sataxi/otel-collector",
    "sataxi/front-end-otel-collector",
    "sataxi/fluentbit",
    "flyway",
    "sataxi/sat-insurance-service",
    "sataxi/keycloak",
    "sataxi/workforce-case-priority-service",
    "sataxi/workforce-sla-service",
    "sataxi/workforce-teams-service",
    "gomo/insurance-service",
    "gomo/finance-service",
    "sataxi/escalations-batch",
    "sataxi/rewards-service",
  ]
  pull_through_cache_registries = [
    {
      ecr_repository_prefix = "ecr-public"
      upstream_registry_url = "public.ecr.aws"
    },
  ]
  ecr_repos_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "AllowPushPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": ["arn:aws:iam::665316528893:root", "arn:aws:iam::743730760644:root"]
      },
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ]
    }
  ]
}
EOF
}
