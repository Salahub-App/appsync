###############################################################################
# Variables
###############################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "me-south-1"
}

variable "role_name" {
  description = "Name of the IAM role for GitHub Actions"
  type        = string
  default     = "github-actions-appsync-bahrain"
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
  default     = "Salahub-App"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "appsync"
}

variable "create_oidc_provider" {
  description = "Whether to create the OIDC provider (set to false if it already exists)"
  type        = bool
  default     = false # Set to false since AI repo likely already created it
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project   = "appsync-bahrain"
    ManagedBy = "terraform"
    Purpose   = "github-actions-cicd"
  }
}
