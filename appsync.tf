###############################################################################
# AppSync GraphQL API
###############################################################################

resource "aws_appsync_graphql_api" "main" {
  name                = "${var.project_name}-api"
  authentication_type = "API_KEY"

  schema = <<-SCHEMA
    type Query {
      # Get AI response from Virginia AI services
      getAIResponse(prompt: String!): AIResponse

      # Search knowledge base
      searchKnowledgeBase(query: String!, limit: Int): KBSearchResult

      # Health check
      healthCheck: HealthCheckResponse
    }

    type Mutation {
      # Process a booking request
      processBooking(input: BookingInput!): BookingResponse

      # Send a chat message to AI
      chat(message: String!, sessionId: String): ChatResponse
    }

    type AIResponse {
      response: String!
      model: String
      processingTime: Float
    }

    type KBSearchResult {
      results: [KBItem]
      total: Int
    }

    type KBItem {
      id: String
      content: String
      score: Float
      metadata: String
    }

    type HealthCheckResponse {
      status: String!
      region: String!
      timestamp: String!
      services: ServiceStatus
    }

    type ServiceStatus {
      lambda: String
      vpc: String
      virginiaConnection: String
    }

    input BookingInput {
      brand: String!
      branch: String
      date: String
      time: String
      guests: Int
      customerName: String
      customerPhone: String
      notes: String
    }

    type BookingResponse {
      success: Boolean!
      bookingId: String
      message: String
      details: BookingDetails
    }

    type BookingDetails {
      brand: String
      branch: String
      date: String
      time: String
      confirmationCode: String
    }

    type ChatResponse {
      response: String!
      sessionId: String
      toolsUsed: [String]
    }
  SCHEMA

  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync_logs.arn
    field_log_level          = "ALL"
  }

  tags = var.tags
}

###############################################################################
# API Key
###############################################################################

resource "aws_appsync_api_key" "main" {
  api_id  = aws_appsync_graphql_api.main.id
  expires = timeadd(timestamp(), "8760h") # 1 year

  lifecycle {
    ignore_changes = [expires]
  }
}

###############################################################################
# Data Sources
###############################################################################

# Lambda Data Source - Main Resolver
resource "aws_appsync_datasource" "lambda_resolver" {
  api_id           = aws_appsync_graphql_api.main.id
  name             = "LambdaResolver"
  type             = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.appsync_datasource.arn

  lambda_config {
    function_arn = aws_lambda_function.appsync_resolver.arn
  }
}

# Lambda Data Source - AI Proxy
resource "aws_appsync_datasource" "ai_proxy" {
  api_id           = aws_appsync_graphql_api.main.id
  name             = "AIProxyLambda"
  type             = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.appsync_datasource.arn

  lambda_config {
    function_arn = aws_lambda_function.ai_proxy.arn
  }
}

###############################################################################
# Resolvers - Queries
###############################################################################

# Get AI Response Resolver
resource "aws_appsync_resolver" "get_ai_response" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Query"
  field       = "getAIResponse"
  data_source = aws_appsync_datasource.ai_proxy.name

  request_template = <<-EOF
    {
      "version": "2017-02-28",
      "operation": "Invoke",
      "payload": {
        "field": "getAIResponse",
        "arguments": $util.toJson($ctx.arguments)
      }
    }
  EOF

  response_template = "$util.toJson($ctx.result)"
}

# Search Knowledge Base Resolver
resource "aws_appsync_resolver" "search_kb" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Query"
  field       = "searchKnowledgeBase"
  data_source = aws_appsync_datasource.ai_proxy.name

  request_template = <<-EOF
    {
      "version": "2017-02-28",
      "operation": "Invoke",
      "payload": {
        "field": "searchKnowledgeBase",
        "arguments": $util.toJson($ctx.arguments)
      }
    }
  EOF

  response_template = "$util.toJson($ctx.result)"
}

# Health Check Resolver
resource "aws_appsync_resolver" "health_check" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Query"
  field       = "healthCheck"
  data_source = aws_appsync_datasource.lambda_resolver.name

  request_template = <<-EOF
    {
      "version": "2017-02-28",
      "operation": "Invoke",
      "payload": {
        "field": "healthCheck",
        "arguments": $util.toJson($ctx.arguments)
      }
    }
  EOF

  response_template = "$util.toJson($ctx.result)"
}

###############################################################################
# Resolvers - Mutations
###############################################################################

# Process Booking Resolver
resource "aws_appsync_resolver" "process_booking" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Mutation"
  field       = "processBooking"
  data_source = aws_appsync_datasource.ai_proxy.name

  request_template = <<-EOF
    {
      "version": "2017-02-28",
      "operation": "Invoke",
      "payload": {
        "field": "processBooking",
        "arguments": $util.toJson($ctx.arguments)
      }
    }
  EOF

  response_template = "$util.toJson($ctx.result)"
}

# Chat Resolver
resource "aws_appsync_resolver" "chat" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Mutation"
  field       = "chat"
  data_source = aws_appsync_datasource.ai_proxy.name

  request_template = <<-EOF
    {
      "version": "2017-02-28",
      "operation": "Invoke",
      "payload": {
        "field": "chat",
        "arguments": $util.toJson($ctx.arguments)
      }
    }
  EOF

  response_template = "$util.toJson($ctx.result)"
}
