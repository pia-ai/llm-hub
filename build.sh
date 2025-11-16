#!/bin/bash

# llm-hub Build Script
# This script provides various build options for the Maven project

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# Print colored message
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Print usage information
print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Build options for Smart Decision Service project

OPTIONS:
    -h, --help              Display this help message
    -c, --clean             Clean build (mvn clean install)
    -s, --skip-tests        Skip tests during build
    -f, --fast              Fast build (clean install skip tests)
    -p, --package           Package only (mvn package)
    -m, --module <name>     Build specific module only
    -d, --download-sources  Download sources and javadoc
    -v, --verify            Run full verification (includes tests)
    -o, --offline           Build in offline mode
    -t, --test              Run tests only
    -u, --update            Update dependencies

Examples:
    $0                      # Default build (install without clean)
    $0 -c                   # Clean and install
    $0 -f                   # Fast build (clean, skip tests)
    $0 -m app/bootstrap     # Build specific module
    $0 -c -s                # Clean build without tests

EOF
}

# Default options
CLEAN=false
SKIP_TESTS=false
PACKAGE_ONLY=false
MODULE=""
DOWNLOAD_SOURCES=false
VERIFY=false
OFFLINE=false
TEST_ONLY=false
UPDATE_DEPS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -s|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -f|--fast)
            CLEAN=true
            SKIP_TESTS=true
            shift
            ;;
        -p|--package)
            PACKAGE_ONLY=true
            shift
            ;;
        -m|--module)
            MODULE="$2"
            shift 2
            ;;
        -d|--download-sources)
            DOWNLOAD_SOURCES=true
            shift
            ;;
        -v|--verify)
            VERIFY=true
            shift
            ;;
        -o|--offline)
            OFFLINE=true
            shift
            ;;
        -t|--test)
            TEST_ONLY=true
            shift
            ;;
        -u|--update)
            UPDATE_DEPS=true
            shift
            ;;
        *)
            print_message "$RED" "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
    print_message "$RED" "Error: Maven is not installed or not in PATH"
    exit 1
fi

# Check Java version
JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d. -f1)
if [ "$JAVA_VERSION" -lt 17 ]; then
    print_message "$RED" "Error: Java 17 or higher is required. Current version: $JAVA_VERSION"
    exit 1
fi

# Build Maven command
MVN_CMD="mvn"

# Add offline mode
if [ "$OFFLINE" = true ]; then
    MVN_CMD="$MVN_CMD -o"
fi

# Build based on options
print_message "$BLUE" "======================================"
print_message "$BLUE" "  Smart Decision Service Build"
print_message "$BLUE" "======================================"
echo ""

if [ -n "$MODULE" ]; then
    print_message "$YELLOW" "Building module: $MODULE"
    MVN_CMD="$MVN_CMD -pl $MODULE -am"
fi

# Handle different build scenarios
if [ "$TEST_ONLY" = true ]; then
    print_message "$YELLOW" "Running tests only..."
    $MVN_CMD test
elif [ "$VERIFY" = true ]; then
    print_message "$YELLOW" "Running full verification..."
    if [ "$CLEAN" = true ]; then
        $MVN_CMD clean verify
    else
        $MVN_CMD verify
    fi
elif [ "$PACKAGE_ONLY" = true ]; then
    print_message "$YELLOW" "Packaging project..."
    if [ "$SKIP_TESTS" = true ]; then
        $MVN_CMD package -DskipTests
    else
        $MVN_CMD package
    fi
else
    # Default install
    if [ "$CLEAN" = true ]; then
        print_message "$YELLOW" "Cleaning previous build..."
        if [ "$SKIP_TESTS" = true ]; then
            print_message "$YELLOW" "Installing project (skip tests)..."
            $MVN_CMD clean install -DskipTests
        else
            print_message "$YELLOW" "Installing project..."
            $MVN_CMD clean install
        fi
    else
        if [ "$SKIP_TESTS" = true ]; then
            print_message "$YELLOW" "Installing project (skip tests)..."
            $MVN_CMD install -DskipTests
        else
            print_message "$YELLOW" "Installing project..."
            $MVN_CMD install
        fi
    fi
fi

# Download sources if requested
if [ "$DOWNLOAD_SOURCES" = true ]; then
    print_message "$YELLOW" "Downloading sources and javadoc..."
    $MVN_CMD dependency:sources dependency:resolve -Dclassifier=javadoc
fi

# Update dependencies if requested
if [ "$UPDATE_DEPS" = true ]; then
    print_message "$YELLOW" "Updating dependencies..."
    $MVN_CMD versions:display-dependency-updates
fi

# Build completed
if [ $? -eq 0 ]; then
    echo ""
    print_message "$GREEN" "======================================"
    print_message "$GREEN" "  Build Completed Successfully!"
    print_message "$GREEN" "======================================"
    echo ""
    print_message "$GREEN" "Main artifact location:"
    print_message "$GREEN" "  → app/bootstrap/target/llm-hub-bootstrap-1.0.0-SNAPSHOT.jar"
    echo ""
else
    echo ""
    print_message "$RED" "======================================"
    print_message "$RED" "  Build Failed!"
    print_message "$RED" "======================================"
    exit 1
fi
