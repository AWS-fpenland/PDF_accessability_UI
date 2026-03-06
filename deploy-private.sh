#!/usr/bin/env bash
# =============================================================================
# deploy-private.sh — Private CI/CD Pipeline Setup for PDF Accessibility UI
# =============================================================================
# Configures AWS CodeBuild to deploy the UI backend (CDK) and frontend (React
# on Amplify) from a private repository. Supports non-interactive mode via
# config file or environment variables, and cleanup of created resources.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/pipeline-helpers.sh"

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status()  { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
print_header()  { echo -e "${CYAN}$1${NC}"; }

# ---------------------------------------------------------------------------
# Global State
# ---------------------------------------------------------------------------
NON_INTERACTIVE="false"
CONFIG_FILE=""
CLI_BUILDSPEC=""
CLI_PROJECT_NAME=""
CLI_PROFILE=""
DO_CLEANUP="false"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
show_help() {
  cat <<'EOF'
Usage: deploy-private.sh [OPTIONS]

Deploy PDF Accessibility UI from a private repository.

Options:
  --config <path>           Path to key-value config file
  --non-interactive         Fail with error instead of prompting
  --buildspec <path>        Custom backend buildspec (default: buildspec.yml)
  --project-name <name>     Custom CodeBuild project name (default: pdf-ui-{timestamp})
  --profile <name>          AWS CLI named profile
  --cleanup                 List and delete pipeline resources
  --help                    Show this help message

Environment Variables (non-interactive mode):
  PRIVATE_REPO_URL          Git repository URL (required)
  SOURCE_PROVIDER           github, codecommit, bitbucket, or gitlab (required)
  TARGET_BRANCH             Branch name (default: main)
  CONNECTION_ARN            CodeConnections ARN (required for non-CodeCommit)
  PDF_TO_PDF_BUCKET         S3 bucket for PDF-to-PDF backend (at least one bucket required)
  PDF_TO_HTML_BUCKET        S3 bucket for PDF-to-HTML backend (at least one bucket required)
  SELF_SIGNUP               Enable self-service user registration: true or false (default: false)

Config File Format:
  PRIVATE_REPO_URL=https://github.com/myorg/my-fork.git
  SOURCE_PROVIDER=github
  TARGET_BRANCH=main
  CONNECTION_ARN=arn:aws:codeconnections:us-east-1:123456789:connection/abc-123
  PDF_TO_PDF_BUCKET=pdfaccessibility-bucket-123456789-us-east-1
  PDF_TO_HTML_BUCKET=pdf2html-bucket-123456789-us-east-1
  SELF_SIGNUP=false
EOF
}

# ---------------------------------------------------------------------------
# Argument Parsing
# ---------------------------------------------------------------------------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --config)           CONFIG_FILE="$2"; shift 2 ;;
      --non-interactive)  NON_INTERACTIVE="true"; shift ;;
      --buildspec)        CLI_BUILDSPEC="$2"; shift 2 ;;
      --project-name)     CLI_PROJECT_NAME="$2"; shift 2 ;;
      --profile)          CLI_PROFILE="$2"; shift 2 ;;
      --cleanup)          DO_CLEANUP="true"; shift ;;
      --help)             show_help; exit 0 ;;
      *)                  print_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Interactive Prompts
# ---------------------------------------------------------------------------
prompt_or_fail() {
  local param_name="$1"
  local prompt_text="$2"
  local current_value="${3:-}"

  if [[ -n "$current_value" ]]; then
    echo "$current_value"
    return 0
  fi

  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    print_error "Missing required parameter: $param_name"
    exit 1
  fi

  local response
  read -rp "$prompt_text" response
  echo "$response"
}

