variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "otp_secret" {
  type      = string
  default   = "change-this-secret-dev"
  sensitive = true
}
