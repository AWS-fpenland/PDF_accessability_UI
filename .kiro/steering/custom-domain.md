# Adding a Custom Domain to the Amplify-Hosted UI

This is a step-by-step playbook for adding an optional custom domain (with auto-managed ACM certificate) to the PDF Accessibility UI. It's written so that an AI coding agent working on a fork of this repository can reproduce the same set of changes mechanically.

The end result is a `CUSTOM_DOMAIN` knob that flows through the CDK backend, the CodeBuild pipelines, and the frontend buildspec — so a single env var (or CDK context value) attaches a domain to the Amplify app, switches the canonical app URL, updates Cognito callbacks and S3 CORS, and bakes the right hosted UI URL into the React bundle.

## Goal

Given a forked copy of `PDF_accessability_UI`, add a `CUSTOM_DOMAIN` parameter such that:

- When unset: behavior is identical to the original — app served at `https://main.<appId>.amplifyapp.com`.
- When set to a bare hostname (e.g. `app.example.edu`): Amplify Hosting attaches the domain, issues an ACM cert, and the React app, Cognito callbacks, and S3 CORS all key off `https://app.example.edu`. The default `*.amplifyapp.com` URL keeps working too.

Amplify Hosting handles the cert lifecycle. The customer adds DNS records once at their registrar and Amplify renews automatically. **Do not** front this with a separately-managed ACM certificate or CloudFront distribution — that's a different architecture.

## Files Touched (5)

| File | Type of change |
|---|---|
| `cdk_backend/lib/cdk_backend-stack.ts` | Add `CUSTOM_DOMAIN` context handling, `addDomain` call, conditional Cognito/CORS/output wiring |
| `buildspec.yml` | Forward `CUSTOM_DOMAIN` to `cdk bootstrap` and `cdk deploy` |
| `buildspec-frontend.yml` | Read all CDK outputs from CloudFormation at build time so the canonical URL flows through automatically |
| `deploy.sh` / `deploy-private.sh` / `deploy-full-stack-local.sh` / `deploy-amplify-direct.sh` / `deploy-frontend.sh` | Surface the parameter to interactive and non-interactive callers |
| `pipeline.conf.example` | Document the optional `CUSTOM_DOMAIN` config-file entry |

The IAM policy created by `deploy.sh` and `deploy-private.sh` already grants `cloudformation:DescribeStacks` on `stack/CdkBackendStack/*`, so no policy changes are needed for the buildspec rewrite.

## Step 1 — CDK Stack Changes

File: `cdk_backend/lib/cdk_backend-stack.ts`

Right after `mainBranch` is created and before the SPA redirect rules, replace the hard-coded `appUrl` block with a custom-domain-aware version.

**Before:**

```ts
// Domain prefix must be globally unique per region. Using the AWS account
// ID so it's stable across deploys but unique across accounts.
// Override with CDK context: -c DOMAIN_PREFIX=my-custom-prefix
const domainPrefix = this.node.tryGetContext('DOMAIN_PREFIX')
  || `pdf-ui-auth-${this.account}`;
const Default_Group = 'DefaultUsers';
const Amazon_Group = 'AmazonUsers';
const Admin_Group = 'AdminUsers';
const appUrl = `https://main.${amplifyApp.appId}.amplifyapp.com`;
```

**After:**

```ts
// Domain prefix must be globally unique per region. Using the AWS account
// ID so it's stable across deploys but unique across accounts.
// Override with CDK context: -c DOMAIN_PREFIX=my-custom-prefix
const domainPrefix = this.node.tryGetContext('DOMAIN_PREFIX')
  || `pdf-ui-auth-${this.account}`;
const Default_Group = 'DefaultUsers';
const Amazon_Group = 'AmazonUsers';
const Admin_Group = 'AdminUsers';

// --------- Optional Custom Domain ----------
// Pass with: -c CUSTOM_DOMAIN=app.example.edu  (bare hostname, no scheme)
// Amplify Hosting issues and renews the ACM certificate automatically.
// After deploy, create the validation/CNAME records Amplify shows in the
// console (or in CloudFormation events) at your DNS provider.
const customDomainName: string | undefined =
  this.node.tryGetContext('CUSTOM_DOMAIN') || undefined;

