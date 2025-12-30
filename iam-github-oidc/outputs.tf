###############################################################################
# Outputs
###############################################################################

output "role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.github_actions.name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = local.oidc_provider_arn
}

output "github_secret_instructions" {
  description = "Instructions for adding the secret to GitHub"
  value       = <<-EOT

    ════════════════════════════════════════════════════════════════
    ADD THIS SECRET TO GITHUB
    ════════════════════════════════════════════════════════════════

    1. Go to: https://github.com/${var.github_org}/${var.github_repo}/settings/secrets/actions

    2. Click "New repository secret"

    3. Add the following:
       - Name:  AWS_ROLE_ARN
       - Value: ${aws_iam_role.github_actions.arn}

    4. For production (if separate role needed):
       - Name:  AWS_ROLE_ARN_PROD
       - Value: <production-role-arn>

    ════════════════════════════════════════════════════════════════

  EOT
}
