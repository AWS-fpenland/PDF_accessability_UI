# Cleaning Up & Updating Your PDF Accessibility UI Deployment

This guide walks you through two things:

1. Removing all AWS resources created by the PDF Accessibility UI deployment
2. Replacing your local code with the latest version from the upstream fork

---

## Prerequisites

- AWS CLI installed and configured with credentials that have admin-level access
- Git installed
- You know the `PROJECT_NAME` you used when you originally ran `deploy.sh` (this is the prefix used for your CodeBuild projects)

---

## Part 1: Delete All Deployed Resources

The deployment creates resources across several AWS services. We'll delete them in reverse dependency order to avoid errors.

### Step 1: Delete the Frontend CodeBuild Project

The deploy script creates a CodeBuild project named `<PROJECT_NAME>-frontend`.

```bash
# List your CodeBuild projects to find the right one
aws codebuild list-projects --no-cli-pager

# Delete the frontend CodeBuild project
aws codebuild delete-project --name <PROJECT_NAME>-frontend --no-cli-pager
```

### Step 2: Delete the Backend CodeBuild Project

If your original `deploy.sh` also created a backend CodeBuild project:

```bash
aws codebuild delete-project --name <PROJECT_NAME>-backend --no-cli-pager
```

### Step 3: Delete the IAM Role Used by CodeBuild

The deploy script creates an IAM role for CodeBuild. Before deleting it, you need to detach all policies.

```bash
# Find the role — it's typically named <PROJECT_NAME>-codebuild-role or similar
aws iam list-roles --query "Roles[?contains(RoleName, '<PROJECT_NAME>')].RoleName" --output text --no-cli-pager

# List and detach all managed policies from the role
aws iam list-attached-role-policies --role-name <ROLE_NAME> --no-cli-pager

# For each attached policy, detach it:
aws iam detach-role-policy --role-name <ROLE_NAME> --policy-arn <POLICY_ARN>

# List and delete any inline policies
aws iam list-role-policies --role-name <ROLE_NAME> --no-cli-pager

# For each inline policy, delete it:
aws iam delete-role-policy --role-name <ROLE_NAME> --policy-name <POLICY_NAME>

# Now delete the role
aws iam delete-role --role-name <ROLE_NAME> --no-cli-pager
```

### Step 4: Delete the CDK CloudFormation Stack

This is the big one. The `CdkBackendStack` CloudFormation stack contains most of the resources:

- Cognito User Pool, User Pool Domain, User Pool Client, Managed Login Branding
- Cognito Identity Pool and role attachments
- Amplify App
- API Gateway REST API (UpdateAttributesApi)
- Lambda functions (PostConfirmation, UpdateAttributes, CheckOrIncrementQuota, UpdateAttributesGroups)
- IAM roles and policies for the Lambdas
- EventBridge rule and CloudTrail trail
- S3 CORS custom resources

To delete everything in one shot:

```bash
# First, verify the stack exists and check its status
aws cloudformation describe-stacks --stack-name CdkBackendStack --query 'Stacks[0].StackStatus' --output text --no-cli-pager
```

#### Important: Before Deleting the Stack

The Cognito User Pool has `DeletionProtection` off by default in this stack, so it should delete cleanly. However, if deletion fails on the User Pool Domain, you may need to manually delete it first:

```bash
# Get the User Pool ID and Domain from the stack outputs
aws cloudformation describe-stacks \
  --stack-name CdkBackendStack \
  --query 'Stacks[0].Outputs' \
  --output table \
  --no-cli-pager

# If needed, delete the User Pool Domain manually
aws cognito-idp delete-user-pool-domain \
  --user-pool-id <USER_POOL_ID> \
  --domain <DOMAIN_PREFIX> \
  --no-cli-pager
```

#### Delete the Stack

```bash
aws cloudformation delete-stack --stack-name CdkBackendStack --no-cli-pager

# Wait for deletion to complete (this can take a few minutes)
aws cloudformation wait stack-delete-complete --stack-name CdkBackendStack
```

If the wait command returns with no output, the stack was deleted successfully.

#### If Stack Deletion Fails

Sometimes resources get stuck. Check what failed:

