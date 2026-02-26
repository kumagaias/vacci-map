#!/bin/bash
set -e

echo "VacciMap Infrastructure Deployment"
echo "==================================="
echo ""

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "Error: terraform.tfvars not found!"
    echo "Please create terraform.tfvars from terraform.tfvars.example"
    echo ""
    echo "Example:"
    echo "  cp terraform.tfvars.example terraform.tfvars"
    echo "  # Edit terraform.tfvars with your values"
    exit 1
fi

# Check AWS credentials
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "Error: AWS credentials not configured!"
    echo "Please configure AWS CLI with: aws configure"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: ${AWS_ACCOUNT_ID}"
echo ""

# Initialize Terraform
echo "Initializing Terraform..."
terraform init
echo ""

# Validate configuration
echo "Validating Terraform configuration..."
terraform validate
echo ""

# Plan deployment
echo "Planning infrastructure changes..."
terraform plan -out=tfplan
echo ""

# Ask for confirmation
read -p "Do you want to apply these changes? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Deployment cancelled."
    rm -f tfplan
    exit 0
fi

# Apply changes
echo ""
echo "Applying infrastructure changes..."
terraform apply tfplan
rm -f tfplan
echo ""

# Display outputs
echo "Deployment complete!"
echo ""
echo "Infrastructure outputs:"
terraform output
echo ""

# Reminder about Claude API key
echo "IMPORTANT: Don't forget to set the Claude API key in Secrets Manager:"
echo ""
echo "  aws secretsmanager put-secret-value \\"
echo "    --secret-id vaccimap-claude-api-key \\"
echo "    --secret-string \"your-claude-api-key-here\""
echo ""
