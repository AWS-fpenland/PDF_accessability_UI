# Cleaning Up & Updating Your PDF Accessibility UI Deployment

This guide walks you through:

1. Removing the AWS resources created by the PDF Accessibility UI deployment
2. Replacing your local code with the latest version from the upstream fork

---

## Prerequisites

- AWS CLI installed and configured with credentials that have admin-level access
- Git installed
- You know the `PROJECT_NAME` you used when you originally ran `deploy.sh`

---

## Part 1: Delete Deployed Resources

### Step 1: Delete the CodeBuild Projects

The deploy script creates CodeBuild projects prefixed with your project name.

```bash
# List your CodeBuild projects to confirm the names
aws codebuild list-projects --no-cli-pager

# Delete the frontend and backend projects
aws codebuild delete-project --name <PROJECT_NAME>-frontend --no-cli-pager
aws codebuild delete-project --name <PROJECT_NAME>-backend --no-cli-pager
```

### Step 2: Delete the Cognito User Pool Domain

The Cognito User Pool Domain can block CloudFormation stack deletion, so remove it first.

```bash
# Get the User Pool ID and Domain from the stack outputs
aws cloudformation describe-stacks \
  --stack-name CdkBackendStack \
  --query 'Stacks[0].Outputs' \
  --output table \
  --no-cli-pager

# Delete the domain using the values from above
aws cognito-idp delete-user-pool-domain \
  --user-pool-id <USER_POOL_ID> \
  --domain <DOMAIN_PREFIX> \
  --no-cli-pager
```

### Step 3: Delete the CDK CloudFormation Stack

This removes the bulk of the resources: Cognito User Pool, Identity Pool, Amplify App, API Gateway, Lambda functions, IAM roles, EventBridge rules, and CloudTrail trail.

```bash
aws cloudformation delete-stack --stack-name CdkBackendStack --no-cli-pager

# Wait for deletion to complete (takes a few minutes)
aws cloudformation wait stack-delete-complete --stack-name CdkBackendStack
```

If the wait command returns with no output, the stack was deleted successfully.

#### If Stack Deletion Fails

Check what went wrong:

```bash
aws cloudformation describe-stack-events \
  --stack-name CdkBackendStack \
  --query 'StackEvents[?ResourceStatus==`DELETE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
  --output table \
  --no-cli-pager
```

If a resource is stuck, you can skip it and clean it up manually:

```bash
aws cloudformation delete-stack \
  --stack-name CdkBackendStack \
  --retain-resources <LogicalResourceId> \
  --no-cli-pager
```

### Step 4: Verify

```bash
# Confirm the stack is gone
aws cloudformation list-stacks \
  --query "StackSummaries[?StackStatus!='DELETE_COMPLETE' && StackName=='CdkBackendStack'].{Name:StackName,Status:StackStatus}" \
  --output table --no-cli-pager

# Confirm the Amplify app is gone
aws amplify list-apps --query 'apps[].{Name:name,Id:appId}' --output table --no-cli-pager

# Confirm the Cognito User Pool is gone
aws cognito-idp list-user-pools --max-results 20 \
  --query "UserPools[?Name=='PDF-Accessability-User-Pool'].{Name:Name,Id:Id}" \
  --output table --no-cli-pager
```

---

## Part 2: Update Your Local Repo from the Upstream Fork

### Step 1: Add the Upstream Remote

```bash
cd PDF_accessability_UI

git remote add upstream https://github.com/AWS-fpenland/PDF_accessability_UI.git

# Verify
git remote -v
```

### Step 2: Fetch and Replace Your Main Branch

```bash
git fetch upstream

git checkout main

# Reset your main to match upstream exactly
git reset --hard upstream/main
```

> If you have local changes you want to keep, back them up first: `git branch backup-main`

### Step 3: Push to Your Private Repo

```bash
git push origin main --force
```

> Use `--force` carefully — this rewrites the remote branch history.

### Step 4: Verify

```bash
git log --oneline -5
git diff upstream/main
```

The diff should return nothing, confirming your branch matches upstream.

---

## What's Next

After updating your code, redeploy the UI following the project README. Make sure the PDF Accessibility backend is deployed first, as the UI depends on the S3 buckets it creates.
