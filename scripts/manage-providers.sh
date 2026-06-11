#!/bin/bash
# scripts/manage-providers.sh

# Provider configuration mapping
# Format: provider_name:display_name:api_key_env_var:base_url

PROVIDERS=(
  "openrouter:OpenRouter:OPENROUTER_API_KEY:https://openrouter.ai/api/v1"
  "opencode-zen:OpenCode Zen:OPENCODE_ZEN_API_KEY:https://opencode.ai/zen/api/v1"
  "freellmapi:FreeLLMAPI:FREELLMAPI_API_KEY:http://freellmapi:3000/v1"
  "anthropic:Anthropic:ANTHROPIC_API_KEY:https://api.anthropic.com"
  "openai:OpenAI:OPENAI_API_KEY:https://api.openai.com/v1"
)

function show_providers() {
  echo "Available AI Providers:"
  echo "======================"
  for i in "${!PROVIDERS[@]}"; do
    IFS=':' read -r provider_name display_name api_key_var base_url <<< "${PROVIDERS[$i]}"
    echo "$((i+1)). $display_name"
    echo "   Key env var: $api_key_var"
    echo "   Base URL: $base_url"
    echo
  done
}

function configure_provider() {
  show_providers
  read -p "Select provider (1-5): " choice
  
  if [[ $choice -ge 1 && $choice -le 5 ]]; then
    IFS=':' read -r provider_name display_name api_key_var base_url <<< "${PROVIDERS[$((choice-1))]}"
    
    echo "Configuring $display_name..."
    echo "1. Use existing API key (from .env)"
    echo "2. Set new API key"
    read -p "Choice: " key_choice
    
    if [[ $key_choice -eq 2 ]]; then
      echo "Enter $display_name API key:"
      read -s -p "" api_key
      echo
      # Store in .env file if not already present
      if ! grep -q "^$api_key_var=" .env 2>/dev/null; then
        echo "$api_key_var=$api_key" >> .env
        echo "✅ Added $api_key_var to .env"
      else
        echo "⚠️  $api_key_var already exists in .env"
      fi
    fi
    
    # Generate config
    cat > /home/coder/.config/opencode/config.json << EOF
{
  "provider": "openai",
  "baseURL": "$base_url",
  "apiKey": "\${$api_key_var}"
}
EOF
    
    echo "✅ $display_name configured successfully"
    echo "Config saved to: /home/coder/.config/opencode/config.json"
  else
    echo "❌ Invalid choice"
  fi
}

function test_provider_connection() {
  read -p "Enter provider name (openrouter/opencode-zen/freellmapi/anthropic/openai): " provider
  
  case $provider in
    openrouter)
      base_url="https://openrouter.ai/api/v1"
      ;;
    opencode-zen)
      base_url="https://opencode.ai/zen/api/v1"
      ;;
    freellmapi)
      base_url="http://freellmapi:3000/v1"
      ;;
    anthropic)
      base_url="https://api.anthropic.com"
      ;;
    openai)
      base_url="https://api.openai.com/v1"
      ;;
    *)
      echo "❌ Unknown provider"
      return
      ;;
  esac
  
  echo "Testing connection to $provider at $base_url..."
  
  # Check if API key is set
  api_key_var="${provider^^}_API_KEY"
  if [[ -z "${!api_key_var}" ]]; then
    echo "❌ API key not set. Please configure first."
    echo "Run: ./scripts/manage-providers.sh configure"
    return
  fi
  
  # Test connection (basic curl)
  if command -v curl >/dev/null 2>&1; then
    echo "Testing with curl..."
    if curl -s -f -H "Authorization: Bearer ${!api_key_var}" "$base_url/v1/models" >/dev/null 2>&1; then
      echo "✅ $provider connection successful"
    else
      echo "❌ $provider connection failed"
      echo "Please check your API key and network connection."
    fi
  else
    echo "⚠️  curl not available, skipping connection test"
  fi
}

# Main script
if [[ "$1" == "list" ]]; then
  show_providers
elif [[ "$1" == "configure" ]]; then
  configure_provider
elif [[ "$1" == "test" ]]; then
  test_provider_connection
else
  echo "Usage: $0 [list|configure|test]"
  echo ""
  echo "Commands:"
  echo "  list      - Show all available providers"
  echo "  configure - Configure a new provider"
  echo "  test      - Test provider connection"
fi
