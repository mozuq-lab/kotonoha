#!/bin/bash
# Helper script for connpass-notifier operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_usage() {
    echo "Usage: ./scripts/manage.sh [command]"
    echo ""
    echo "Commands:"
    echo "  build          - Build the SAM application"
    echo "  deploy         - Deploy the application"
    echo "  test-checker   - Manually invoke the Event Checker function"
    echo "  test-notifier  - Manually invoke the Email Notifier function"
    echo "  logs-checker   - Tail Event Checker logs"
    echo "  logs-notifier  - Tail Email Notifier logs"
    echo "  list-events    - List events in DynamoDB"
    echo "  validate       - Validate SAM template"
    echo "  delete         - Delete the stack"
    echo ""
}

function validate_template() {
    echo -e "${YELLOW}Validating SAM template...${NC}"
    sam validate --lint
    echo -e "${GREEN}✓ Template is valid${NC}"
}

function build_app() {
    echo -e "${YELLOW}Building SAM application...${NC}"
    sam build
    echo -e "${GREEN}✓ Build complete${NC}"
}

function deploy_app() {
    echo -e "${YELLOW}Deploying application...${NC}"
    sam deploy
    echo -e "${GREEN}✓ Deployment complete${NC}"
}

function get_function_name() {
    local function_type=$1
    aws lambda list-functions \
        --query "Functions[?contains(FunctionName, '$function_type')].FunctionName" \
        --output text
}

function test_event_checker() {
    echo -e "${YELLOW}Testing Event Checker function...${NC}"
    local function_name=$(get_function_name "EventChecker")
    
    if [ -z "$function_name" ]; then
        echo -e "${RED}✗ Event Checker function not found${NC}"
        exit 1
    fi
    
    echo "Function: $function_name"
    aws lambda invoke \
        --function-name "$function_name" \
        --payload '{}' \
        /tmp/response.json
    
    echo -e "\n${GREEN}Response:${NC}"
    cat /tmp/response.json | python3 -m json.tool
    rm /tmp/response.json
}

function test_email_notifier() {
    echo -e "${YELLOW}Testing Email Notifier function...${NC}"
    local function_name=$(get_function_name "EmailNotifier")
    
    if [ -z "$function_name" ]; then
        echo -e "${RED}✗ Email Notifier function not found${NC}"
        exit 1
    fi
    
    echo "Function: $function_name"
    aws lambda invoke \
        --function-name "$function_name" \
        --payload '{}' \
        /tmp/response.json
    
    echo -e "\n${GREEN}Response:${NC}"
    cat /tmp/response.json | python3 -m json.tool
    rm /tmp/response.json
}

function tail_checker_logs() {
    echo -e "${YELLOW}Tailing Event Checker logs...${NC}"
    local function_name=$(get_function_name "EventChecker")
    
    if [ -z "$function_name" ]; then
        echo -e "${RED}✗ Event Checker function not found${NC}"
        exit 1
    fi
    
    aws logs tail "/aws/lambda/$function_name" --follow
}

function tail_notifier_logs() {
    echo -e "${YELLOW}Tailing Email Notifier logs...${NC}"
    local function_name=$(get_function_name "EmailNotifier")
    
    if [ -z "$function_name" ]; then
        echo -e "${RED}✗ Email Notifier function not found${NC}"
        exit 1
    fi
    
    aws logs tail "/aws/lambda/$function_name" --follow
}

function list_events() {
    echo -e "${YELLOW}Listing events in DynamoDB...${NC}"
    aws dynamodb scan \
        --table-name connpass-events \
        --max-items 10 \
        | python3 -m json.tool
}

function delete_stack() {
    echo -e "${RED}WARNING: This will delete the entire stack and all data!${NC}"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo -e "${YELLOW}Deleting stack...${NC}"
        sam delete
        echo -e "${GREEN}✓ Stack deleted${NC}"
    else
        echo "Cancelled"
    fi
}

# Main
case "${1:-}" in
    build)
        build_app
        ;;
    deploy)
        deploy_app
        ;;
    test-checker)
        test_event_checker
        ;;
    test-notifier)
        test_email_notifier
        ;;
    logs-checker)
        tail_checker_logs
        ;;
    logs-notifier)
        tail_notifier_logs
        ;;
    list-events)
        list_events
        ;;
    validate)
        validate_template
        ;;
    delete)
        delete_stack
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
