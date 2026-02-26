.PHONY: help install test test-unit test-security clean deploy-infra destroy-infra

help: ## Display available commands
	@echo "VacciMap - Available Commands"
	@echo "=============================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies
	@echo "Installing dependencies..."
	@mise install
	@echo "Dependencies installed successfully!"

test: test-unit test-security ## Run all tests (unit + security)

test-unit: ## Run unit tests only
	@echo "Running unit tests..."
	@echo "Note: Lambda function tests will be implemented in Phase 2"

test-security: ## Run security checks
	@echo "Running security checks..."
	@echo "Note: Security checks will be implemented with Lambda functions"

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "node_modules" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "dist" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "Clean complete!"

deploy-infra: ## Deploy infrastructure with Terraform
	@echo "Deploying infrastructure..."
	@cd terraform/environments/production && ./deploy.sh

destroy-infra: ## Destroy infrastructure (WARNING: deletes all data)
	@echo "WARNING: This will destroy all infrastructure and data!"
	@read -p "Are you sure? Type 'yes' to confirm: " CONFIRM; \
	if [ "$$CONFIRM" = "yes" ]; then \
		cd terraform/environments/production && terraform destroy; \
	else \
		echo "Destroy cancelled."; \
	fi
