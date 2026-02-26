variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "cognito_user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
  default     = "vaccimap-users"
}

variable "claude_api_key_secret_name" {
  description = "Name of the Secrets Manager secret for Claude API key"
  type        = string
  default     = "vaccimap-claude-api-key"
}
