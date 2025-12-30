###############################################################################
# Lambda Functions
###############################################################################

# Zip the Lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/.build/lambda.zip"
}

###############################################################################
# AppSync Resolver Lambda
###############################################################################

resource "aws_lambda_function" "appsync_resolver" {
  function_name    = "${var.project_name}-resolver"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory

  role = aws_iam_role.lambda_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      LOG_LEVEL    = var.log_level
      PROJECT_NAME = var.project_name
      REGION       = var.aws_region
    }
  }

  tags = merge(var.tags, {
    Function = "appsync-resolver"
  })
}

# Lambda permission for AppSync
resource "aws_lambda_permission" "appsync_resolver" {
  statement_id  = "AllowAppSyncInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.appsync_resolver.function_name
  principal     = "appsync.amazonaws.com"
  source_arn    = "${aws_appsync_graphql_api.main.arn}/*"
}

###############################################################################
# AI Proxy Lambda (communicates with Virginia)
###############################################################################

resource "aws_lambda_function" "ai_proxy" {
  function_name    = "${var.project_name}-ai-proxy"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler          = "ai_proxy.lambda_handler"
  runtime          = "python3.12"
  timeout          = 120 # Longer timeout for AI calls
  memory_size      = 512

  role = aws_iam_role.lambda_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      LOG_LEVEL            = var.log_level
      PROJECT_NAME         = var.project_name
      REGION               = var.aws_region
      VIRGINIA_LAMBDA_ARN  = var.virginia_lambda_arn
      VIRGINIA_GATEWAY_URL = var.virginia_gateway_url
    }
  }

  tags = merge(var.tags, {
    Function = "ai-proxy"
  })
}

# Lambda permission for AppSync
resource "aws_lambda_permission" "ai_proxy" {
  statement_id  = "AllowAppSyncInvokeAIProxy"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ai_proxy.function_name
  principal     = "appsync.amazonaws.com"
  source_arn    = "${aws_appsync_graphql_api.main.arn}/*"
}

###############################################################################
# CloudWatch Log Groups
###############################################################################

resource "aws_cloudwatch_log_group" "resolver" {
  name              = "/aws/lambda/${aws_lambda_function.appsync_resolver.function_name}"
  retention_in_days = 14

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "ai_proxy" {
  name              = "/aws/lambda/${aws_lambda_function.ai_proxy.function_name}"
  retention_in_days = 14

  tags = var.tags
}
