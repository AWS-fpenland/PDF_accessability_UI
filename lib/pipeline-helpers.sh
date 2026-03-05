#!/usr/bin/env bash
# =============================================================================
# pipeline-helpers.sh — Pure functions for the UI private CI/CD pipeline
# =============================================================================
# Sourced by deploy-private.sh. Contains testable logic with no side effects
# (no AWS CLI calls, no prompts).
# =============================================================================

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "ERROR: This file should be sourced, not executed directly." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# URL Validation
# ---------------------------------------------------------------------------
validate_repo_url() {
  local provider="$1"
  local url="$2"
  case "$provider" in
    github)
      [[ "$url" =~ ^https://github\.com/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?$ ]] && return 0 ;;
    codecommit)
      [[ "$url" =~ ^https://git-codecommit\.[a-z0-9-]+\.amazonaws\.com/v1/repos/[a-zA-Z0-9._-]+$ ]] && return 0 ;;
    bitbucket)
      [[ "$url" =~ ^https://bitbucket\.org/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?$ ]] && return 0 ;;
    gitlab)
      [[ "$url" =~ ^https://gitlab\.com/[a-zA-Z0-9._/-]+(\.git)?$ ]] && return 0 ;;
  esac
  return 1
}

# ---------------------------------------------------------------------------
# Branch Resolution
# ---------------------------------------------------------------------------
resolve_branch() {
  local input="${1:-}"
  if [[ -n "$input" ]]; then echo "$input"; else echo "main"; fi
}

# ---------------------------------------------------------------------------
# Connection Validation
# ---------------------------------------------------------------------------
validate_connection_status() {
  [[ "$1" == "AVAILABLE" ]] && return 0
  return 1
}

# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------
generate_trust_policy() {
  cat <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "codebuild.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# ---------------------------------------------------------------------------
# Config File Parsing
# ---------------------------------------------------------------------------
parse_config_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "ERROR: Config file not found: $path" >&2
    return 1
  fi
  local line_num=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*=.* ]]; then
      echo "$line"
    else
      echo "ERROR: Malformed line $line_num: $line" >&2
      return 1
    fi
  done < "$path"
}

# ---------------------------------------------------------------------------
# Source Configuration
# ---------------------------------------------------------------------------
configure_source() {
  local provider="$1"
  local url="$2"
  local branch="$3"
  local connection_arn="${4:-}"
  local buildspec="${5:-buildspec.yml}"

  if [[ "$provider" == "codecommit" ]]; then
    cat <<EOF
{"type":"CODECOMMIT","location":"${url}","buildspec":"${buildspec}"}
EOF
  else
    local source_type
    case "$provider" in
      github)    source_type="GITHUB" ;;
      bitbucket) source_type="BITBUCKET" ;;
      gitlab)    source_type="GITLAB" ;;
      *)         echo "ERROR: Unknown provider: $provider" >&2; return 1 ;;
    esac
    cat <<EOF
{"type":"${source_type}","location":"${url}","buildspec":"${buildspec}"}
EOF
  fi
}

# ---------------------------------------------------------------------------
# CLI Defaults
# ---------------------------------------------------------------------------
resolve_cli_defaults() {
  local buildspec_flag="${1:-}"
  local project_name_flag="${2:-}"
  if [[ -n "$buildspec_flag" ]]; then echo "$buildspec_flag"; else echo "buildspec.yml"; fi
  if [[ -n "$project_name_flag" ]]; then echo "$project_name_flag"; else echo "pdf-ui-$(date +%s)"; fi
}
