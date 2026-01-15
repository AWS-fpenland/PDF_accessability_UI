# Direct Amplify Deployment Guide

## Overview

The `deploy-amplify-direct.sh` script allows you to deploy any local branch directly to Amplify without using CodeBuild or pushing to GitHub. This is perfect for:

- Testing local changes before committing
- Deploying custom demo branches (like the UB demo)
- Rapid iteration during development
- Keeping the main branch connected to GitHub while deploying other branches

## Quick Start

### Basic Usage (Auto-detect buckets)

```bash
chmod +x deploy-amplify-direct.sh
./deploy-amplify-direct.sh
```

### With Bucket Names

```bash
./deploy-amplify-direct.sh <PDF_BUCKET_NAME> <HTML_BUCKET_NAME>
```

### Example

```bash
./deploy-amplify-direct.sh pdfaccessibility-mybucket-abc123 pdf2html-bucket-xyz789
```

## How It Works

The script automates the entire deployment process:

1. **Retrieves Configuration** - Pulls backend settings from CloudFormation
2. **Validates Amplify App** - Verifies the Amplify app exists in your region
3. **Creates .env.production** - Generates environment variables automatically
4. **Builds React App** - Runs `npm run build` locally
5. **Creates Deployment** - Packages and uploads to Amplify
6. **Monitors Progress** - Waits for deployment to complete

## Prerequisites

- AWS CLI configured with appropriate credentials
- Node.js and npm installed
- Backend stack (`CdkBackendStack`) already deployed
- Amplify app created and accessible

## Parameters

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| PDF_BUCKET | Optional | PDF-to-PDF S3 bucket name | `pdfaccessibility-bucket-abc123` |
| HTML_BUCKET | Optional | PDF-to-HTML S3 bucket name | `pdf2html-bucket-xyz789` |

If not provided, the script attempts to auto-detect bucket names from CloudFormation.

## What Gets Auto-Retrieved

The script automatically retrieves from CloudFormation:

- Amplify App ID
- Amplify App URL
- Cognito User Pool ID
- Cognito User Pool Client ID
- Cognito User Pool Domain
- Identity Pool ID
- API Gateway endpoints
- AWS Region

## Troubleshooting

### Error: "App d39fc130immml9 not found"

**Cause**: The Amplify App ID from CloudFormation doesn't match an existing app, or you're in the wrong AWS region.

**Solutions**:
1. Check your AWS region: `aws configure get region`
2. List available Amplify apps: `aws amplify list-apps`
3. Verify the backend stack is deployed: `aws cloudformation describe-stacks --stack-name CdkBackendStack`
4. Check if the Amplify app was created in a different region

### Error: "Could not find AmplifyAppId"

**Cause**: Backend stack not deployed or missing Amplify outputs.

**Solution**: Deploy the backend first:
```bash
cd cdk_backend
npm install
npm run build
cdk deploy
```

### Bucket Names Not Auto-Detected

**Cause**: Bucket names don't match expected patterns or aren't in CloudFormation.

**Solution**: Specify bucket names manually:
```bash
./deploy-amplify-direct.sh my-pdf-bucket my-html-bucket
```

To find your bucket names:
```bash
aws s3 ls | grep -E 'pdfaccessibility|pdf2html'
```

### Build Fails

**Cause**: Missing dependencies or build errors.

**Solution**:
```bash
cd pdf_ui
rm -rf node_modules package-lock.json
npm install
npm run build
```

### Deployment Timeout

**Cause**: Deployment is taking longer than expected.

**Solution**: Check Amplify console for status:
```bash
# Get your app ID
aws cloudformation describe-stacks \
  --stack-name CdkBackendStack \
  --query 'Stacks[0].Outputs[?OutputKey==`AmplifyAppId`].OutputValue' \
  --output text

# Then visit:
# https://console.aws.amazon.com/amplify/home#/<APP_ID>
```

## Advantages Over CodeBuild Deployment

| Feature | Direct Deploy | CodeBuild Deploy |
|---------|---------------|------------------|
| Speed | ⚡ Faster (local build) | Slower (remote build) |
| GitHub Push Required | ❌ No | ✅ Yes |
| Build Environment | Local machine | AWS CodeBuild |
| Cost | Free (local) | CodeBuild charges |
| Testing | Immediate | After push |
| Branch Flexibility | Any local branch | GitHub branches only |

## When to Use

**Use Direct Deploy when:**
- Testing UI changes quickly
- Working on a feature branch
- Don't want to push to GitHub yet
- Need rapid iteration

**Use CodeBuild Deploy when:**
- Deploying to production
- Want CI/CD automation
- Need consistent build environment
- Deploying from GitHub

## Files Created

The script creates temporary files that are gitignored:

- `pdf_ui/.env.production` - Environment variables (auto-generated)
- `pdf_ui/deployment.zip` - Build package (auto-cleaned)

## Example Workflow

```bash
# 1. Make your UI changes
cd pdf_ui/src
# ... edit files ...

# 2. Test locally (optional)
npm start

# 3. Deploy directly
cd ../..
./deploy-amplify-direct.sh

# 4. View your changes live
# Opens automatically or visit the URL shown
```

## Security Notes

- The `.env.production` file contains sensitive configuration
- It's automatically excluded by `.gitignore`
- Never commit this file to version control
- The file is regenerated on each deployment

## Advanced Usage

### Deploy with Custom Region

```bash
AWS_REGION=us-west-2 ./deploy-amplify-direct.sh
```

### Deploy Specific Stack

```bash
# Edit the script and change STACK_NAME variable
STACK_NAME="MyCustomStack" ./deploy-amplify-direct.sh
```

### Skip Build (Use Existing)

If you've already built locally:

```bash
cd pdf_ui
npm run build
cd ..
# Then manually run the deployment steps from the script
```

## Comparison with Other Methods

### Method 1: Direct Deploy (This Script)
```bash
./deploy-amplify-direct.sh
# ✅ Fast, no GitHub push needed
```

### Method 2: CodeBuild with Branch
```bash
git push origin fpenland/demo/UB
./deploy-frontend-ub.sh <params>
# ✅ CI/CD, consistent environment
```

### Method 3: Manual Amplify Console
```bash
# Push to GitHub, then use AWS Console
# ✅ Visual interface, easy monitoring
```

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Verify AWS credentials: `aws sts get-caller-identity`
3. Check CloudFormation stack status
4. Review Amplify console logs
5. Ensure all prerequisites are met