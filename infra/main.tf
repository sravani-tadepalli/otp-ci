terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
  }
}

provider "aws" {
  region = var.aws_region
}

module "otp" {
  source = "./modules/otp"

  # override defaults if you want
  dynamodb_table_name = "OtpTable"
  lambda_generate_zip = "lambda_src/lambda_generate.zip"
  lambda_verify_zip   = "lambda_src/lambda_verify.zip"

  otp_secret = var.otp_secret

  create_api = true

  tags = {
    Name      = "OtpStack"
    ManagedBy = "terraform"
  }
}