const defaultAmplifyUrl = `https://main.${amplifyApp.appId}.amplifyapp.com`;
const customDomainUrl = customDomainName ? `https://${customDomainName}` : undefined;

// Primary app URL — custom domain takes precedence when present so the
// React app, Cognito callbacks, and CORS all key off the canonical host.
const appUrl = customDomainUrl || defaultAmplifyUrl;

if (customDomainName) {
  const customDomain = amplifyApp.addDomain(customDomainName, {
    enableAutoSubdomain: false,
  });
  customDomain.mapRoot(mainBranch);
  // Also serve www.<customDomainName> if customers hit it directly.
  // Comment out if you don't want the www subdomain.
  customDomain.mapSubDomain(mainBranch, 'www');
}
```

Then update the S3 CORS `AllowedOrigins` (search for `AllowedOrigins: [appUrl, 'http://localhost:3000']`):

```ts
AllowedOrigins: customDomainUrl
  ? [customDomainUrl, defaultAmplifyUrl, 'http://localhost:3000']
  : [defaultAmplifyUrl, 'http://localhost:3000'],
```

Update the Cognito user pool client (search for `callbackUrls:` on the user pool client construct):

```ts
callbackUrls: customDomainUrl
  ? [`${customDomainUrl}/callback`, `${defaultAmplifyUrl}/callback`, "http://localhost:3000/callback"]
  : [`${defaultAmplifyUrl}/callback`, "http://localhost:3000/callback"],
logoutUrls: customDomainUrl
  ? [`${customDomainUrl}/home`, `${defaultAmplifyUrl}/home`, "http://localhost:3000/home"]
  : [`${defaultAmplifyUrl}/home`, "http://localhost:3000/home"],
```

Add two new CFN outputs near the existing `AmplifyAppId` / `AmplifyAppURL` outputs:

```ts
if (customDomainUrl) {
  new cdk.CfnOutput(this, 'AmplifyCustomDomain', {
    value: customDomainName!,
    description: 'Custom domain attached to the Amplify app',
  });
  new cdk.CfnOutput(this, 'AmplifyCustomDomainURL', {
    value: customDomainUrl,
    description: 'Custom domain URL (https://<custom-domain>)',
  });
}
```

The `appUrl` variable is referenced later when populating `mainBranch.addEnvironment('REACT_APP_HOSTED_UI_URL', appUrl)` — that line keeps working unchanged because `appUrl` now evaluates to the custom domain when set.

## Step 2 — Backend Buildspec

File: `buildspec.yml`

Forward `CUSTOM_DOMAIN` to both `cdk bootstrap` and `cdk deploy` only when set. The `${VAR:+...}` shell expansion is the cleanest pattern — empty values produce no flag at all, so legacy projects without the env var are unaffected.

```yaml
pre_build:
  commands:
    - echo "Building TypeScript sources"
    - npm run build
    - echo "Bootstrapping CDK (no approval)..."
    - >-
      cdk bootstrap --require-approval never \
        -c PDF_TO_PDF_BUCKET=$PDF_TO_PDF_BUCKET \
        -c PDF_TO_HTML_BUCKET=$PDF_TO_HTML_BUCKET \
        -c SELF_SIGNUP=${SELF_SIGNUP:-false} \
        ${CUSTOM_DOMAIN:+-c CUSTOM_DOMAIN=$CUSTOM_DOMAIN}

build:
  commands:
    - echo "Deploying all CDK stacks..."
    - >-
      cdk deploy --all --require-approval never \
        -c PDF_TO_PDF_BUCKET=$PDF_TO_PDF_BUCKET \
        -c PDF_TO_HTML_BUCKET=$PDF_TO_HTML_BUCKET \
        -c SELF_SIGNUP=${SELF_SIGNUP:-false} \
        ${CUSTOM_DOMAIN:+-c CUSTOM_DOMAIN=$CUSTOM_DOMAIN}
