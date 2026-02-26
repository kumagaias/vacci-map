terraform {
  required_version = "~> 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# OutbreakCache Table
module "outbreak_cache" {
  source = "../../modules/dynamodb"

  table_name     = "vaccimap-outbreak-cache"
  hash_key       = "locationKey"
  range_key      = "diseaseType"
  ttl_enabled    = true
  ttl_attribute  = "ttl"

  tags = {
    Project     = "VacciMap"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# VaccineScheduleCache Table
module "vaccine_schedule_cache" {
  source = "../../modules/dynamodb"

  table_name     = "vaccimap-vaccine-schedule-cache"
  hash_key       = "locationKey"
  range_key      = "vaccineId"
  ttl_enabled    = true
  ttl_attribute  = "ttl"

  tags = {
    Project     = "VacciMap"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ChildProfiles Table
module "child_profiles" {
  source = "../../modules/dynamodb"

  table_name    = "vaccimap-child-profiles"
  hash_key      = "childId"
  gsi_name      = "parentId-index"
  gsi_hash_key  = "parentId"

  tags = {
    Project     = "VacciMap"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ClinicCache Table
module "clinic_cache" {
  source = "../../modules/dynamodb"

  table_name     = "vaccimap-clinic-cache"
  hash_key       = "locationKey"
  range_key      = "clinicId"
  ttl_enabled    = true
  ttl_attribute  = "ttl"

  tags = {
    Project     = "VacciMap"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Cognito User Pool
module "cognito" {
  source = "../../modules/cognito"

  user_pool_name = var.cognito_user_pool_name

  tags = {
    Project     = "VacciMap"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Secrets Manager for Claude API Key
resource "aws_secretsmanager_secret" "claude_api_key" {
  name        = var.claude_api_key_secret_name
  description = "Claude API key for VacciMap application"

  tags = {
    Project     = "VacciMap"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# IAM policy for Lambda functions to access the secret
resource "aws_iam_policy" "lambda_secrets_access" {
  name        = "vaccimap-lambda-secrets-access"
  description = "Allow Lambda functions to access Claude API key secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.claude_api_key.arn
      }
    ]
  })

  tags = {
    Project     = "VacciMap"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
