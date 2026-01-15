# Deployment Quick Start

## 🚀 Three Ways to Deploy Your UB Demo

### Option 1: Direct Deploy (Fastest for Testing) ⚡

**Best for**: Quick testing, local changes, no GitHub push needed

```bash
# With bucket names (recommended)
./deploy-amplify-direct.sh pdfaccessibility-bucket-name pdf2html-bucket-name

# Or let it auto-detect (may not work)
./deploy-amplify-direct.sh
```

**Find your bucket names:**
```bash
aws s3 ls | grep -E 'pdfaccessibility|pdf2html'
```

**Troubleshooting:**
- If you get "App not found" error, check your AWS region matches where Amplify was deployed
- List Amplify apps: `aws amplify list-apps`
- Check region: `aws configure get region`

---

### Option 2: Deploy UB Branch via CodeBuild

**Best for**: Production deployments, CI/CD workflow

```bash
# First, push your branch
git push origin fpenland/demo/UB

# Then deploy
chmod +x deploy-frontend-ub.sh
./deploy-frontend-ub.sh <PROJECT_NAME> <PDF_BUCKET> <HTML_BUCKET> <ROLE_ARN>
```

**Get your parameters:**
```bash
# Get CloudFormation outputs
aws cloudformation describe-stacks \
  --stack-name CdkBackendStack \
  --query 'Stacks[0].Outputs' \
  --output table

# Get CodeBuild role ARN
aws iam list-roles \
  --query 'Roles[?contains(RoleName, `CodeBuild`)].Arn' \
  --output text
```

---

### Option 3: Deploy Main Branch (Original)

**Best for**: Deploying the original non-UB version

```bash
./deploy-frontend.sh <PROJECT_NAME> <PDF_BUCKET> <HTML_BUCKET> <ROLE_ARN>
```

---

## 🧪 Test Locally First

Always test before deploying:

```bash
cd pdf_ui
npm install
npm start
```

Visit http://localhost:3000 to preview your changes.

---

## 🔍 Common Issues

### "App not found" Error

**Problem**: Amplify app ID doesn't exist or wrong region

**Fix**:
1. Check your region: `aws configure get region`
2. List apps: `aws amplify list-apps`
3. Verify backend is deployed: `aws cloudformation describe-stacks --stack-name CdkBackendStack`

### Can't Find Bucket Names

**Problem**: Auto-detection failed

**Fix**: Specify them manually as parameters
```bash
# List all S3 buckets
aws s3 ls

# Or search for specific ones
aws s3 ls | grep pdf
```

### Build Fails

**Problem**: Dependencies or build errors

**Fix**:
```bash
cd pdf_ui
rm -rf node_modules package-lock.json
npm install
npm run build
cd ..
```

---

## 📊 Comparison

| Method | Speed | GitHub Push | Cost | Use Case |
|--------|-------|-------------|------|----------|
| Direct Deploy | ⚡ Fast | ❌ No | Free | Testing |
| CodeBuild (UB) | Medium | ✅ Yes | $ | Production |
| CodeBuild (Main) | Medium | ✅ Yes | $ | Original |

---

## 💡 Recommended Workflow

1. **Develop**: Make changes locally
2. **Test**: Run `npm start` to preview
3. **Quick Deploy**: Use `deploy-amplify-direct.sh` for rapid testing
4. **Commit**: When satisfied, commit your changes
5. **Push**: `git push origin fpenland/demo/UB`
6. **Production Deploy**: Use `deploy-frontend-ub.sh` for final deployment

---

## 📚 Full Documentation

- **Direct Deploy**: `docs/DIRECT_AMPLIFY_DEPLOYMENT.md`
- **Branch Deploy**: `docs/DEPLOY_LOCAL_BRANCH.md`
- **UB Demo Info**: `UB_DEMO_README.md`