```

## Step 3 — Frontend Buildspec (rewrite to read CFN outputs at build time)

File: `buildspec-frontend.yml`

This is the most important change. The original buildspec consumed CDK values from CodeBuild project env vars that were baked in at *project create time*. That meant every time the backend changed (adding a custom domain, rotating endpoints, etc.) the frontend project's env vars went stale and the React bundle would ship with the wrong URLs.

The rewrite queries `aws cloudformation describe-stacks --stack-name CdkBackendStack` in `pre_build`, extracts every needed output, and uses those values for the rest of the build. CodeBuild env vars become fall-backs only.

Replace the entire file with:

```yaml
version: 0.2

# This buildspec reads the current CdkBackendStack outputs at build time so the
# React bundle always reflects the canonical Amplify URL (custom domain when
# set, default *.amplifyapp.com otherwise) without needing CodeBuild env-var
# updates whenever the backend changes.
#
# Required project env vars (set at create time): PDF_TO_PDF_BUCKET, PDF_TO_HTML_BUCKET.
# Everything else is pulled from CloudFormation; project env vars of the same
# names are honored as fall-backs if the corresponding stack output is missing.

phases:
  install:
    runtime-versions:
      nodejs: 20
      python: 3.12
    commands:
      - echo "Installing zip and jq..."
      - yum install -y zip jq

  pre_build:
    commands:
      - echo "Changing into pdf_ui directory"
      - cd pdf_ui
      - echo "Installing frontend dependencies..."
      - npm ci
      - echo "Querying CdkBackendStack outputs from CloudFormation..."
      - |
        STACK_NAME="${CDK_STACK_NAME:-CdkBackendStack}"
        OUTPUTS_JSON=$(aws cloudformation describe-stacks \
          --stack-name "$STACK_NAME" \
          --query 'Stacks[0].Outputs' \
          --output json 2>/dev/null || echo "[]")

        get_output() {
          local key="$1"; local fallback="${2:-}"
          local value
          value=$(echo "$OUTPUTS_JSON" | jq -r --arg k "$key" \
            '.[] | select(.OutputKey == $k) | .OutputValue' 2>/dev/null)
          if [ -z "$value" ] || [ "$value" = "null" ]; then
            echo "$fallback"
          else
            echo "$value"
          fi
        }

        export AMPLIFY_APP_ID=$(get_output "AmplifyAppId" "${AMPLIFY_APP_ID:-}")
        export REACT_APP_AMPLIFY_APP_URL=$(get_output "AmplifyAppURL" "${REACT_APP_AMPLIFY_APP_URL:-}")
        export REACT_APP_USER_POOL_ID=$(get_output "UserPoolId" "${REACT_APP_USER_POOL_ID:-}")
        export REACT_APP_USER_POOL_CLIENT_ID=$(get_output "UserPoolClientId" "${REACT_APP_USER_POOL_CLIENT_ID:-}")
        export REACT_APP_USER_POOL_DOMAIN=$(get_output "UserPoolDomain" "${REACT_APP_USER_POOL_DOMAIN:-}")
        export REACT_APP_IDENTITY_POOL_ID=$(get_output "IdentityPoolId" "${REACT_APP_IDENTITY_POOL_ID:-}")
        export REACT_APP_UPDATE_FIRST_SIGN_IN_ENDPOINT=$(get_output "UpdateFirstSignInEndpoint" "${REACT_APP_UPDATE_FIRST_SIGN_IN_ENDPOINT:-}")
        export REACT_APP_CHECK_UPLOAD_QUOTA_ENDPOINT=$(get_output "CheckUploadQuotaEndpoint" "${REACT_APP_CHECK_UPLOAD_QUOTA_ENDPOINT:-}")
        export REACT_APP_JOB_HISTORY_ENDPOINT=$(get_output "JobHistoryEndpoint" "${REACT_APP_JOB_HISTORY_ENDPOINT:-}")
        export REACT_APP_UPDATE_ATTRIBUTES_API_ENDPOINT=$(get_output "UpdateAttributesApiEndpoint377B5108" "${REACT_APP_UPDATE_ATTRIBUTES_API_ENDPOINT:-}")
        export AMPLIFY_CUSTOM_DOMAIN=$(get_output "AmplifyCustomDomain" "")
        export AMPLIFY_CUSTOM_DOMAIN_URL=$(get_output "AmplifyCustomDomainURL" "")

        echo "Resolved configuration from CdkBackendStack:"
        echo "  AmplifyAppId        = $AMPLIFY_APP_ID"
        echo "  AmplifyAppURL       = $REACT_APP_AMPLIFY_APP_URL"
        if [ -n "$AMPLIFY_CUSTOM_DOMAIN_URL" ]; then
          echo "  Custom domain       = $AMPLIFY_CUSTOM_DOMAIN ($AMPLIFY_CUSTOM_DOMAIN_URL)"
        fi

        # Persist exports for subsequent build phases (each phase gets a fresh shell)
        cat > /tmp/frontend-env.sh <<EOF
        export AMPLIFY_APP_ID="$AMPLIFY_APP_ID"
        export REACT_APP_AMPLIFY_APP_URL="$REACT_APP_AMPLIFY_APP_URL"
        export REACT_APP_USER_POOL_ID="$REACT_APP_USER_POOL_ID"
        export REACT_APP_USER_POOL_CLIENT_ID="$REACT_APP_USER_POOL_CLIENT_ID"
        export REACT_APP_USER_POOL_DOMAIN="$REACT_APP_USER_POOL_DOMAIN"
        export REACT_APP_IDENTITY_POOL_ID="$REACT_APP_IDENTITY_POOL_ID"
        export REACT_APP_UPDATE_FIRST_SIGN_IN_ENDPOINT="$REACT_APP_UPDATE_FIRST_SIGN_IN_ENDPOINT"
        export REACT_APP_CHECK_UPLOAD_QUOTA_ENDPOINT="$REACT_APP_CHECK_UPLOAD_QUOTA_ENDPOINT"
        export REACT_APP_JOB_HISTORY_ENDPOINT="$REACT_APP_JOB_HISTORY_ENDPOINT"
        export REACT_APP_UPDATE_ATTRIBUTES_API_ENDPOINT="$REACT_APP_UPDATE_ATTRIBUTES_API_ENDPOINT"
        EOF

        if [ -z "$AMPLIFY_APP_ID" ] || [ -z "$REACT_APP_AMPLIFY_APP_URL" ]; then
          echo "❌ Required values missing: AmplifyAppId or AmplifyAppURL not in CFN outputs"
          echo "   and no fallback env var was provided."
          exit 1
        fi
      - echo "Creating .env file with resolved configuration..."
      - |
        source /tmp/frontend-env.sh
        AWS_REGION=$(echo "$REACT_APP_USER_POOL_ID" | cut -d'_' -f1)
        cat > .env << EOF
        REACT_APP_MAINTENANCE_MODE=false
        REACT_APP_AUTHORITY=cognito-idp.$AWS_REGION.amazonaws.com/$REACT_APP_USER_POOL_ID
        REACT_APP_AWS_REGION=$AWS_REGION
        REACT_APP_PDF_BUCKET_NAME=$PDF_TO_PDF_BUCKET
        REACT_APP_BUCKET_REGION=$AWS_REGION
        REACT_APP_HTML_BUCKET_NAME=$PDF_TO_HTML_BUCKET
        REACT_APP_DOMAIN_PREFIX=$REACT_APP_USER_POOL_DOMAIN
        REACT_APP_IDENTITY_POOL_ID=$REACT_APP_IDENTITY_POOL_ID
        REACT_APP_UPDATE_FIRST_SIGN_IN=$REACT_APP_UPDATE_FIRST_SIGN_IN_ENDPOINT
        REACT_APP_UPLOAD_QUOTA_API=$REACT_APP_CHECK_UPLOAD_QUOTA_ENDPOINT
        REACT_APP_JOB_HISTORY_API=$REACT_APP_JOB_HISTORY_ENDPOINT
        REACT_APP_USER_POOL_CLIENT_ID=$REACT_APP_USER_POOL_CLIENT_ID
        REACT_APP_USER_POOL_ID=$REACT_APP_USER_POOL_ID
        REACT_APP_HOSTED_UI_URL=$REACT_APP_AMPLIFY_APP_URL
        EOF
      - echo "Contents of .env file:"
      - cat .env

  build:
    commands:
      - source /tmp/frontend-env.sh
      - echo "Building React application..."
      - npm run build
      - echo "Creating deployment package..."
      - cd build && zip -r build .
      - echo "Frontend build completed successfully"

  post_build:
    commands:
      - source /tmp/frontend-env.sh
      - echo "🚀 Deploying frontend to Amplify..."
      - echo "Amplify App ID: $AMPLIFY_APP_ID"
      - >-
        aws amplify create-deployment
        --app-id $AMPLIFY_APP_ID
        --branch-name main
        --output json > deployment_response.json
      - export UPLOAD_URL=$(jq -r '.zipUploadUrl' deployment_response.json)
      - export JOB_ID=$(jq -r '.jobId' deployment_response.json)
      - curl -X PUT -T build.zip "$UPLOAD_URL"
      - >-
        aws amplify start-deployment
        --app-id $AMPLIFY_APP_ID
        --branch-name main
        --job-id $JOB_ID
      - |
        if [ -n "$AMPLIFY_CUSTOM_DOMAIN_URL" ]; then
          echo "🌐 Live at custom domain (once DNS validates): $AMPLIFY_CUSTOM_DOMAIN_URL"
        else
          echo "🌐 Live at: $REACT_APP_AMPLIFY_APP_URL"
        fi
