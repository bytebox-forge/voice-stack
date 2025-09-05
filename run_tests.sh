#!/bin/bash

# Matrix Family Server Test Runner
# Simple script to run comprehensive tests for the Matrix family server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Matrix Family Server Test Runner${NC}"
echo "======================================"

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: docker-compose.yml not found. Please run from project root.${NC}"
    exit 1
fi

# Create tests directory if it doesn't exist
mkdir -p tests

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is required but not installed.${NC}"
    exit 1
fi

# Check if tests directory has the required files
if [ ! -f "tests/run_tests.py" ]; then
    echo -e "${RED}Error: Test files not found. Please ensure all test files are in the tests/ directory.${NC}"
    exit 1
fi

# Install test dependencies if needed
echo -e "${YELLOW}Checking test dependencies...${NC}"
if [ -f "tests/requirements.txt" ]; then
    if ! python3 -c "import pytest, requests, playwright" &> /dev/null; then
        echo -e "${YELLOW}Installing test dependencies...${NC}"
        python3 -m pip install -r tests/requirements.txt
        
        # Install Playwright browsers
        echo -e "${YELLOW}Installing Playwright browsers...${NC}"
        python3 -m playwright install chromium
    else
        echo -e "${GREEN}✓ Test dependencies already installed${NC}"
    fi
else
    echo -e "${YELLOW}⚠ requirements.txt not found, assuming dependencies are installed${NC}"
fi

# Check if services are running
echo -e "${YELLOW}Checking service status...${NC}"
if ! curl -s http://localhost:8008/health > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Synapse server not responding. Starting services...${NC}"
    
    if [ -f "deploy.sh" ]; then
        ./deploy.sh start
        
        # Wait for services to be ready
        echo -e "${YELLOW}Waiting for services to be ready...${NC}"
        sleep 30
        
        # Check again
        if ! curl -s http://localhost:8008/health > /dev/null 2>&1; then
            echo -e "${RED}Error: Services failed to start properly. Check logs with './deploy.sh logs'${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Error: deploy.sh not found. Please start services manually.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Services are running${NC}"
fi

# Parse command line arguments
CONFIG_FILE=""
OUTPUT_DIR="test-reports"
FORMAT="both"
SUITES=""
EXTRA_ARGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        -s|--suites)
            SUITES="$2"
            shift 2
            ;;
        --quick)
            EXTRA_ARGS="$EXTRA_ARGS -m 'not slow'"
            shift
            ;;
        --no-browser)
            export HEADLESS=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -c, --config FILE       Test configuration file"
            echo "  -o, --output-dir DIR    Output directory for reports (default: test-reports)"
            echo "  -f, --format FORMAT     Report format: html, json, both (default: both)"
            echo "  -s, --suites SUITES     Specific test suites to run"
            echo "      --quick             Skip slow tests"
            echo "      --no-browser        Run browser tests in headless mode"
            echo "  -h, --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                              # Run all tests"
            echo "  $0 --quick                      # Run quick tests only"
            echo "  $0 -s 'test_synapse_api.py'    # Run specific test suite"
            echo "  $0 -f html -o reports           # Generate HTML report in 'reports' dir"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Set up test environment
export SYNAPSE_URL="http://localhost:8008"
export ELEMENT_URL="http://localhost:8080"
export SYNAPSE_SERVER_NAME="matrix.byte-box.org"
export TEST_USER_PASSWORD="TestPassword123!"

# Use config file if provided
CONFIG_ARG=""
if [ -n "$CONFIG_FILE" ]; then
    if [ -f "$CONFIG_FILE" ]; then
        CONFIG_ARG="--config $CONFIG_FILE"
    else
        echo -e "${RED}Error: Config file '$CONFIG_FILE' not found${NC}"
        exit 1
    fi
fi

# Build test command
TEST_CMD="python3 tests/run_tests.py"
if [ -n "$CONFIG_ARG" ]; then
    TEST_CMD="$TEST_CMD $CONFIG_ARG"
fi
TEST_CMD="$TEST_CMD --output-dir $OUTPUT_DIR --format $FORMAT"
if [ -n "$SUITES" ]; then
    TEST_CMD="$TEST_CMD --suites $SUITES"
fi
if [ -n "$EXTRA_ARGS" ]; then
    TEST_CMD="$TEST_CMD $EXTRA_ARGS"
fi

echo -e "${BLUE}Running tests...${NC}"
echo "Command: $TEST_CMD"
echo ""

# Run the tests
cd "$(dirname "$0")"
if eval $TEST_CMD; then
    echo ""
    echo -e "${GREEN}✓ All tests completed successfully!${NC}"
    echo -e "${GREEN}Check the generated reports in: $OUTPUT_DIR${NC}"
    
    # Open HTML report if available
    LATEST_HTML_REPORT=$(find "$OUTPUT_DIR" -name "*.html" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2- 2>/dev/null || echo "")
    if [ -n "$LATEST_HTML_REPORT" ] && [ -f "$LATEST_HTML_REPORT" ]; then
        echo -e "${BLUE}HTML Report: file://$(realpath "$LATEST_HTML_REPORT")${NC}"
        
        # Try to open in browser (Linux)
        if command -v xdg-open &> /dev/null; then
            echo -e "${BLUE}Opening report in browser...${NC}"
            xdg-open "$LATEST_HTML_REPORT" 2>/dev/null || true
        fi
    fi
    
    exit 0
else
    echo ""
    echo -e "${RED}✗ Some tests failed. Check the reports for details.${NC}"
    echo -e "${YELLOW}Troubleshooting tips:${NC}"
    echo "- Run './deploy.sh health' to check service status"
    echo "- Check service logs with './deploy.sh logs [service]'"
    echo "- Run with --quick to skip slow tests"
    echo "- Check the detailed HTML report for specific failures"
    exit 1
fi