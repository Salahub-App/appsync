###############################################################################
# Variables
###############################################################################

variable "aws_region" {
  description = "AWS region to deploy resources (Bahrain)"
  type        = string
  default     = "me-south-1"
}

variable "project_name" {
  description = "Project name (used for resource naming)"
  type        = string
  default     = "appsync-bahrain"
}

###############################################################################
# VPC Configuration
###############################################################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["me-south-1a", "me-south-1b"]
}

###############################################################################
# Virginia VPC Peering Configuration
###############################################################################

variable "virginia_vpc_id" {
  description = "VPC ID in Virginia (us-east-1) for peering"
  type        = string
}

variable "virginia_vpc_cidr" {
  description = "CIDR block of Virginia VPC"
  type        = string
  default     = "172.31.0.0/16"
}

variable "virginia_lambda_arn" {
  description = "ARN of the AI Lambda function in Virginia"
  type        = string
  default     = ""
}

variable "virginia_gateway_url" {
  description = "URL of the Bedrock AgentCore Gateway in Virginia"
  type        = string
  default     = ""
}

###############################################################################
# Lambda Configuration
###############################################################################

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 256
}

variable "log_level" {
  description = "Logging level for Lambda"
  type        = string
  default     = "INFO"
}

###############################################################################
# Tags
###############################################################################

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "appsync-bahrain"
    Environment = "dev"
    Region      = "bahrain"
    ManagedBy   = "terraform"
  }
}
