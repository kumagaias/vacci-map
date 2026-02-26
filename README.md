# VacciMap

Infectious disease hazard map and child vaccination management application.

## Overview

VacciMap combines real-time infectious disease outbreak monitoring with personalized vaccination schedule management, leveraging Claude AI's web search capabilities for data retrieval and risk assessment.

## Features

- Interactive hazard map showing disease risk levels by region
- Real-time disease outbreak data with AI-powered retrieval
- Child profile management with vaccination tracking
- AI-powered health chat for guidance
- Nearby clinic information
- Multi-language support (Japanese/English)

## Technology Stack

- **Frontend**: React, TypeScript, Leaflet, Vite
- **Backend**: Python 3.14 Lambda functions in ECR containers
- **Infrastructure**: Terraform 1.14, AWS (DynamoDB, Cognito, API Gateway, Amplify)
- **AI**: Claude API (claude-sonnet-4-20250514) with web_search

## Prerequisites

- [mise](https://mise.jdx.dev/) for tool version management
- AWS CLI configured with appropriate credentials
- AWS account with permissions for DynamoDB, Cognito, Lambda, ECR, Secrets Manager

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/kumagaias/vacci-map.git
cd vacci-map
```

2. Install dependencies:
```bash
make install
```

3. Deploy infrastructure:
```bash
make deploy-infra
```

4. Set Claude API key:
```bash
aws secretsmanager put-secret-value \
  --secret-id vaccimap-claude-api-key \
  --secret-string "your-claude-api-key-here"
```

## Project Structure

```
vacci-map/
├── .kiro/specs/          # Specification documents
├── terraform/            # Infrastructure as Code
│   ├── modules/         # Reusable Terraform modules
│   └── environments/    # Environment-specific configs
├── lambda/              # Lambda function services
│   ├── outbreak-service/
│   ├── vaccine-service/
│   ├── child-service/
│   ├── chat-service/
│   └── clinic-service/
└── frontend/            # React application
```

## Development

See individual README files for detailed instructions:
- [Terraform Infrastructure](terraform/environments/production/README.md)
- [Lambda Services](lambda/README.md)

## Available Commands

```bash
make help              # Display available commands
make install           # Install dependencies
make test              # Run all tests
make deploy-infra      # Deploy infrastructure
make destroy-infra     # Destroy infrastructure
make clean             # Clean build artifacts
```

## Documentation

- [Requirements](. kiro/specs/vaccimap-full-stack-app/requirements.md)
- [Design](. kiro/specs/vaccimap-full-stack-app/design.md)
- [Tasks](. kiro/specs/vaccimap-full-stack-app/tasks.md)

## License

MIT

## Contributing

This project was built for the TerraCode Convergence hackathon.