collect_parameters() {
  PRIVATE_REPO_URL="$(prompt_or_fail "PRIVATE_REPO_URL" \
    "Enter your private repository URL: " "${PRIVATE_REPO_URL:-}")"

  if [[ -z "${SOURCE_PROVIDER:-}" ]]; then
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
      print_error "Missing required parameter: SOURCE_PROVIDER"
      exit 1
    fi
    echo ""
    echo "Select your source provider:"
    echo "  1) github"
    echo "  2) codecommit"
    echo "  3) bitbucket"
    echo "  4) gitlab"
    local choice
    read -rp "Enter choice (1-4): " choice
    case "$choice" in
      1) SOURCE_PROVIDER="github" ;;
      2) SOURCE_PROVIDER="codecommit" ;;
      3) SOURCE_PROVIDER="bitbucket" ;;
      4) SOURCE_PROVIDER="gitlab" ;;
      *) print_error "Invalid choice: $choice"; exit 1 ;;
    esac
  fi

  TARGET_BRANCH="$(resolve_branch "${TARGET_BRANCH:-}")"

  # Connection ARN for non-CodeCommit providers
  if [[ "$SOURCE_PROVIDER" != "codecommit" && -z "${CONNECTION_ARN:-}" ]]; then
    CONNECTION_ARN="$(prompt_or_fail "CONNECTION_ARN" \
      "Enter your AWS CodeConnections ARN: " "${CONNECTION_ARN:-}")"
  fi

  # S3 bucket names — at least one required
  if [[ -z "${PDF_TO_PDF_BUCKET:-}" || "${PDF_TO_PDF_BUCKET}" == "Null" ]]; then
    PDF_TO_PDF_BUCKET="$(prompt_or_fail "PDF_TO_PDF_BUCKET" \
      "Enter PDF-to-PDF S3 bucket name (leave empty to skip): " "${PDF_TO_PDF_BUCKET:-}")" || true
  fi

  if [[ -z "${PDF_TO_HTML_BUCKET:-}" || "${PDF_TO_HTML_BUCKET}" == "Null" ]]; then
    PDF_TO_HTML_BUCKET="$(prompt_or_fail "PDF_TO_HTML_BUCKET" \
      "Enter PDF-to-HTML S3 bucket name (leave empty to skip): " "${PDF_TO_HTML_BUCKET:-}")" || true
  fi

  # Validate at least one bucket
  if [[ ( -z "${PDF_TO_PDF_BUCKET:-}" || "${PDF_TO_PDF_BUCKET}" == "Null" ) && \
        ( -z "${PDF_TO_HTML_BUCKET:-}" || "${PDF_TO_HTML_BUCKET}" == "Null" ) ]]; then
    print_error "At least one S3 bucket name is required (PDF_TO_PDF_BUCKET or PDF_TO_HTML_BUCKET)"
    exit 1
  fi

  # Self-service signup toggle
  if [[ -z "${SELF_SIGNUP:-}" ]]; then
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
      SELF_SIGNUP="false"
    else
      echo ""
      local signup_choice
      read -rp "Enable self-service user signup? (y/N): " signup_choice
      case "${signup_choice}" in
        [Yy]*) SELF_SIGNUP="true" ;;
        *)     SELF_SIGNUP="false" ;;
      esac
    fi
  fi
  print_status "Self-service signup: $SELF_SIGNUP"
}

# ---------------------------------------------------------------------------
# Input Validation
# ---------------------------------------------------------------------------
validate_inputs() {
  # Validate provider
  case "${SOURCE_PROVIDER:-}" in
    github|codecommit|bitbucket|gitlab) ;;
    *) print_error "Invalid source provider: '${SOURCE_PROVIDER:-}'"; exit 1 ;;
  esac

  # Validate URL format
  if ! validate_repo_url "$SOURCE_PROVIDER" "$PRIVATE_REPO_URL"; then
    print_error "Invalid repository URL for provider '$SOURCE_PROVIDER': $PRIVATE_REPO_URL"
    exit 1
  fi

  # Validate connection for non-CodeCommit
  if [[ "$SOURCE_PROVIDER" != "codecommit" ]]; then
    if [[ -z "${CONNECTION_ARN:-}" ]]; then
      print_error "CONNECTION_ARN is required for provider '$SOURCE_PROVIDER'"
      exit 1
    fi
    if [[ ! "$CONNECTION_ARN" =~ ^arn:aws:codeconnections:[a-z0-9-]+:[0-9]+:connection/.+$ ]]; then
      print_error "Invalid Connection ARN format: $CONNECTION_ARN"
      exit 1
    fi

    local conn_status
    conn_status="$(aws codeconnections get-connection \
      --connection-arn "$CONNECTION_ARN" \
      --query 'Connection.ConnectionStatus' \
      --output text 2>/dev/null)" || {
      print_error "Failed to retrieve connection status for: $CONNECTION_ARN"
      exit 1
    }
    if ! validate_connection_status "$conn_status"; then
      print_error "Connection is not AVAILABLE (current status: $conn_status)"
      exit 1
    fi
    print_success "Connection verified: AVAILABLE"

    # Register as CodeBuild source credential
    local existing_cred
    existing_cred="$(aws codebuild list-source-credentials \
      --query "sourceCredentialsInfos[?resource=='${CONNECTION_ARN}'].arn" \
      --output text 2>/dev/null || echo "")"

    if [[ -z "$existing_cred" || "$existing_cred" == "None" ]]; then
      print_status "Registering connection as CodeBuild source credential..."
      local server_type
      case "$SOURCE_PROVIDER" in
        github)    server_type="GITHUB" ;;
        bitbucket) server_type="BITBUCKET" ;;
        gitlab)    server_type="GITLAB" ;;
      esac
      aws codebuild import-source-credentials \
        --server-type "$server_type" \
        --auth-type CODECONNECTIONS \
        --token "$CONNECTION_ARN" > /dev/null 2>&1 || {
        print_error "Failed to register connection as source credential"
        exit 1
      }
      print_success "Connection registered as source credential"
    else
      print_success "Connection already registered as source credential"
    fi
  fi
}


