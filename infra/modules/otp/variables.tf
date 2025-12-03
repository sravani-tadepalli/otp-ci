variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = "OtpTable"
}

variable "dynamodb_hash_key" {
  description = "Hash key attribute name"
  type        = string
  default     = "mobile_number"
}

variable "dynamodb_ttl_attribute" {
  description = "TTL attribute name for the DynamoDB table"
  type        = string
  default     = "expiry"
}

variable "dynamodb_ttl_enabled" {
  description = "Enable TTL on the DynamoDB table"
  type        = bool
  default     = true
}

variable "lambda_role_name" {
  description = "IAM role name for lambda"
  type        = string
  default     = "lambda_otp_role"
}

variable "lambda_generate_name" {
  description = "Lambda function name for OTP generation"
  type        = string
  default     = "OtpGenerateFunction"
}

variable "lambda_verify_name" {
  description = "Lambda function name for OTP verification"
  type        = string
  default     = "OtpVerifyFunction"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.10"
}

variable "lambda_generate_zip" {
  description = "Path to the zip file for the generate lambda"
  type        = string
  default     = "lambda_generate.py.zip"
}

variable "lambda_verify_zip" {
  description = "Path to the zip file for the verify lambda"
  type        = string
  default     = "lambda_verify.py.zip"
}

variable "lambda_generate_handler" {
  description = "Handler for generate lambda (module:function)"
  type        = string
  default     = "lambda_generate.handler"
}

variable "lambda_verify_handler" {
  description = "Handler for verify lambda (module:function)"
  type        = string
  default     = "lambda_verify.handler"
}

variable "otp_ttl_seconds" {
  description = "OTP TTL in seconds"
  type        = number
  default     = 300
}

variable "otp_secret" {
  description = "OTP secret used by both lambdas (in prod use Secrets Manager)"
  type        = string
  default     = "change-this-secret-dev"
  sensitive   = true
}

variable "extra_environment_variables" {
  description = "Map of extra environment variables to attach to lambdas"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to add to resources"
  type        = map(string)
  default     = {
    ManagedBy = "terraform"
  }
}

variable "create_api" {
  description = "Whether to create an HTTP API (API Gateway v2) + routes"
  type        = bool
  default     = true
}

variable "api_name" {
  description = "Name for the HTTP API"
  type        = string
  default     = "OtpApi"
}

variable "api_stage_name" {
  description = "stage name"
  type        = string
  default     = "$default"
}

variable "api_auto_deploy" {
  description = "Stage auto-deploy"
  type        = bool
  default     = true
}

variable "generate_route_key" {
  description = "Route key for generate"
  type        = string
  default     = "POST /generate-otp"
}

variable "verify_route_key" {
  description = "Route key for verify"
  type        = string
  default     = "POST /verify-otp"
}
