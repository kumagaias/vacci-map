# VacciMap Lambda Services

This directory contains all Lambda function services for the VacciMap application.

## Services

- `outbreak-service` - Retrieves and caches infectious disease outbreak data
- `vaccine-service` - Manages vaccination schedules
- `child-service` - Handles child profile CRUD operations
- `chat-service` - AI-powered health chat with Claude API
- `clinic-service` - Retrieves nearby clinic information

## Docker Build and Push Commands

### Prerequisites

1. Get AWS account ID:
```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
```

2. Login to ECR:
```bash
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
```

### Build and Push All Services

```bash
# Set variables
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
SERVICES=("outbreak-service" "vaccine-service" "child-service" "chat-service" "clinic-service")

# Build and push each service
for SERVICE in "${SERVICES[@]}"; do
  echo "Building ${SERVICE}..."
  cd ${SERVICE}
  
  docker build -t vaccimap-${SERVICE}:latest .
  docker tag vaccimap-${SERVICE}:latest \
    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/vaccimap-${SERVICE}:latest
  
  docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/vaccimap-${SERVICE}:latest
  
  cd ..
done
```

### Build and Push Individual Service

```bash
# Example: outbreak-service
SERVICE="outbreak-service"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"

cd ${SERVICE}

# Build
docker build -t vaccimap-${SERVICE}:latest .

# Tag
docker tag vaccimap-${SERVICE}:latest \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/vaccimap-${SERVICE}:latest

# Push
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/vaccimap-${SERVICE}:latest
```

## Development

Each service directory contains:
- `src/` - Source code
- `tests/` - Unit and property tests
- `Dockerfile` - Container definition
- `requirements.txt` - Python dependencies

## Testing

Run tests for a specific service:
```bash
cd <service-name>
python -m pytest tests/
```

Run tests with coverage:
```bash
cd <service-name>
python -m pytest --cov=src tests/
```

## Environment Variables

Each Lambda function requires specific environment variables:

### outbreak-service
- `DYNAMODB_TABLE_OUTBREAK` - OutbreakCache table name
- `CLAUDE_API_KEY_SECRET` - Secrets Manager secret name
- `LOG_LEVEL` - Logging level (INFO, DEBUG, ERROR)

### vaccine-service
- `DYNAMODB_TABLE_VACCINE` - VaccineScheduleCache table name
- `CLAUDE_API_KEY_SECRET` - Secrets Manager secret name
- `LOG_LEVEL` - Logging level

### child-service
- `DYNAMODB_TABLE_CHILD` - ChildProfiles table name
- `LOG_LEVEL` - Logging level

### chat-service
- `DYNAMODB_TABLE_CHILD` - ChildProfiles table name
- `DYNAMODB_TABLE_OUTBREAK` - OutbreakCache table name
- `CLAUDE_API_KEY_SECRET` - Secrets Manager secret name
- `LOG_LEVEL` - Logging level

### clinic-service
- `DYNAMODB_TABLE_CLINIC` - ClinicCache table name
- `CLAUDE_API_KEY_SECRET` - Secrets Manager secret name
- `LOG_LEVEL` - Logging level