# ---------------------------------------------------------------------------
# IAM Role and Policy
# ---------------------------------------------------------------------------
create_iam_role() {
  local role_name="$1"

  print_status "Setting up IAM role: $role_name"
  if aws iam get-role --role-name "$role_name" >/dev/null 2>&1; then
    print_success "Role '$role_name' already exists, reusing"
    ROLE_ARN="$(aws iam get-role --role-name "$role_name" --output json | jq -r '.Role.Arn')"
    return 0
  fi

  local trust_policy
  trust_policy="$(generate_trust_policy)"

  local create_output
  create_output="$(aws iam create-role \
    --role-name "$role_name" \
    --assume-role-policy-document "$trust_policy" \
    --output json)" || {
    print_error "Failed to create IAM role: $role_name"
    exit 1
  }

  ROLE_ARN="$(echo "$create_output" | jq -r '.Role.Arn')"
  print_success "Role created: $ROLE_ARN"

  print_status "Waiting 15s for IAM role propagation..."
  sleep 15
}

create_iam_policy() {
  local role_name="$1"

  # Scoped policy matching the existing deploy.sh policy structure
  local policy_doc
  policy_doc='{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AmplifyAccess",
        "Effect": "Allow",
        "Action": [
          "amplify:CreateApp", "amplify:CreateBranch", "amplify:CreateDeployment",
          "amplify:DeleteApp", "amplify:DeleteBranch", "amplify:GetApp",
          "amplify:GetBranch", "amplify:ListApps", "amplify:ListBranches",
          "amplify:StartDeployment", "amplify:StopJob", "amplify:UpdateApp",
          "amplify:UpdateBranch"
        ],
        "Resource": "arn:aws:amplify:'"$REGION"':'"$ACCOUNT_ID"':apps/*"
      },
      {
        "Sid": "CognitoAccess",
        "Effect": "Allow",
        "Action": [
          "cognito-idp:CreateUserPool", "cognito-idp:DeleteUserPool",
          "cognito-idp:DescribeUserPool", "cognito-idp:UpdateUserPool",
          "cognito-idp:CreateUserPoolClient", "cognito-idp:DeleteUserPoolClient",
          "cognito-idp:DescribeUserPoolClient",
          "cognito-idp:CreateUserPoolDomain", "cognito-idp:DeleteUserPoolDomain",
          "cognito-idp:DescribeUserPoolDomain",
          "cognito-idp:CreateGroup", "cognito-idp:DeleteGroup", "cognito-idp:GetGroup",
          "cognito-idp:SetUICustomization", "cognito-idp:SetUserPoolMfaConfig",
          "cognito-idp:CreateManagedLoginBranding", "cognito-idp:UpdateManagedLoginBranding",
          "cognito-idp:DeleteManagedLoginBranding", "cognito-idp:DescribeManagedLoginBranding",
          "cognito-idp:DescribeManagedLoginBrandingByClient",
          "cognito-idp:TagResource", "cognito-idp:UntagResource",
          "cognito-idp:ListTagsForResource"
        ],
        "Resource": "arn:aws:cognito-idp:'"$REGION"':'"$ACCOUNT_ID"':userpool/*"
      },
      {
        "Sid": "CognitoIdentityAccess",
        "Effect": "Allow",
        "Action": [
          "cognito-identity:CreateIdentityPool", "cognito-identity:DeleteIdentityPool",
          "cognito-identity:DescribeIdentityPool", "cognito-identity:UpdateIdentityPool",
          "cognito-identity:SetIdentityPoolRoles", "cognito-identity:GetIdentityPoolRoles",
          "cognito-identity:TagResource"
        ],
        "Resource": "arn:aws:cognito-identity:'"$REGION"':'"$ACCOUNT_ID"':identitypool/*"
      },
      {
        "Sid": "LambdaAccess",
        "Effect": "Allow",
        "Action": [
          "lambda:CreateFunction", "lambda:DeleteFunction", "lambda:GetFunction",
          "lambda:GetFunctionConfiguration", "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration", "lambda:AddPermission",
          "lambda:RemovePermission", "lambda:InvokeFunction",
          "lambda:ListTags", "lambda:TagResource", "lambda:UntagResource",
          "lambda:PublishVersion", "lambda:ListVersionsByFunction"
        ],
        "Resource": "arn:aws:lambda:'"$REGION"':'"$ACCOUNT_ID"':function:*"
      },
      {
        "Sid": "APIGatewayAccess",
        "Effect": "Allow",
        "Action": [
          "apigateway:GET", "apigateway:POST", "apigateway:PUT",
          "apigateway:DELETE", "apigateway:PATCH", "apigateway:TagResource"
        ],
        "Resource": "arn:aws:apigateway:'"$REGION"'::/*"
      },
      {
        "Sid": "IAMRoleAccess",
        "Effect": "Allow",
        "Action": [
          "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:PassRole",
          "iam:AttachRolePolicy", "iam:DetachRolePolicy",
          "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",
          "iam:TagRole", "iam:UntagRole",
          "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
          "iam:CreatePolicy", "iam:DeletePolicy", "iam:GetPolicy",
          "iam:GetPolicyVersion", "iam:ListPolicyVersions"
        ],
        "Resource": [
          "arn:aws:iam::'"$ACCOUNT_ID"':role/pdf-ui-*",
          "arn:aws:iam::'"$ACCOUNT_ID"':role/CdkBackendStack-*",
          "arn:aws:iam::'"$ACCOUNT_ID"':role/cdk-*",
          "arn:aws:iam::'"$ACCOUNT_ID"':policy/CdkBackendStack-*"
        ]
      },
      {
        "Sid": "IAMPassRoleForServices",
        "Effect": "Allow",
        "Action": "iam:PassRole",
        "Resource": "arn:aws:iam::'"$ACCOUNT_ID"':role/*",
        "Condition": {
          "StringEquals": {
            "iam:PassedToService": [
              "lambda.amazonaws.com",
              "cognito-idp.amazonaws.com",
              "apigateway.amazonaws.com",
              "events.amazonaws.com"
            ]
          }
        }
      },
      {
        "Sid": "S3CDKAccess",
        "Effect": "Allow",
        "Action": [
          "s3:GetObject", "s3:PutObject", "s3:GetBucketLocation",
          "s3:ListBucket", "s3:CreateBucket",
          "s3:GetEncryptionConfiguration", "s3:PutEncryptionConfiguration",
          "s3:GetBucketVersioning", "s3:PutBucketVersioning",
          "s3:PutBucketPublicAccessBlock", "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPolicy", "s3:GetBucketPolicy", "s3:DeleteBucketPolicy"
        ],
        "Resource": ["arn:aws:s3:::cdk-*", "arn:aws:s3:::cdk-*/*"]
      },
      {
        "Sid": "S3BucketCorsAccess",
        "Effect": "Allow",
        "Action": ["s3:PutBucketCORS", "s3:GetBucketCORS"],
        "Resource": ["arn:aws:s3:::*"]
      },
      {
        "Sid": "SecretsManagerAccess",
        "Effect": "Allow",
        "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        "Resource": "arn:aws:secretsmanager:'"$REGION"':'"$ACCOUNT_ID"':secret:*"
      },
      {
        "Sid": "CloudFormationAccess",
        "Effect": "Allow",
        "Action": [
          "cloudformation:CreateStack", "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks", "cloudformation:DescribeStackEvents",
          "cloudformation:GetTemplate", "cloudformation:UpdateStack",
          "cloudformation:CreateChangeSet", "cloudformation:DeleteChangeSet",
          "cloudformation:DescribeChangeSet", "cloudformation:ExecuteChangeSet",
          "cloudformation:GetTemplateSummary", "cloudformation:ListStackResources"
        ],
        "Resource": [
          "arn:aws:cloudformation:'"$REGION"':'"$ACCOUNT_ID"':stack/CdkBackendStack/*",
          "arn:aws:cloudformation:'"$REGION"':'"$ACCOUNT_ID"':stack/CDKToolkit/*"
        ]
      },
      {
        "Sid": "CloudFormationGlobal",
        "Effect": "Allow",
        "Action": ["cloudformation:ListStacks", "cloudformation:GetTemplateSummary"],
        "Resource": "*"
      },
      {
        "Sid": "CloudTrailAccess",
        "Effect": "Allow",
        "Action": [
          "cloudtrail:CreateTrail", "cloudtrail:DeleteTrail",
          "cloudtrail:DescribeTrails", "cloudtrail:GetTrailStatus",
          "cloudtrail:StartLogging", "cloudtrail:StopLogging",
          "cloudtrail:PutEventSelectors", "cloudtrail:AddTags"
        ],
        "Resource": "arn:aws:cloudtrail:'"$REGION"':'"$ACCOUNT_ID"':trail/*"
      },
      {
        "Sid": "EventsAccess",
        "Effect": "Allow",
        "Action": [
          "events:PutRule", "events:DeleteRule", "events:DescribeRule",
          "events:PutTargets", "events:RemoveTargets",
          "events:EnableRule", "events:DisableRule", "events:TagResource"
        ],
        "Resource": "arn:aws:events:'"$REGION"':'"$ACCOUNT_ID"':rule/*"
      },
      {
        "Sid": "CloudWatchLogsAccess",
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents",
          "logs:DeleteLogGroup", "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy", "logs:TagResource"
        ],
        "Resource": [
          "arn:aws:logs:'"$REGION"':'"$ACCOUNT_ID"':log-group:*",
          "arn:aws:logs:'"$REGION"':'"$ACCOUNT_ID"':log-group:*:*"
        ]
      },
      {
        "Sid": "STSAccess",
        "Effect": "Allow",
        "Action": ["sts:GetCallerIdentity", "sts:AssumeRole"],
        "Resource": "*"
      },
      {
        "Sid": "SSMBootstrap",
        "Effect": "Allow",
        "Action": "ssm:GetParameter",
        "Resource": "arn:aws:ssm:'"$REGION"':'"$ACCOUNT_ID"':parameter/cdk-bootstrap/*"
      },
      {
        "Sid": "CodeConnectionsAccess",
        "Effect": "Allow",
        "Action": [
          "codeconnections:UseConnection", "codeconnections:GetConnection",
          "codeconnections:GetConnectionToken", "codeconnections:PassConnectionToService"
        ],
        "Resource": "arn:aws:codeconnections:*:*:connection/*"
      }
    ]
  }'

  print_status "Attaching deployment policy to role..."
  aws iam put-role-policy \
    --role-name "$role_name" \
    --policy-name "DeploymentPolicy" \
    --policy-document "$policy_doc" || {
    print_error "Failed to attach policy to role"
    exit 1
  }
  print_success "Policy attached to role: $role_name"
}


