# Deploying Your Local Branch

## The Issue

The `deploy-frontend.sh` script pulls code from GitHub's `main` branch by default. To deploy your local `fpenland/demo/UB` branch, you need to either push it to GitHub or modify the deployment process.

## Option 1: Push Branch to GitHub (Recommended)

This is the cleanest approach and maintains the CI/CD workflow.

### Step 1: Push Your Branch to GitHub

```bash
cd PDF_accessability_UI
git push origin fpenland/demo/UB
```

### Step 2: Create a Custom Deploy Script

Create a new file `deploy-frontend-branch.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------
# Frontend Deployment Script for Specific Branch
# Usage: ./deploy-frontend-branch.sh <PROJECT_NAME> <PDF_TO_PDF_BUCKET> <PDF_TO_HTML_BUCKET> <ROLE_ARN> <BRANCH_NAME>
# --------------------------------------------------

# Parse arguments
PROJECT_NAME="$1"
PDF_TO_PDF_BUCKET="$2"
PDF_TO_HTML_BUCKET="$3"
ROLE_ARN="$4"
BRANCH_NAME="${5:-fpenland/demo/UB}"  # Default to your branch

echo "🚀 Starting Frontend Deployment from branch: $BRANCH_NAME"
echo "📋 Parameters:"
echo "  - PROJECT_NAME: $PROJECT_NAME"
echo "  - PDF_TO_PDF_BUCKET: $PDF_TO_PDF_BUCKET"
echo "  - PDF_TO_HTML_BUCKET: $PDF_TO_HTML_BUCKET"
echo "  - ROLE_ARN: $ROLE_ARN"
echo "  - BRANCH: $BRANCH_NAME"

# [Rest of the script is the same as deploy-frontend.sh, but change SOURCE_VERSION]

# ... (copy all the CDK output retrieval code) ...

# Change this line:
SOURCE_VERSION="$BRANCH_NAME"  # Instead of "main"

# ... (rest of the script) ...
```

### Step 3: Run the Custom Script

```bash
chmod +x deploy-frontend-branch.sh
./deploy-frontend-branch.sh <PROJECT_NAME> <PDF_BUCKET> <HTML_BUCKET> <ROLE_ARN> fpenland/demo/UB
```

## Option 2: Direct Amplify Deployment (Faster for Testing)

This bypasses CodeBuild and deploys directly to Amplify.

### Step 1: Build Locally

```bash
cd pdf_ui

# Create .env file with your backend values
cat > .env.production << EOF
REACT_APP_AUTHORITY=your-cognito-domain.auth.region.amazoncognito.com
REACT_APP_AWS_REGION=us-east-1
REACT_APP_BUCKET_REGION=us-east-1
REACT_APP_PDF_BUCKET_NAME=your-pdf-bucket
REACT_APP_HTML_BUCKET_NAME=your-html-bucket
REACT_APP_HOSTED_UI_URL=https://your-amplify-url.amplifyapp.com
REACT_APP_DOMAIN_PREFIX=your-domain-prefix
REACT_APP_IDENTITY_POOL_ID=your-identity-pool-id
REACT_APP_USER_POOL_CLIENT_ID=your-client-id
REACT_APP_USER_POOL_ID=your-user-pool-id
REACT_APP_UPDATE_FIRST_SIGN_IN=your-api-endpoint
REACT_APP_UPLOAD_QUOTA_API=your-quota-endpoint
EOF

# Build the production bundle
npm run build
```

### Step 2: Deploy to Amplify

```bash
# Install Amplify CLI if not already installed
npm install -g @aws-amplify/cli

# Get your Amplify App ID from CloudFormation outputs
AMPLIFY_APP_ID=$(aws cloudformation describe-stacks \
  --stack-name CdkBackendStack \
  --query 'Stacks[0].Outputs[?OutputKey==`AmplifyAppId`].OutputValue' \
  --output text)

echo "Amplify App ID: $AMPLIFY_APP_ID"

# Create a deployment package
cd build
zip -r ../deployment.zip .
cd ..

# Deploy using AWS CLI
aws amplify create-deployment \
  --app-id $AMPLIFY_APP_ID \
  --branch-name main

# Upload the build
# (This requires additional steps with the deployment URL)
```

## Option 3: Use the UB Deployment Script (Recommended)

A pre-configured deployment script `deploy-frontend-ub.sh` is available that deploys the `fpenland/demo/UB` branch.

### Step 1: Push Your Branch First

```bash
git push origin fpenland/demo/UB
```

### Step 2: Run the UB Deployment Script

```bash
chmod +x deploy-frontend-ub.sh
./deploy-frontend-ub.sh <PROJECT_NAME> <PDF_BUCKET> <HTML_BUCKET> <ROLE_ARN>
```

The script is identical to `deploy-frontend.sh` except it deploys from the `fpenland/demo/UB` branch instead of `main`.

## Option 4: Manual Amplify Console Deployment

### Step 1: Push Your Branch

```bash
git push origin fpenland/demo/UB
```

### Step 2: Configure in AWS Console

1. Go to AWS Amplify Console
2. Find your app
3. Click "Connect branch"
4. Select `fpenland/demo/UB` branch
5. Configure build settings
6. Deploy

## Recommended Workflow

For your UB demo, I recommend **Option 3** (UB Deployment Script):

1. **First time setup:**
   ```bash
   # Push your branch
   git push origin fpenland/demo/UB
   
   # Make script executable
   chmod +x deploy-frontend-ub.sh
   ```

2. **For each deployment:**
   ```bash
   # Make your changes
   git add -A
   git commit -m "Your changes"
   git push origin fpenland/demo/UB
   
   # Deploy
   ./deploy-frontend-ub.sh <PROJECT_NAME> <PDF_BUCKET> <HTML_BUCKET> <ROLE_ARN>
   ```

## Quick Reference: Get Deployment Parameters

If you need to find your deployment parameters:

```bash
# Get stack outputs
aws cloudformation describe-stacks \
  --stack-name CdkBackendStack \
  --query 'Stacks[0].Outputs' \
  --output table

# Get role ARN
aws iam list-roles \
  --query 'Roles[?contains(RoleName, `CodeBuild`)].Arn' \
  --output text

# Get bucket names
aws s3 ls | grep -E 'pdfaccessibility|pdf2html'
```

## Troubleshooting

### "Branch not found" Error
- Make sure you've pushed your branch: `git push origin fpenland/demo/UB`
- Check branch exists: `git branch -r | grep fpenland/demo/UB`

### Build Fails
- Check CodeBuild logs in AWS Console
- Verify environment variables are set correctly
- Ensure buildspec-frontend.yml exists in your branch

### Amplify Not Updating
- Check Amplify console for build status
- Verify the correct branch is connected
- Clear browser cache and hard refresh

## Testing Before Deployment

Always test locally first:

```bash
cd pdf_ui
npm install
npm start
```

Visit http://localhost:3000 to verify your changes work correctly.
