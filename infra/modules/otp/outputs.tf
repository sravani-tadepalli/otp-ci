output "dynamodb_table_name" {
  value = aws_dynamodb_table.otp_table.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.otp_table.arn
}

output "lambda_generate_arn" {
  value = aws_lambda_function.otp_generate.arn
}

output "lambda_verify_arn" {
  value = aws_lambda_function.otp_verify.arn
}

output "api_endpoint" {
  value       = try(aws_apigatewayv2_api.otp_api[0].api_endpoint, "")
  description = "HTTP API endpoint (empty if create_api=false)"
}