```

Why this matters: with the original buildspec, every domain change required `aws codebuild update-project` calls on the frontend project to refresh `REACT_APP_AMPLIFY_APP_URL`. With this version, push-to-main (or `start-build`) is sufficient — the buildspec re-resolves all CDK values on every run.

## Step 4 — Deploy Scripts

The bash scripts surface the parameter to interactive and non-interactive callers. Treat them as stylistically optional — the only required surface is the env var on the CodeBuild project. But matching the existing UX makes the fork feel coherent.

### `deploy.sh` (public-repo CodeBuild path)

Add an interactive prompt right after the SELF_SIGNUP prompt:

```bash
echo ""
echo "🌐 Custom Domain (optional):"
echo "   Attach a custom domain (e.g., app.example.edu) to the Amplify app."
echo "   Amplify will provision and renew an ACM certificate automatically."
echo "   You'll need to add the validation/CNAME records at your DNS provider after deploy."
echo "   Leave blank to skip and use the default *.amplifyapp.com URL."
read -rp "Custom domain (or press Enter to skip): " CUSTOM_DOMAIN
CUSTOM_DOMAIN="${CUSTOM_DOMAIN:-}"
```

In the `ENV_VARS_ARRAY` construction for the backend project, append:

```bash
if [ -n "${CUSTOM_DOMAIN:-}" ]; then
  ENV_VARS_ARRAY="$ENV_VARS_ARRAY,"'{
    "name":  "CUSTOM_DOMAIN",
    "value": "'"$CUSTOM_DOMAIN"'",
    "type":  "PLAINTEXT"
  }'
