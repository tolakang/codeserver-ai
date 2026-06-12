#!/bin/bash
# scripts/configure-provider.sh - Unified provider configuration

set -euo pipefail

load_env_file() {
  local file="${1:-.env}"
  local line key value

  [[ -f "$file" ]] || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]] || continue

    key="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"

    if [[ "$value" == \"*\" && "$value" == *\" ]]; then
      value="${value:1:${#value}-2}"
    elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
      value="${value:1:${#value}-2}"
    fi

    declare -gx "$key=$value"
  done < "$file"
}

json_escape() {
  local value="${1:-}"
  printf '%s' "$value" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e $'s/\t/\\t/g' -e $'s/\r/\\r/g'
}

load_env_file ".env"

PROVIDER_NAMES=(openrouter opencode-zen freellmapi anthropic openai)
PROVIDER_DISPLAY=(OpenRouter "OpenCode Zen" FreeLLMAPI Anthropic OpenAI)
PROVIDER_KEY_VARS=(OPENROUTER_API_KEY OPENCODE_ZEN_API_KEY FREELLMAPI_API_KEY ANTHROPIC_API_KEY OPENAI_API_KEY)
PROVIDER_URLS=(
  "${OPENROUTER_BASE_URL:-https://openrouter.ai/api/v1}"
  "${OPENCODE_ZEN_BASE_URL:-https://opencode.ai/zen/api/v1}"
  "${FREELLMAPI_BASE_URL:-http://freellmapi:3000/v1}"
  "${ANTHROPIC_BASE_URL:-https://api.anthropic.com}"
  "${OPENAI_BASE_URL:-https://api.openai.com/v1}"
)
OPENCODE_PROVIDERS=(openai openai openai anthropic openai)

show_providers() {
  echo "Available AI Providers:"
  echo "======================"
  for i in "${!PROVIDER_NAMES[@]}"; do
    echo "$((i + 1)). ${PROVIDER_DISPLAY[$i]}"
    echo "   Key env var: ${PROVIDER_KEY_VARS[$i]}"
    echo "   Base URL: ${PROVIDER_URLS[$i]}"
    echo
  done
}

configure_provider() {
  local choice key_choice api_key api_key_var base_url opencode_provider display_name

  show_providers
  read -r -p "Select provider (1-${#PROVIDER_NAMES[@]}): " choice

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#PROVIDER_NAMES[@]} )); then
    echo "Invalid choice"
    return 1
  fi

  choice=$((choice - 1))
  display_name="${PROVIDER_DISPLAY[$choice]}"
  api_key_var="${PROVIDER_KEY_VARS[$choice]}"
  base_url="${PROVIDER_URLS[$choice]}"
  opencode_provider="${OPENCODE_PROVIDERS[$choice]}"

  echo "Configuring ${display_name}..."
  echo "1. Use existing API key (from .env)"
  echo "2. Set new API key"
  read -r -p "Choice: " key_choice

  if [[ "$key_choice" == "2" ]]; then
    echo "Enter ${display_name} API key:"
    read -r -s api_key
    echo

    if [[ ! -f .env ]]; then
      : > .env
    fi

    if ! grep -q "^${api_key_var}=" .env 2>/dev/null; then
      printf '%s=%s\n' "$api_key_var" "$api_key" >> .env
      echo "Added ${api_key_var} to .env"
    else
      echo "${api_key_var} already exists in .env"
    fi
  fi

CONFIG_DIR="${OPENCODE_CONFIG_DIR:-${HOME}/.config/opencode}"

mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_DIR/config.json" <<EOF
{
  "provider": "$(json_escape "$opencode_provider")",
  "baseURL": "$(json_escape "$base_url")",
  "apiKey": "$(json_escape "${!api_key_var:-}")"
}
EOF
chmod 600 "$CONFIG_DIR/config.json"

echo "${display_name} configured successfully"
echo "Config saved to: $CONFIG_DIR/config.json"
}

test_provider_connection() {
  local provider index base_url api_key_var

  read -r -p "Enter provider name (openrouter/opencode-zen/freellmapi/anthropic/openai): " provider

  case "$provider" in
    openrouter) index=0 ;;
    opencode-zen) index=1 ;;
    freellmapi) index=2 ;;
    anthropic) index=3 ;;
    openai) index=4 ;;
    *)
      echo "Unknown provider"
      return 1
      ;;
  esac

  base_url="${PROVIDER_URLS[$index]}"
  api_key_var="${PROVIDER_KEY_VARS[$index]}"

  echo "Testing connection to ${PROVIDER_NAMES[$index]} at ${base_url}..."

  if [[ -z "${!api_key_var:-}" ]]; then
    echo "API key not set. Please configure first."
    echo "Run: ./scripts/configure-provider.sh configure"
    return 1
  fi

  if command -v curl >/dev/null 2>&1; then
    echo "Testing with curl..."
    if curl -s -f --max-time 15 -H "Authorization: Bearer ${!api_key_var}" "${base_url}/v1/models" >/dev/null 2>&1; then
      echo "${PROVIDER_NAMES[$index]} connection successful"
    else
      echo "${PROVIDER_NAMES[$index]} connection failed"
      echo "Please check your API key and network connection."
      return 1
    fi
  else
    echo "curl not available, skipping connection test"
  fi
}

case "${1:-}" in
  list)
    show_providers
    ;;
  configure)
    configure_provider
    ;;
  test)
    test_provider_connection
    ;;
  *)
    echo "Usage: $0 [list|configure|test]"
    echo
    echo "Commands:"
    echo "  list      - Show all available providers"
    echo "  configure - Configure a new provider"
    echo "  test      - Test provider connection"
    ;;
esac