# ---------------------------------------------------------------------------
# CodeBuild Project Creation
# ---------------------------------------------------------------------------
create_codebuild_project() {
  local project_name="$1"
  local buildspec="$2"
  local env_vars_json="$3"

  print_status "Creating CodeBuild project: $project_name"

  local source_json
  source_json="$(configure_source "$SOURCE_PROVIDER" "$PRIVATE_REPO_URL" \
    "$TARGET_BRANCH" "${CONNECTION_ARN:-}" "$buildspec")"

  local env_json
  env_json="{\"type\":\"LINUX_CONTAINER\",\"image\":\"aws/codebuild/amazonlinux-x86_64-standard:5.0\",\"computeType\":\"BUILD_GENERAL1_SMALL\"}"
  env_json="$(echo "$env_json" | jq --argjson ev "$env_vars_json" '.environmentVariables = $ev')"

  local create_output
  create_output="$(aws codebuild create-project \
    --name "$project_name" \
    --source "$source_json" \
    --source-version "$TARGET_BRANCH" \
    --artifacts '{"type":"NO_ARTIFACTS"}' \
    --environment "$env_json" \
    --service-role "$ROLE_ARN" \
    --output json 2>&1)" || {
    if echo "$create_output" | grep -qi "already exists"; then
      print_warning "CodeBuild project '$project_name' already exists, reusing"
    else
      print_error "Failed to create CodeBuild project: $project_name"
      print_error "$create_output"
      exit 1
    fi
  }

  # Verify project exists
  if ! aws codebuild batch-get-projects --names "$project_name" \
      --query 'projects[0].name' --output text 2>/dev/null | grep -q "$project_name"; then
    print_error "CodeBuild project '$project_name' not found after creation attempt"
    exit 1
  fi

  print_success "CodeBuild project ready: $project_name"
}