fi
```

And pass it through to the frontend script:

```bash
./deploy-frontend.sh "$PROJECT_NAME" "$PDF_TO_PDF_BUCKET" "$PDF_TO_HTML_BUCKET" "$ROLE_ARN" "${CUSTOM_DOMAIN:-}"
```

### `deploy-frontend.sh`

Accept the new fifth positional argument:

```bash
PROJECT_NAME="$1"
PDF_TO_PDF_BUCKET="$2"
PDF_TO_HTML_BUCKET="$3"
ROLE_ARN="$4"
CUSTOM_DOMAIN="${5:-}"
```

Add `CUSTOM_DOMAIN` to the frontend project's env vars (so the value is visible to humans who poke at the project later):

```bash
add_frontend_env_var "CUSTOM_DOMAIN" "$CUSTOM_DOMAIN"
```

The frontend buildspec from Step 3 ignores this env var directly — it resolves the URL from CFN outputs — but having it on the project makes the configuration discoverable.

### `deploy-private.sh`

Add `CUSTOM_DOMAIN` handling alongside `SELF_SIGNUP`. In `collect_parameters`:

```bash
if [[ -z "${CUSTOM_DOMAIN:-}" ]]; then
  if [[ "$NON_INTERACTIVE" != "true" ]]; then
    echo ""
    echo "Custom domain (optional) — Amplify will provision an ACM certificate"
    echo "and you'll need to add the validation/CNAME records at your DNS provider."
    read -rp "Custom domain (or press Enter to skip): " CUSTOM_DOMAIN
    CUSTOM_DOMAIN="${CUSTOM_DOMAIN:-}"
  fi
