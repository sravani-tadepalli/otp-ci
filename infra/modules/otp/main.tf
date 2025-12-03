########################
# DynamoDB table
########################
resource "aws_dynamodb_table" "otp_table" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.dynamodb_hash_key

  attribute {
    name = var.dynamodb_hash_key
    type = "S"
  }

  ttl {
    attribute_name = var.dynamodb_ttl_attribute
    enabled        = var.dynamodb_ttl_enabled
  }

  tags = var.tags
}

########################
# IAM Role for Lambda
########################
resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Scoped policy to allow basic DynamoDB operations on this table
resource "aws_iam_policy" "lambda_dynamo_policy" {
  name        = "${var.lambda_role_name}-dynamo-policy"
  description = "Allow Lambda to read/write OTP items to the table ${aws_dynamodb_table.otp_table.name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.otp_table.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_dynamo_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamo_policy.arn
}

# Allow logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

########################
# Lambda: Generate OTP
########################
resource "aws_lambda_function" "otp_generate" {
  function_name = var.lambda_generate_name
  role          = aws_iam_role.lambda_role.arn
  handler       = var.lambda_generate_handler
  runtime       = var.lambda_runtime

  filename         = var.lambda_generate_zip
  source_code_hash = filebase64sha256(var.lambda_generate_zip)

  environment {
    variables = merge(
      {
        DYNAMODB_TABLE  = aws_dynamodb_table.otp_table.name
        OTP_TTL_SECONDS = tostring(var.otp_ttl_seconds)
        OTP_SECRET      = var.otp_secret
      },
      var.extra_environment_variables
    )
  }

  tags = var.tags
}

########################
# Lambda: Verify OTP
########################
resource "aws_lambda_function" "otp_verify" {
  function_name = var.lambda_verify_name
  role          = aws_iam_role.lambda_role.arn
  handler       = var.lambda_verify_handler
  runtime       = var.lambda_runtime

  filename         = var.lambda_verify_zip
  source_code_hash = filebase64sha256(var.lambda_verify_zip)

  environment {
    variables = merge(
      {
        DYNAMODB_TABLE  = aws_dynamodb_table.otp_table.name
        OTP_SECRET      = var.otp_secret
      },
      var.extra_environment_variables
    )
  }

  tags = var.tags
}

########################
# Optional HTTP API (API Gateway v2) and integrations
########################
resource "aws_apigatewayv2_api" "otp_api" {
  count         = var.create_api ? 1 : 0
  name          = var.api_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "generate_integration" {
  count                  = var.create_api ? 1 : 0
  api_id                 = aws_apigatewayv2_api.otp_api[0].id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.otp_generate.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "verify_integration" {
  count                  = var.create_api ? 1 : 0
  api_id                 = aws_apigatewayv2_api.otp_api[0].id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.otp_verify.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "generate_route" {
  count    = var.create_api ? 1 : 0
  api_id   = aws_apigatewayv2_api.otp_api[0].id
  route_key = var.generate_route_key
  target    = "integrations/${aws_apigatewayv2_integration.generate_integration[0].id}"
}

resource "aws_apigatewayv2_route" "verify_route" {
  count    = var.create_api ? 1 : 0
  api_id   = aws_apigatewayv2_api.otp_api[0].id
  route_key = var.verify_route_key
  target    = "integrations/${aws_apigatewayv2_integration.verify_integration[0].id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  count      = var.create_api ? 1 : 0
  api_id     = aws_apigatewayv2_api.otp_api[0].id
  name       = var.api_stage_name
  auto_deploy = var.api_auto_deploy
}

########################
# Allow API Gateway to invoke Lambdas
########################
resource "aws_lambda_permission" "apigw_invoke_generate" {
  count         = var.create_api ? 1 : 0
  statement_id  = "AllowAPIGatewayInvokeGenerate-${random_id.suffix.hex}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.otp_generate.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.otp_api[0].execution_arn}/*/*"
  depends_on    = [aws_apigatewayv2_api.otp_api]
}

resource "aws_lambda_permission" "apigw_invoke_verify" {
  count         = var.create_api ? 1 : 0
  statement_id  = "AllowAPIGatewayInvokeVerify-${random_id.suffix.hex}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.otp_verify.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.otp_api[0].execution_arn}/*/*"
  depends_on    = [aws_apigatewayv2_api.otp_api]
}

# small random id used to avoid duplicate statement_id collisions
resource "random_id" "suffix" {
  byte_length = 2
}
