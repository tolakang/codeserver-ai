#!/bin/bash
# scripts/resolve-env.sh - Resolve ${{project.*}} placeholders from .env.values
# Usage: source scripts/resolve-env.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

VALUES_FILE="${ROOT_DIR}/.env.values"
TEMPLATE_FILE="${ROOT_DIR}/.env.example"
OUTPUT_FILE="${ROOT_DIR}/.env"

# Check if values file exists
if [ ! -f "$VALUES_FILE" ]; then
    echo "Error: $VALUES_FILE not found"
    echo "Please create it from .env.values template and fill in your values"
    exit 1
fi

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: $TEMPLATE_FILE not found"
    exit 1
fi

echo "Resolving environment variables from $VALUES_FILE..."

# Create output file
cp "$TEMPLATE_FILE" "$OUTPUT_FILE"

# Read each key=value pair from .env.values
while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ "$key" =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue
    
    # Escape special characters for sed
    escaped_value=$(printf '%s\n' "$value" | sed 's/[&/\]/\\&/g')
    
    # Replace ${{project.KEY}} with actual value in output file
    sed -i "s|\${{project.${key}}}|${escaped_value}|g" "$OUTPUT_FILE"
    
    echo "Resolved: ${key}=***"
done < "$VALUES_FILE"

# Check for any unresolved placeholders
if grep -q '${{project\.' "$OUTPUT_FILE"; then
    echo ""
    echo "Warning: Some placeholders could not be resolved:"
    grep -n '${{project\.' "$OUTPUT_FILE" || true
    echo ""
    echo "Please add the missing values to $VALUES_FILE"
fi

echo ""
echo "Environment variables resolved successfully to $OUTPUT_FILE"
echo "You can now use this file with Docker Compose or other tools."