fi
```

Add `CUSTOM_DOMAIN` to the help text and the documented config-file entries.

### `deploy-full-stack-local.sh`

Accept the optional third positional arg or `CUSTOM_DOMAIN` env var, then pass through to `cdk deploy`:

```bash
CUSTOM_DOMAIN="${3:-${CUSTOM_DOMAIN:-}}"
# ...
if [ -n "$CUSTOM_DOMAIN" ]; then
  CDK_CONTEXT_ARGS="$CDK_CONTEXT_ARGS -c CUSTOM_DOMAIN=$CUSTOM_DOMAIN"
fi
```

### `deploy-amplify-direct.sh`

Read `AmplifyCustomDomainURL` from CFN and surface it in the summary:

```bash
CUSTOM_DOMAIN_URL=$(get_output "AmplifyCustomDomainURL")
# ...
if [ -n "${CUSTOM_DOMAIN_URL:-}" ]; then
  echo "🌐 Custom domain (once DNS validates):"
  echo "   $CUSTOM_DOMAIN_URL"
fi
```

This script doesn't *set* the domain — it just reports whichever domain the backend stack already attached.

### `pipeline.conf.example`

Document the optional config entry:

```bash
# Optional custom domain to attach to the Amplify app (e.g., app.example.edu).
# Leave blank or remove the line to skip and use the default *.amplifyapp.com URL.
# After deploy, add the validation/CNAME records Amplify shows in the
# console (or in CloudFormation events) to your DNS provider.
# CUSTOM_DOMAIN=app.example.edu
```

## Operating the Custom Domain After Deploy

These notes belong in any docs the agent writes for the customer.

### Format Rules

`CUSTOM_DOMAIN` must be the **bare hostname**, no scheme, no trailing slash. The CDK prepends `https://` itself.

```
✅ CUSTOM_DOMAIN=pdf-demo.example.edu
❌ CUSTOM_DOMAIN=https://pdf-demo.example.edu/
❌ CUSTOM_DOMAIN=pdf-demo.example.edu/
```

### Setting It Once on Existing CodeBuild Projects

If the customer already deployed the original repo before adopting this change, they'll have CodeBuild projects without the env var. Update both projects:

```bash
BACKEND_PROJECT=pdf-ui-<timestamp>-backend
FRONTEND_PROJECT=pdf-ui-<timestamp>-frontend
DOMAIN=pdf-demo.example.edu

aws codebuild batch-get-projects --names "$BACKEND_PROJECT" \
  --query 'projects[0].environment' \
  | jq --arg d "$DOMAIN" '.environmentVariables += [{"name":"CUSTOM_DOMAIN","value":$d,"type":"PLAINTEXT"}]' \
  > /tmp/backend-env.json
aws codebuild update-project --name "$BACKEND_PROJECT" --environment file:///tmp/backend-env.json

# Frontend doesn't strictly need it (buildspec reads from CFN), but adding it
# for traceability when humans inspect the project later
aws codebuild batch-get-projects --names "$FRONTEND_PROJECT" \
  --query 'projects[0].environment' \
  | jq --arg d "$DOMAIN" '.environmentVariables += [{"name":"CUSTOM_DOMAIN","value":$d,"type":"PLAINTEXT"}]' \
  > /tmp/frontend-env.json
aws codebuild update-project --name "$FRONTEND_PROJECT" --environment file:///tmp/frontend-env.json
```

Then either push to main or:

```bash
aws codebuild start-build --project-name "$BACKEND_PROJECT"
# wait for backend to succeed, validate DNS records
aws codebuild start-build --project-name "$FRONTEND_PROJECT"
```

### One-Shot Test (No Permanent Change)

```bash
aws codebuild start-build \
  --project-name "$BACKEND_PROJECT" \
  --environment-variables-override '[{"name":"CUSTOM_DOMAIN","value":"pdf-demo.example.edu","type":"PLAINTEXT"}]'
```

