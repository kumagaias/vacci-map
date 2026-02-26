output "outbreak_cache_table_name" {
  description = "Name of the OutbreakCache DynamoDB table"
  value       = module.outbreak_cache.table_name
}

output "vaccine_schedule_cache_table_name" {
  description = "Name of the VaccineScheduleCache DynamoDB table"
  value       = module.vaccine_schedule_cache.table_name
}

output "child_profiles_table_name" {
  description = "Name of the ChildProfiles DynamoDB table"
  value       = module.child_profiles.table_name
}

output "clinic_cache_table_name" {
  description = "Name of the ClinicCache DynamoDB table"
  value       = module.clinic_cache.table_name
}

output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = module.cognito.client_id
}

output "claude_api_key_secret_arn" {
  description = "ARN of the Claude API key secret"
  value       = aws_secretsmanager_secret.claude_api_key.arn
}

output "lambda_secrets_access_policy_arn" {
  description = "ARN of the IAM policy for Lambda secrets access"
  value       = aws_iam_policy.lambda_secrets_access.arn
}
