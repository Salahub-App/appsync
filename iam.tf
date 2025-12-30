###############################################################################
# IAM Roles and Policies
###############################################################################

###############################################################################
# Lambda Execution Role
###############################################################################

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# Lambda Basic Execution Policy (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda VPC Execution Policy
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda Additional Permissions
resource "aws_iam_role_policy" "lambda_additional" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Cross-region Lambda invocation (Virginia)
      {
        Sid    = "InvokeVirginiaLambda"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          "arn:aws:lambda:us-east-1:${local.account_id}:function:*"
        ]
      },
      # Bedrock AgentCore Gateway invocation (Virginia)
      {
        Sid    = "BedrockAgentCoreInvoke"
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:InvokeGateway"
        ]
        Resource = [
          "arn:aws:bedrock-agentcore:us-east-1:${local.account_id}:gateway/*"
        ]
      },
      # Bedrock model invocation (if needed directly)
      {
        Sid    = "BedrockModelInvoke"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:us-east-1::foundation-model/*",
          "arn:aws:bedrock:${var.aws_region}::foundation-model/*"
        ]
      },
      # Secrets Manager (for future use)
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${local.account_id}:secret:${var.project_name}-*"
        ]
      }
    ]
  })
}

###############################################################################
# AppSync CloudWatch Logs Role
###############################################################################

resource "aws_iam_role" "appsync_logs" {
  name = "${var.project_name}-appsync-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "appsync.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "appsync_logs" {
  role       = aws_iam_role.appsync_logs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppSyncPushToCloudWatchLogs"
}

###############################################################################
# AppSync Data Source Role (to invoke Lambda)
###############################################################################

resource "aws_iam_role" "appsync_datasource" {
  name = "${var.project_name}-appsync-datasource-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "appsync.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "appsync_invoke_lambda" {
  name = "${var.project_name}-appsync-invoke-lambda"
  role = aws_iam_role.appsync_datasource.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [
        aws_lambda_function.appsync_resolver.arn,
        "${aws_lambda_function.appsync_resolver.arn}:*",
        aws_lambda_function.ai_proxy.arn,
        "${aws_lambda_function.ai_proxy.arn}:*"
      ]
    }]
  })
}
