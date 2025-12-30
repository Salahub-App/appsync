###############################################################################
# GitHub Actions OIDC IAM Role for CI/CD
#
# This creates an IAM role that GitHub Actions can assume using OIDC.
# More secure than using AWS access keys - no credentials to rotate.
#
# Usage:
#   cd iam-github-oidc
#   terraform init
#   terraform apply
###############################################################################

terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "terraform-state-agentcore-147054060142"
    key            = "appsync-iam-github-oidc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

###############################################################################
# OIDC Identity Provider for GitHub
###############################################################################

# Check if OIDC provider already exists
data "aws_iam_openid_connect_provider" "github_existing" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = var.tags
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github_existing[0].arn
}

###############################################################################
# IAM Role for GitHub Actions
###############################################################################

resource "aws_iam_role" "github_actions" {
  name        = var.role_name
  description = "IAM role for GitHub Actions to deploy AppSync Bahrain infrastructure"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = var.tags
}

###############################################################################
# IAM Policies for the Role
###############################################################################

# Lambda Full Access
resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

# IAM Full Access (for creating roles, policies)
resource "aws_iam_role_policy_attachment" "iam" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

# S3 (for Terraform state)
resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# CloudWatch Logs
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# EC2 (for VPC, Security Groups, VPC Endpoints, VPC Peering)
resource "aws_iam_role_policy_attachment" "ec2" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# DynamoDB (for Terraform state lock)
resource "aws_iam_role_policy_attachment" "dynamodb" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# AppSync Full Access
resource "aws_iam_role_policy" "appsync" {
  name = "${var.role_name}-appsync"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AppSyncFullAccess"
        Effect = "Allow"
        Action = [
          "appsync:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Secrets Manager (for future use)
resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