# ---------------------------------------------------------------------------
# Build Monitoring
# ---------------------------------------------------------------------------
show_build_logs() {
  local project_name="$1"
  local log_group="/aws/codebuild/$project_name"

  sleep 5
  local latest_stream
  latest_stream="$(aws logs describe-log-streams \
    --log-group-name "$log_group" \
    --order-by LastEventTime --descending --max-items 1 \
    --query 'logStreams[0].logStreamName' --output text 2>/dev/null || echo "")"

  if [[ -n "$latest_stream" && "$latest_stream" != "None" ]]; then
    print_error "Recent build logs:"
    aws logs get-log-events \
      --log-group-name "$log_group" \
      --log-stream-name "$latest_stream" \
      --query 'events[-30:].message' --output text 2>/dev/null || \
      print_error "Could not retrieve logs"
  else
    print_error "Could not retrieve build logs. Check CodeBuild console."
  fi
}

start_and_monitor_build() {
  local project_name="$1"
  local source_version="$2"

  print_status "Starting build for project '$project_name'..."

  local build_response
  build_response="$(aws codebuild start-build \
    --project-name "$project_name" \
    --source-version "$source_version" \
    --output json)" || {
    print_error "Failed to start build"
    exit 1
  }

  local build_id
  build_id="$(echo "$build_response" | jq -r '.build.id')"
  print_success "Build started: $build_id"

  print_status "Monitoring build progress..."
  local dots=0 last_status=""
  while true; do
    local build_status
    build_status="$(aws codebuild batch-get-builds --ids "$build_id" \
      --query 'builds[0].buildStatus' --output text)"

    if [[ "$build_status" != "$last_status" ]]; then
      echo ""
      print_status "Build status: $build_status"
      last_status="$build_status"
      dots=0
    fi

    case "$build_status" in
      SUCCEEDED)
        echo ""
        print_success "Build completed successfully!"
        return 0
        ;;
      FAILED|FAULT|STOPPED|TIMED_OUT)
        echo ""
        print_error "Build failed with status: $build_status"
        show_build_logs "$project_name"
        return 1
        ;;
      IN_PROGRESS)
        printf "."
        dots=$((dots + 1))
        if [[ $dots -eq 60 ]]; then
          echo ""
          print_status "Still building..."
          dots=0
        fi
        sleep 5
        ;;
      *)
        printf "."
        sleep 3
        ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Frontend Deployment (after backend CDK stack is up)