Note: the *next* webhook-triggered build will revert because the env var isn't on the project. CDK will then *remove* the domain association. Use only for testing.

### DNS Validation

After the backend build succeeds, the `AmplifyDomain` resource sits in `PENDING_VERIFICATION`. The customer needs to:

1. Open the Amplify console → the app → **Domain management**.
2. Copy the validation CNAME (and the `_amazonses` record if applicable).
3. Add those records at the DNS provider for the apex/zone that owns the hostname.
4. Wait for Amplify to flip the domain to `AVAILABLE` (typically minutes, sometimes up to a day).

Cognito callback/logout URLs include both the custom domain and the default `*.amplifyapp.com` URL, so the original URL keeps serving traffic during DNS validation. No downtime cutover.

### Removing the Domain

Clear the env var on the backend project (or set it to empty), then push:

```bash
aws codebuild update-project --name "$BACKEND_PROJECT" \
  --environment "$(aws codebuild batch-get-projects --names "$BACKEND_PROJECT" \
    --query 'projects[0].environment' \
    | jq 'del(.environmentVariables[] | select(.name == "CUSTOM_DOMAIN"))')"
```

CDK tears down the `AmplifyDomain` resource. The customer manually deletes the DNS records at their registrar.

## Verification Checklist

After applying the changes, the agent should verify:

1. `python3 -c "import yaml; yaml.safe_load(open('buildspec-frontend.yml'))"` — buildspec parses.
2. `cd cdk_backend && npm run build` — TypeScript compiles.
3. `cd cdk_backend && npx cdk synth` — synthesizes without error both with and without `-c CUSTOM_DOMAIN=test.example.com`.
4. Without `CUSTOM_DOMAIN`: synth output shows the original `appUrl` in CORS, callbacks, and outputs. No `AmplifyDomain` resource. No `AmplifyCustomDomain*` outputs.
5. With `CUSTOM_DOMAIN`: synth output shows `AmplifyDomain`, `AmplifyDomainSubDomainSetting` resources. `https://test.example.com` appears in CORS `AllowedOrigins`, Cognito `CallbackURLs`, and `LogoutURLs`. `AmplifyCustomDomain` and `AmplifyCustomDomainURL` outputs are present.

## Common Pitfalls

| Pitfall | Symptom | Fix |
|---|---|---|
| `CUSTOM_DOMAIN=https://...` | CDK synth fails or the domain string ends up doubled | Strip the scheme; use `app.example.edu` |
| Forgot to add validation CNAME | `AmplifyDomain` stuck in `PENDING_VERIFICATION` | Open Amplify console, copy the CNAME, add at DNS provider |
| Frontend project has stale `REACT_APP_AMPLIFY_APP_URL` | React app redirects to wrong host after sign-in | Apply the buildspec rewrite from Step 3 — the CFN-driven approach makes this self-healing |
| Used a CloudFront-fronted custom cert workflow instead | Amplify's auto-renewal stops working / extra moving parts | Use Amplify's built-in `addDomain` (this doc); only switch architectures if a corporate cert is contractually required |
| DNS in a zone the AWS account can't reach | Validation never completes | Have the customer add the records manually in whatever system owns the zone (e.g., `people.aws.dev` tooling, ServiceNow at an enterprise, etc.) |

## What's Intentionally Not Included

- **Bringing your own ACM certificate.** Amplify Hosting doesn't expose a "use this certificate ARN" knob the way CloudFront does. If a customer needs a customer-managed cert (private CA, EV cert), they need a different architecture (CloudFront in front of an S3 origin or in front of the Amplify-served origin), which is outside the scope of this doc.
- **Apex domains via ALIAS records.** Amplify supports apex domains, but only on Route 53 (which can issue ALIAS records). If the customer hosts DNS elsewhere, recommend using a subdomain (`app.example.edu`) rather than the apex (`example.edu`).
- **Multiple environments on one Amplify app.** This setup attaches a single domain to the `main` branch. If the fork has dev/staging/prod branches, replicate the `addDomain` block per branch with distinct domains.
