#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$REPO_ROOT/lemonade-configs"
SCHEMA_URL="${1:-${LEMONADE_BACKEND_SCHEMA_URL:-https://raw.githubusercontent.com/lemonade-sdk/lemonade/main/src/cpp/resources/backend_versions.json}}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

build_generated_config() {
  local backend="$1"
  local schema_file="$2"

  case "$backend" in
    rocm)
      jq --arg backend "$backend" '
        to_entries
        | map(
            select(.value | type == "object")
            | select(any(.value | keys[]?; startswith("rocm")))
            | {
                ((if .key == "sd-cpp" then "sdcpp" else .key end)): {
                  backend: $backend
                }
              }
          )
        | add // {}
      ' "$schema_file"
      ;;
    *)
      jq --arg backend "$backend" '
        to_entries
        | map(
            select(.value | type == "object")
            | select(.value[$backend]?)
            | {
                ((if .key == "sd-cpp" then "sdcpp" else .key end)): {
                  backend: $backend
                }
              }
          )
        | add // {}
      ' "$schema_file"
      ;;
  esac
}

update_config() {
  local backend="$1"
  local schema_file="$2"
  local config_file="$CONFIG_DIR/$backend.json"
  local existing_json generated_json merged_json

  existing_json='{}'
  if [[ -f "$config_file" ]]; then
    existing_json="$(jq '.' "$config_file")"
  fi

  generated_json="$(build_generated_config "$backend" "$schema_file")"
  merged_json="$(jq -n \
    --argjson existing "$existing_json" \
    --argjson generated "$generated_json" '
      $existing
      + $generated
      | to_entries
      | sort_by(.key)
      | from_entries
    ')"

  printf '%s\n' "$merged_json" > "$config_file"
  echo "Updated $config_file"
}

require_command curl
require_command jq

tmp_schema="$(mktemp)"
trap 'rm -f "$tmp_schema"' EXIT

curl -fsSL "$SCHEMA_URL" -o "$tmp_schema"

update_config cpu "$tmp_schema"
update_config cuda "$tmp_schema"
update_config rocm "$tmp_schema"
update_config vulkan "$tmp_schema"