# ---------------------------------------------------------------------------
deploy_frontend() {
  local project_name="$1"

  print_header "Deploying Frontend..."

  # Retrieve CDK stack outputs
  print_status "Retrieving CDK stack outputs from CdkBackendStack..."
  local cdk_outputs
  cdk_outputs="$(aws cloudformation describe-stacks \
    --stack-name CdkBackendStack \
    --query 'Stacks[0].Outputs' \
    --output json 2>/dev/null)" || {
    print_error "Could not retrieve CdkBackendStack outputs. Is the backend deployed?"
    return 1
  }

  if [[ -z "$cdk_outputs" || "$cdk_outputs" == "null" ]]; then
    print_error "CdkBackendStack has no outputs"
    return 1
  fi

  # Extract outputs
  local amplify_app_id user_pool_id user_pool_client_id user_pool_domain
  local identity_pool_id update_first_sign_in_endpoint check_upload_quota_endpoint
  local amplify_app_url update_attributes_api_endpoint

  amplify_app_id="$(echo "$cdk_outputs" | jq -r '.[] | select(.OutputKey == "AmplifyAppId") | .OutputValue')"
  amplify_app_url="$(echo "$cdk_outputs" | jq -r '.[] | select(.OutputKey == "AmplifyAppURL") | .OutputValue')"
  user_pool_id="$(echo "$cdk_outputs" | jq -r '.[] | select(.OutputKey == "UserPoolId") | .OutputValue')"
  user_pool_client_id="$(echo "$cdk_outputs" | jq -r '.[] | select(.OutputKey == "UserPoolClientId") | .OutputValue')"
  user_pool_domain="$(echo "$cdk_outputs" | jq -r '.[] | select(.OutputKey == "UserPoolDomain") | .OutputValue')"
  identity_pool_id="$(echo "$cdk_outputs" | jq -r '.[] | select(.OutputKey == "IdentityPoolId") | .OutputValue')"
  update_first_sign_in_endpoint="$(echo "$cdk_outputs" | jq -r '.[] | select(.OutputKey == "UpdateFirstSignInEndpoint") | .OutputValue')"
  check_upload_quota_endpoint="$(echo "$cdk_outputs" | jq -r '.[] | select(.OutputKey == "CheckUploadQuotaEndpoint") | .OutputValue')"
  update_attributes_api_endpoint="$(echo "$cdk_outputs" | jq -r '.[] | select(.OutputKey == "UpdateAttributesApiEndpoint377B5108") | .OutputValue')"

  if [[ -z "$amplify_app_id" || "$amplify_app_id" == "null" ]]; then
    print_error "Could not find AmplifyAppId in CDK stack outputs"
    return 1
  fi

  print_success "Retrieved CDK outputs (Amplify App: $amplify_app_id)"

  # Build frontend env vars JSON
  local fe_env_vars="["
  local first=true

  add_fe_env() {
    local name="$1" value="$2"
    if [[ -n "$value" && "$value" != "null" ]]; then
      if [[ "$first" != "true" ]]; then fe_env_vars+=","; fi
      fe_env_vars+="{\"name\":\"$name\",\"value\":\"$value\",\"type\":\"PLAINTEXT\"}"
      first=false
    fi
  }

  # Bucket vars
  if [[ -n "${PDF_TO_PDF_BUCKET:-}" && "${PDF_TO_PDF_BUCKET}" != "Null" ]]; then
    add_fe_env "PDF_TO_PDF_BUCKET" "$PDF_TO_PDF_BUCKET"
  fi
  if [[ -n "${PDF_TO_HTML_BUCKET:-}" && "${PDF_TO_HTML_BUCKET}" != "Null" ]]; then
    add_fe_env "PDF_TO_HTML_BUCKET" "$PDF_TO_HTML_BUCKET"
  fi

  # CDK output vars
  add_fe_env "AMPLIFY_APP_ID" "$amplify_app_id"
  add_fe_env "REACT_APP_AMPLIFY_APP_URL" "$amplify_app_url"
  add_fe_env "REACT_APP_USER_POOL_ID" "$user_pool_id"
  add_fe_env "REACT_APP_USER_POOL_CLIENT_ID" "$user_pool_client_id"
  add_fe_env "REACT_APP_USER_POOL_DOMAIN" "$user_pool_domain"
  add_fe_env "REACT_APP_IDENTITY_POOL_ID" "$identity_pool_id"
  add_fe_env "REACT_APP_UPDATE_FIRST_SIGN_IN_ENDPOINT" "$update_first_sign_in_endpoint"
  add_fe_env "REACT_APP_CHECK_UPLOAD_QUOTA_ENDPOINT" "$check_upload_quota_endpoint"
  add_fe_env "REACT_APP_UPDATE_ATTRIBUTES_API_ENDPOINT" "$update_attributes_api_endpoint"

  fe_env_vars+="]"

  # Create frontend CodeBuild project
  local frontend_project="${project_name}-frontend"

  # Use MEDIUM compute for frontend build (React build is memory-hungry)
  print_status "Creating frontend CodeBuild project: $frontend_project"

  local source_json
  source_json="$(configure_source "$SOURCE_PROVIDER" "$PRIVATE_REPO_URL" \
    "$TARGET_BRANCH" "${CONNECTION_ARN:-}" "buildspec-frontend.yml")"

  local env_json
  env_json="{\"type\":\"LINUX_CONTAINER\",\"image\":\"aws/codebuild/amazonlinux-x86_64-standard:5.0\",\"computeType\":\"BUILD_GENERAL1_MEDIUM\"}"
  env_json="$(echo "$env_json" | jq --argjson ev "$fe_env_vars" '.environmentVariables = $ev')"

  local create_output
  create_output="$(aws codebuild create-project \
    --name "$frontend_project" \
    --source "$source_json" \
    --source-version "$TARGET_BRANCH" \
    --artifacts '{"type":"NO_ARTIFACTS"}' \
    --environment "$env_json" \
    --service-role "$ROLE_ARN" \
    --output json 2>&1)" || {
    if echo "$create_output" | grep -qi "already exists"; then
      print_warning "CodeBuild project '$frontend_project' already exists, reusing"
    else
      print_error "Failed to create frontend CodeBuild project"
      print_error "$create_output"
      return 1
    fi
  }

  print_success "Frontend CodeBuild project ready: $frontend_project"

  # Start and monitor frontend build
  if start_and_monitor_build "$frontend_project" "$TARGET_BRANCH"; then
    print_success "Frontend deployed to: $amplify_app_url"
    AMPLIFY_URL="$amplify_app_url"
    return 0
  else
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
cleanup_resources() {
  print_header "Cleaning up UI pipeline resources..."

  local all_projects
  all_projects="$(aws codebuild list-projects --query 'projects' --output text 2>/dev/null | tr '\t' '\n')"

  local matching=""
  while IFS= read -r project; do
    [[ -z "$project" ]] && continue
    case "$project" in
      pdf-ui-*) matching+="$project"$'\n' ;;
    esac
  done <<< "$all_projects"

  if [[ -z "$matching" ]]; then
    print_status "No matching pdf-ui-* resources found."
    return 0
  fi

  echo ""
  print_status "Resources to delete:"
  echo "$matching" | while read -r p; do
    [[ -n "$p" ]] && print_status "  - CodeBuild project: $p"
  done

  if [[ "$NON_INTERACTIVE" != "true" ]]; then
    local confirm
    read -rp "Proceed with deletion? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      print_status "Cleanup cancelled."
      return 0
    fi
  fi

  local failed=()
  while IFS= read -r project; do
    [[ -z "$project" ]] && continue
    print_status "Deleting: $project"
    aws codebuild delete-project --name "$project" 2>/dev/null || {
      print_warning "Failed to delete project: $project"
      failed+=("$project")
    }
  done <<< "$matching"

  # Clean up IAM roles matching pdf-ui-*-service-role
  local all_roles
  all_roles="$(aws iam list-roles --query "Roles[?starts_with(RoleName, 'pdf-ui-')].RoleName" --output text 2>/dev/null | tr '\t' '\n')"
  while IFS= read -r role; do
    [[ -z "$role" ]] && continue
    print_status "Deleting IAM role: $role"
    # Remove inline policies first
    local policies
    policies="$(aws iam list-role-policies --role-name "$role" --query 'PolicyNames' --output text 2>/dev/null | tr '\t' '\n')"
    while IFS= read -r pol; do
      [[ -z "$pol" ]] && continue
      aws iam delete-role-policy --role-name "$role" --policy-name "$pol" 2>/dev/null || true
    done <<< "$policies"
    aws iam delete-role --role-name "$role" 2>/dev/null || {
      print_warning "Failed to delete role: $role"
      failed+=("$role")
    }
  done <<< "$all_roles"

  if [[ ${#failed[@]} -gt 0 ]]; then
    print_warning "Failed to delete ${#failed[@]} resource(s)"
    return 1
  fi

  print_success "Cleanup complete!"
}


# ---------------------------------------------------------------------------
# Main Orchestration
# ---------------------------------------------------------------------------
main() {
  parse_args "$@"

  # Handle cleanup mode
  if [[ "$DO_CLEANUP" == "true" ]]; then
    if [[ -n "$CLI_PROFILE" ]]; then
      export AWS_PROFILE="$CLI_PROFILE"
      print_status "Using AWS profile: $AWS_PROFILE"
    fi
    ACCOUNT_ID="$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)" || {
      print_error "AWS CLI not configured. Run 'aws configure' first."
      exit 1
    }
    cleanup_resources
    exit $?
  fi

  # Welcome
  echo ""
  print_header "🔒 PDF Accessibility UI — Private Pipeline Setup"
  print_header "=================================================="
  echo ""

  # Apply AWS profile
  if [[ -n "$CLI_PROFILE" ]]; then
    export AWS_PROFILE="$CLI_PROFILE"
    print_status "Using AWS profile: $AWS_PROFILE"
  elif [[ -n "${AWS_PROFILE:-}" ]]; then
    print_status "Using AWS profile from environment: $AWS_PROFILE"
  fi

  # Get AWS identity
  print_status "Verifying AWS credentials..."
  ACCOUNT_ID="$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)" || {
    print_error "AWS CLI not configured. Run 'aws configure' first."
    exit 1
  }
  REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"
  if [[ -z "$REGION" ]]; then
    REGION="$(aws configure get region 2>/dev/null || echo "")"
  fi
  if [[ -z "$REGION" ]]; then
    print_error "Could not determine AWS region. Set AWS_DEFAULT_REGION or run: aws configure set region <region>"
    exit 1
  fi
  print_success "Account: $ACCOUNT_ID, Region: $REGION"

  # Load config file if provided
  if [[ -n "$CONFIG_FILE" ]]; then
    print_status "Loading config from: $CONFIG_FILE"
    eval "$(parse_config_file "$CONFIG_FILE")" || exit 1
  fi

  # Collect parameters
  collect_parameters

  # Resolve CLI defaults
  local cli_defaults
  cli_defaults="$(resolve_cli_defaults "$CLI_BUILDSPEC" "$CLI_PROJECT_NAME")"
  BUILDSPEC_FILE="$(echo "$cli_defaults" | head -1)"
  PROJECT_NAME="$(echo "$cli_defaults" | tail -1)"

  # Validate inputs
  validate_inputs

  # Create IAM role and attach policy
  local role_name="${PROJECT_NAME}-service-role"
  create_iam_role "$role_name"
  create_iam_policy "$role_name"

  # Wait for IAM policy propagation after attachment
  print_status "Waiting 15s for IAM policy propagation..."
  sleep 15

  # --- Phase 1: Backend CDK deployment ---
  print_header "Phase 1: Deploying Backend (CDK Stack)..."

  # Build backend env vars
  local backend_env_vars="["
  local first=true

  add_env() {
    local name="$1" value="$2"
    if [[ -n "$value" && "$value" != "Null" ]]; then
      if [[ "$first" != "true" ]]; then backend_env_vars+=","; fi
      backend_env_vars+="{\"name\":\"$name\",\"value\":\"$value\",\"type\":\"PLAINTEXT\"}"
      first=false
    fi
  }

  add_env "PDF_TO_PDF_BUCKET" "${PDF_TO_PDF_BUCKET:-}"
  add_env "PDF_TO_HTML_BUCKET" "${PDF_TO_HTML_BUCKET:-}"
  add_env "SELF_SIGNUP" "${SELF_SIGNUP:-false}"
  backend_env_vars+="]"

  local backend_project="${PROJECT_NAME}-backend"
  create_codebuild_project "$backend_project" "$BUILDSPEC_FILE" "$backend_env_vars"

  if ! start_and_monitor_build "$backend_project" "$TARGET_BRANCH"; then
    print_error "Backend deployment failed. Cannot proceed with frontend."
    exit 1
  fi

  # --- Phase 2: Frontend deployment ---
  print_header "Phase 2: Deploying Frontend (React on Amplify)..."

  AMPLIFY_URL=""
  if ! deploy_frontend "$PROJECT_NAME"; then
    print_error "Frontend deployment failed."
    exit 1
  fi

  # --- Summary ---
  echo ""
  print_header "🎉 Deployment Complete!"
  print_header "======================="
  echo ""
  print_status "Backend Project:  ${backend_project}"
  print_status "Frontend Project: ${PROJECT_NAME}-frontend"
  print_status "CDK Stack:        CdkBackendStack"
  if [[ -n "${AMPLIFY_URL:-}" ]]; then
    print_status "Frontend URL:     $AMPLIFY_URL"
  fi
  echo ""
  print_success "Pipeline setup complete!"
}

# ---------------------------------------------------------------------------
# Entry Point
# ---------------------------------------------------------------------------
main "$@"
