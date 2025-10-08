#!/bin/bash
# cloudflare_manager.sh
# Cloudflare IP block/unblock management via API
# Version with logging (date format dd-mm-yyyy)
# ==================================================

# === LOAD CONFIGURATION ===
ENV_FILE="$HOME/.env/cloudflare"

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
else
  echo "❌ Configuration file not found at $ENV_FILE"
  exit 1
fi

# === PREPARE LOG FILE ===
LOG_DIR="$HOME/.cache"
LOG_FILE="$LOG_DIR/cloudflare_manager.log"
mkdir -p "$LOG_DIR"

# Save output and error to log (still display on screen)
exec > >(tee -a "$LOG_FILE") 2>&1

# Date format dd-mm-yyyy
DATE_NOW=$(date '+%d-%m-%Y %H:%M:%S')

# === AUTHENTICATION HEADERS ===
HEADER_AUTH=(-H "X-Auth-Email: $CF_EMAIL" -H "X-Auth-Key: $API_KEY" -H "Content-Type: application/json")
CF_API="https://api.cloudflare.com/client/v4"

# === FUNCTIONS ===
list_banned() {
  echo "📋 List of blocked IPs:"
  curl -s -X GET "$CF_API/zones/$ZONE_ID/firewall/access_rules/rules" "${HEADER_AUTH[@]}" | \
    jq -r '.result[] | "\(.configuration.value) \(.configuration.target) \(.mode) - \(.notes)"'
}

ban_ip() {
  IP=$1
  if [ -z "$IP" ]; then
    echo "⚠️  Usage: cfm ban <IP>"
    exit 1
  fi

  if [[ $IP == *:* ]]; then
    TARGET="ip6"
  else
    TARGET="ip"
  fi

  echo "🚫 Blocking IP: $IP"
  curl -s -X POST "$CF_API/zones/$ZONE_ID/firewall/access_rules/rules" \
    "${HEADER_AUTH[@]}" \
    --data "{\"mode\":\"block\",\"configuration\":{\"target\":\"$TARGET\",\"value\":\"$IP\"},\"notes\":\"Banned via script\"}" | jq .
}

unban_ip() {
  IP=$1
  if [ -z "$IP" ]; then
    echo "⚠️  Usage: cfm unban <IP>"
    exit 1
  fi

  if [[ $IP == *:* ]]; then
    TARGET="ip6"
  else
    TARGET="ip"
  fi

  # Search for the rule ID based on IP and target type
  RULE_ID=$(curl -s -X GET "$CF_API/zones/$ZONE_ID/firewall/access_rules/rules" "${HEADER_AUTH[@]}" | jq -r ".result[] | select(.configuration.value==\"$IP\" and .configuration.target==\"$TARGET\") | .id")
  if [ -z "$RULE_ID" ]; then
    echo "❌ IP $IP not found in the block list."
    exit 1
  fi

  echo "✅ Unblocking IP: $IP"
  curl -s -X DELETE "$CF_API/zones/$ZONE_ID/firewall/access_rules/rules/$RULE_ID" "${HEADER_AUTH[@]}" | jq .
}

unban_all() {
  echo "⚠️ Unblocking all IPs (Zone + Account level)..."

  fetch_ids() {
    local endpoint="$1"
    local page=1
    local ids=""
    while :; do
      # Fetch rules page by page
      resp=$(curl -s -G "${HEADER_AUTH[@]}" --data-urlencode "page=$page" --data-urlencode "per_page=100" "$endpoint")
      # Extract IDs of rules that target 'ip' or 'ip6'
      page_ids=$(echo "$resp" | jq -r '.result[] | select(.configuration.target=="ip" or .configuration.target=="ip6") | .id' 2>/dev/null)
      if [ -n "$page_ids" ]; then
        ids="$ids"$'\n'"$page_ids"
      fi
      # Check total pages for loop termination
      total_pages=$(echo "$resp" | jq -r '.result_info.total_pages // 1' 2>/dev/null)
      if [ -z "$resp" ] || [ "$page" -ge "$total_pages" ]; then
        break
      fi
      page=$((page+1))
    done
    # Print unique IDs, filtered for empty lines
    echo "$ids" | sed '/^\s*$/d' | sort -u
  }

  delete_each() {
    local base="$1"
    local ids="$2"
    if [ -z "$ids" ]; then
      echo "ℹ️ No rules to delete for endpoint: $base"
      return
    fi
    # Loop through each ID and delete
    while IFS= read -r id; do
      [ -z "$id" ] && continue
      echo "🗑️ Deleting rule $id from $base ..."
      resp_del=$(curl -s -X DELETE "${HEADER_AUTH[@]}" "$base/$id")
      ok=$(echo "$resp_del" | jq -r '.success' 2>/dev/null)
      if [ "$ok" = "true" ]; then
        echo "✅ Rule $id deleted."
      else
        echo "❌ Failed to delete $id. API response:"
        # Print errors/messages if available, otherwise raw response
        echo "$resp_del" | jq -c '.errors, .messages' 2>/dev/null || echo "$resp_del"
      fi
      sleep 0.2
    done <<< "$ids"
  }

  zone_endpoint="$CF_API/zones/$ZONE_ID/firewall/access_rules/rules"
  echo "› Fetching rules at ZONE level..."
  ZONE_IDS=$(fetch_ids "$zone_endpoint")
  delete_each "$zone_endpoint" "$ZONE_IDS"

  account_endpoint="$CF_API/user/firewall/access_rules/rules"
  echo "› Fetching rules at ACCOUNT level..."
  ACCOUNT_IDS=$(fetch_ids "$account_endpoint")
  delete_each "$account_endpoint" "$ACCOUNT_IDS"

  echo "🎉 Finished processing all rules (zone & account)."
}

check_connection() {
  echo "🔍 Checking connection to Cloudflare..."
  # Check connection by fetching zone info (requires minimal permissions)
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$CF_API/zones/$ZONE_ID" "${HEADER_AUTH[@]}")
  if [ "$RESPONSE" -eq 200 ]; then
    echo "✅ Connection successful! Email and API Key are valid."
  else
    echo "❌ Connection failed! HTTP status code: $RESPONSE"
  fi
}

show_help() {
  echo "📖 Cloudflare Manager"
  echo ""
  echo "Usage: cfm <command> [argument]"
  echo ""
  echo "Available Commands:"
  echo "  list            - Display the list of blocked IPs"
  echo "  ban <IP>        - Block a specific IP"
  echo "  unban <IP>      - Unblock a specific IP"
  echo "  unban_all       - Unblock all IPs"
  echo "  check           - Check connection to Cloudflare"
  echo "  help            - Display this help message"
  echo ""
  echo "Example:"
  echo "  cfm ban 1.2.3.4"
  echo "  cfm unban 1.2.3.4"
  echo "  cfm unban_all"
  echo "  cfm check"
}

# === COMMAND ROUTER ===
case "$1" in
list) list_banned ;;
ban) ban_ip "$2" ;;
unban) unban_ip "$2" ;;
unban_all) unban_all ;;
check) check_connection ;;
help | "") show_help ;;
*)
  echo "❌ Unknown command: $1"
  show_help ;;
esac
