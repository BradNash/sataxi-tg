locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//sataxi-api-gateway"
}

dependency "sat_insurance_service" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../services/sat-insurance"
}

dependency "insurance_service" {
  config_path = "${dirname(get_original_terragrunt_dir())}/../services/insurance"
}

inputs = {
  api_gw_name = "sataxi-api-gateway-${local.env_vars.locals.environment}"
  environment = local.env_vars.locals.environment

  api_key_names = ["zapier", "bot"]

  open_api_spec = {
    openapi = "3.0.1"
    info = {
      title   = "SA Taxi ${local.env_vars.locals.environment} API"
      version = "1.0.0"
    }

    components = {
      securitySchemes = {
        api_key = {
          type = "apiKey"
          name = "x-api-key"
          in   = "header"
        }
      }
    }

    paths = {
      "/insurance_premium/{proxy+}" = {
        post = {
          security = [
            {
              api_key = []
            }
          ]
          x-amazon-apigateway-integration = {
            payloadFormatVersion = "1.0"
            httpMethod           = "POST"
            type                 = "AWS_PROXY"
            uri                  = dependency.sat_insurance_service.outputs.lambda_proxy_invoke_arn
          }
        }
      }
      "/insurance/{proxy+}" = {
        post = {
          security = [
            {
              api_key = []
            }
          ]
          x-amazon-apigateway-integration = {
            payloadFormatVersion = "1.0"
            httpMethod           = "POST"
            type                 = "AWS_PROXY"
            uri                  = dependency.insurance_service.outputs.lambda_proxy_invoke_arn
          }
        }
      }
    }
  }

  tags = {
    "map-migrated" = "d-server-03carvz5colf02"
  }
}
