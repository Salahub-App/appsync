###############################################################################
# Terraform: AppSync + Lambda Infrastructure (Bahrain Region)
#
# This creates:
#   - VPC with public/private subnets
#   - VPC Peering to Virginia (us-east-1)
#   - AppSync GraphQL API
#   - Lambda functions
#   - All necessary IAM roles and permissions
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "terraform-state-agentcore-147054060142"
    key            = "appsync/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.31.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.0"
    }
  }
}

# Primary provider - Bahrain
provider "aws" {
  region = var.aws_region
}

# Secondary provider - Virginia (for VPC peering accepter)
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}
