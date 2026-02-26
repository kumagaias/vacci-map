# VacciMap Terraform Configuration

This directory contains the Terraform configuration for the VacciMap production environment.

## Prerequisites

- Terraform 1.14.0 (managed by mise)
- AWS CLI configured with appropriate credentials
- AWS account with permissions to create DynamoDB, Cognito, and Secrets Manager resources

## Setup

1. Install mise and required tools:
```bash
mise install
```

2. Create `terraform.tfvars` file from example:
```bash
cd terraform/environments/production
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

3. Configure AWS credentials:
```bash
aws configure
```

4. Deploy infrastructure using the deployment script:
```bash
cd terraform/environments/production
./deploy.sh
```

Or manually:

```bash
cd terraform/environments/production

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

## Post-Deployment Steps

After applying the Terraform configuration, you must manually set the Claude API key value:

```bash
aws secretsmanager put-secret-value \
  --secret-id vaccimap-claude-api-key \
  --secret-string "your-claude-api-key-here"
```

## Resources Created

- **DynamoDB Tables:**
  - `vaccimap-outbreak-cache` - Outbreak data cache (6h TTL)
  - `vaccimap-vaccine-schedule-cache` - Vaccination schedules (30d TTL)
  - `vaccimap-child-profiles` - Child profile data
  - `vaccimap-clinic-cache` - Clinic information (7d TTL)

- **Cognito:**
  - User Pool with email verification
  - User Pool Client for authentication

- **Secrets Manager:**
  - Secret for Claude API key
  - IAM policy for Lambda access

## Outputs

Run `terraform output` to see all output values including:
- DynamoDB table names
- Cognito User Pool ID and Client ID
- Secrets Manager ARN
- IAM policy ARN

## Clean Up

To destroy all resources:
```bash
terraform destroy
```

**Warning:** This will delete all data in DynamoDB tables.
