#!/bin/bash
# scripts/resolve-env.sh - Generate .env from .env.example
# Usage: source scripts/resolve-env.sh
#
# This script reads .env.example, resolves any ${ENVIRONMENT.VAR} or ${PROJECT.VAR}
# links, and writes the result to .env for use with docker-compose or other tools.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

EXAMPLE_FILE="${ROOT_DIR}/.env.example"
OUTPUT_FILE="${ROOT_DIR}/.env"

# Check if example file exists
if [ ! -f "$EXAMPLE_FILE" ]; then
    echo "Error: $EXAMPLE_FILE not found"
    echo "Please create .env.example from the template"
    exit 1
fi

echo "Generating .env from .env.example..."

# Copy example to output
cp "$EXAMPLE_FILE" "$OUTPUT_FILE"

# First pass: collect all KEY=VALUE pairs from Environment section
declare -A VALUES
while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ "$key" =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue
    
    # Only collect from Environment section (before Project/Service sections)
    # Store the value for later resolution
    VALUES["$key"]="$value"
done < "$OUTPUT_FILE"

# Second pass: resolve ${ENVIRONMENT.VAR} and ${PROJECT.VAR} links
for key in "${!VALUES[@]}"; do
    value="${VALUES[$key]}"
    
    # Check for ${ENVIRONMENT.VAR} or ${PROJECT.VAR} patterns
    if [[ "$value" =~ \$\{(ENVIRONMENT|PROJECT)\.([A-Z_]+)\} ]]; then
        ref_key="${BASH_REMATCH[2]}"
        if [[ -n "${VALUES[$ref_key]}" ]]; then
            # Replace the reference with the actual value
            sed -i "s|\${\(ENVIRONMENT\|PROJECT\)\.${ref_key}}|${VALUES[$ref_key]}|g" "$OUTPUT_FILE"
            echo "Resolved: ${key} -> ${ref_key}"
        else
            echo "Warning: Referenced variable ${ref_key} not found for ${key}"
        fi
    fi
done

# Check for any unresolved placeholders
if grep -q '${\(ENVIRONMENT\|PROJECT\)\.' "$OUTPUT_FILE"; then
    echo ""
    echo "Warning: Some placeholders could not be resolved:"
    grep -n '${\(ENVIRONMENT\|PROJECT\)\.' "$OUTPUT_FILE" || true
fi

echo ""
echo "Environment variables written to $OUTPUT_FILE"
echo "You can now use this file with Docker Compose or other tools."