```bash
aws cloudformation describe-stack-events \
  --stack-name CdkBackendStack \
  --query 'StackEvents[?ResourceStatus==`DELETE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
  --output table \
  --no-cli-pager
```

Common fixes:
- If the Cognito User Pool Domain fails to delete, manually delete it (see above) then retry
- If a Lambda-backed custom resource fails, you can skip it by retaining it:

```bash
aws cloudformation delete-stack \
  --stack-name CdkBackendStack \
  --retain-resources <LogicalResourceId> \
  --no-cli-pager
```

### Step 5: Delete the CDKToolkit Bootstrap Stack (Optional)

If you no longer need CDK in this account/region and want a full cleanup:

```bash
# First, empty the CDK staging bucket
CDK_BUCKET=$(aws cloudformation describe-stack-resources \
  --stack-name CDKToolkit \
  --query "StackResources[?ResourceType=='AWS::S3::Bucket'].PhysicalResourceId" \
  --output text --no-cli-pager)

aws s3 rm s3://$CDK_BUCKET --recursive --no-cli-pager

# Then delete the bootstrap stack
aws cloudformation delete-stack --stack-name CDKToolkit --no-cli-pager
aws cloudformation wait stack-delete-complete --stack-name CDKToolkit
```

> **Note:** Only do this if no other CDK projects in this account/region depend on the bootstrap stack.

### Step 6: Verify Everything Is Gone

```bash
# Check that no stacks remain
aws cloudformation list-stacks \
  --query "StackSummaries[?StackStatus!='DELETE_COMPLETE' && (StackName=='CdkBackendStack' || StackName=='CDKToolkit')].{Name:StackName,Status:StackStatus}" \
  --output table --no-cli-pager

# Check that CodeBuild projects are gone
aws codebuild list-projects --no-cli-pager

# Check that the Amplify app is gone
aws amplify list-apps --query 'apps[].{Name:name,Id:appId}' --output table --no-cli-pager

# Check that the Cognito User Pool is gone
aws cognito-idp list-user-pools --max-results 20 \
  --query "UserPools[?Name=='PDF-Accessability-User-Pool'].{Name:Name,Id:Id}" \
  --output table --no-cli-pager

# Check that the Identity Pool is gone
aws cognito-identity list-identity-pools --max-results 20 \
  --query "IdentityPools[*].{Name:IdentityPoolName,Id:IdentityPoolId}" \
  --output table --no-cli-pager
```

If any of these still show resources, delete them manually through the AWS Console or CLI.

---

## Part 2: Update Your Local Repo from the Upstream Fork

Now that your environment is clean, replace your local `main` branch with the latest code from the upstream fork.

### Step 1: Add the Upstream Remote

```bash
cd PDF_accessability_UI

# Add the upstream fork as a remote
git remote add upstream https://github.com/AWS-fpenland/PDF_accessability_UI.git

# Verify it was added
git remote -v
```

You should see both `origin` (your repo) and `upstream` (the fork).

### Step 2: Fetch the Upstream Branches

```bash
git fetch upstream
```

### Step 3: Replace Your Main Branch with Upstream's Main

Since you want to fully replace your `main` branch with the upstream version:

```bash
# Make sure you're on main
git checkout main

# Reset your main branch to match upstream's main exactly
git reset --hard upstream/main
```

> **Warning:** This will discard any local changes on your `main` branch. If you have work you want to keep, create a backup branch first:
> ```bash
> git branch backup-main
> ```

### Step 4: Push the Updated Main to Your Private Repo

```bash
# Force push because you've rewritten the branch history
git push origin main --force
```

> **Note:** Use `--force` carefully. This rewrites the remote branch. If others are working from your private repo, coordinate with them first.

### Step 5: Verify

```bash
# Check that your branch matches upstream
git log --oneline -5

# Compare with upstream to confirm they're identical
git diff upstream/main
```

The diff should return nothing, meaning your branch is an exact match.

---

## What's Next

After updating your code, you can redeploy the UI by following the deployment instructions in the project README. Make sure your PDF Accessibility backend is deployed first, as the UI depends on the S3 buckets it creates.
