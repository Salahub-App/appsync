# Bahrain Dev Environment Configuration

# Project Configuration
project_name = "appsync-bahrain"
aws_region   = "me-south-1"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
availability_zones   = ["me-south-1a", "me-south-1b"]

# Virginia VPC Peering Configuration
virginia_vpc_id   = "vpc-096d3a73d142945f5"
virginia_vpc_cidr = "172.31.0.0/16"

# Virginia AI Infrastructure
virginia_lambda_arn  = "arn:aws:lambda:us-east-1:147054060142:function:order-agent-tool"
virginia_gateway_url = "https://gateway.bedrock.us-east-1.amazonaws.com/gateways/"

# Lambda Configuration
lambda_timeout = 30
lambda_memory  = 256
log_level      = "INFO"

# Tags
tags = {
  Project     = "appsync-bahrain"
  Environment = "dev"
  Region      = "bahrain"
  ManagedBy   = "terraform"
}
