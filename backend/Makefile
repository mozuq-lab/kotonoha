.PHONY: lint format test test-cov clean help

help:  ## Display this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

lint:  ## Run ruff linter
	ruff check app tests

format:  ## Format code with black and ruff
	black app tests
	ruff check app tests --fix

test:  ## Run tests
	pytest

test-cov:  ## Run tests with coverage report
	pytest --cov=app --cov-report=html --cov-report=term-missing

clean:  ## Clean up generated files
	rm -rf .pytest_cache
	rm -rf htmlcov
	rm -rf .coverage
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
