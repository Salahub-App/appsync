###############################################################################
# Outputs
###############################################################################

###############################################################################
# VPC Outputs
###############################################################################

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

###############################################################################
# VPC Peering Outputs
###############################################################################

output "vpc_peering_id" {
  description = "VPC Peering Connection ID"
  value       = aws_vpc_peering_connection.bahrain_to_virginia.id
}

output "vpc_peering_status" {
  description = "VPC Peering Connection Status"
  value       = aws_vpc_peering_connection.bahrain_to_virginia.accept_status
}

###############################################################################
# Lambda Outputs
###############################################################################

output "resolver_lambda_arn" {
  description = "AppSync Resolver Lambda ARN"
  value       = aws_lambda_function.appsync_resolver.arn
}

output "ai_proxy_lambda_arn" {
  description = "AI Proxy Lambda ARN"
  value       = aws_lambda_function.ai_proxy.arn
}

###############################################################################
# AppSync Outputs
###############################################################################

output "appsync_api_id" {
  description = "AppSync API ID"
  value       = aws_appsync_graphql_api.main.id
}

output "appsync_api_url" {
  description = "AppSync GraphQL API URL"
  value       = aws_appsync_graphql_api.main.uris["GRAPHQL"]
}

output "appsync_api_key" {
  description = "AppSync API Key"
  value       = aws_appsync_api_key.main.key
  sensitive   = true
}

###############################################################################
# IAM Outputs
###############################################################################

output "lambda_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_role.arn
}

###############################################################################
# Summary Output
###############################################################################

output "deployment_summary" {
  description = "Deployment summary and next steps"
  value       = <<-EOT

    ════════════════════════════════════════════════════════════════
    APPSYNC BAHRAIN - DEPLOYMENT COMPLETE
    ════════════════════════════════════════════════════════════════

    Region:           ${var.aws_region}
    VPC:              ${aws_vpc.main.id} (${var.vpc_cidr})
    VPC Peering:      ${aws_vpc_peering_connection.bahrain_to_virginia.id}

    ────────────────────────────────────────────────────────────────
    APPSYNC GRAPHQL API
    ────────────────────────────────────────────────────────────────

    API URL:          ${aws_appsync_graphql_api.main.uris["GRAPHQL"]}
    API ID:           ${aws_appsync_graphql_api.main.id}

    ────────────────────────────────────────────────────────────────
    LAMBDA FUNCTIONS
    ────────────────────────────────────────────────────────────────

    Resolver:         ${aws_lambda_function.appsync_resolver.function_name}
    AI Proxy:         ${aws_lambda_function.ai_proxy.function_name}

    ────────────────────────────────────────────────────────────────
    USAGE EXAMPLE
    ────────────────────────────────────────────────────────────────

    # Health Check Query
    curl -X POST ${aws_appsync_graphql_api.main.uris["GRAPHQL"]} \
      -H "Content-Type: application/json" \
      -H "x-api-key: <API_KEY>" \
      -d '{"query": "{ healthCheck { status region timestamp } }"}'

    # AI Query
    curl -X POST ${aws_appsync_graphql_api.main.uris["GRAPHQL"]} \
      -H "Content-Type: application/json" \
      -H "x-api-key: <API_KEY>" \
      -d '{"query": "{ getAIResponse(prompt: \"Hello\") { response } }"}'

    ────────────────────────────────────────────────────────────────
    TROUBLESHOOTING
    ────────────────────────────────────────────────────────────────

    # Check Lambda logs
    aws logs tail /aws/lambda/${aws_lambda_function.appsync_resolver.function_name} --follow --region ${var.aws_region}

    # Test VPC Peering
    aws ec2 describe-vpc-peering-connections --vpc-peering-connection-ids ${aws_vpc_peering_connection.bahrain_to_virginia.id}

    ════════════════════════════════════════════════════════════════

  EOT
}
