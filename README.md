# PDF Accessibility Solutions - Frontend UI

This repository provides the **web-based user interface** for the PDF Accessibility Solutions, enabling users to easily upload, process, and download accessibility-compliant PDF documents through an intuitive web application.

> **⚠️ Important:** This is the frontend UI component. You must first deploy the [PDF Accessibility Backend](https://github.com/ASUCICREPO/PDF_Accessibility) before deploying this UI.

## Disclaimers

Customers are responsible for making their own independent assessment of the information in this document.

This document:

(a) is for informational purposes only,

(b) represents current AWS product offerings and practices, which are subject to change without notice, and

(c) does not create any commitments or assurances from AWS and its affiliates, suppliers or licensors. AWS products or services are provided "as is" without warranties, representations, or conditions of any kind, whether express or implied. The responsibilities and liabilities of AWS to its customers are controlled by AWS agreements, and this document is not part of, nor does it modify, any agreement between AWS and its customers.

(d) is not to be considered a recommendation or viewpoint of AWS

Additionally, all prototype code and associated assets should be considered:

(a) as-is and without warranties

(b) not suitable for production environments

(d) to include shortcuts in order to support rapid prototyping such as, but not limited to, relaxed authentication and authorization and a lack of strict adherence to security best practices

All work produced is open source. More information can be found in the GitHub repo.

## Overview

The PDF Accessibility UI connects to both PDF remediation solutions:

1. **PDF-to-PDF Remediation**: Upload PDFs and receive accessibility-improved PDFs
2. **PDF-to-HTML Remediation**: Upload PDFs and receive accessible HTML versions

The application features user authentication, quota management, real-time processing status, and secure file handling, all powered by AWS services.

## Table of Contents

| Index | Description |
|---|---|
| [Prerequisites](#prerequisites) | Requirements before deployment |
| [Option A: Deploy from Public Repository](#option-a-deploy-from-public-repository) | Quick deploy from the upstream GitHub repo |
| [Option B: Deploy from Private Repository](#option-b-deploy-from-private-repository) | Deploy from a fork or private repo with CI/CD |
| [Using the Application](#using-the-application) | User guide for the web interface |
| [Infrastructure Components](#infrastructure-components) | AWS resources created |
| [Monitoring](#monitoring) | System monitoring and logs |
| [Contributing](#contributing) | How to contribute to the project |

## Prerequisites

### Required: Backend Deployment

**You must deploy the backend solutions first!** The UI requires at least one of the following:

- **PDF-to-PDF Backend**: Deployed from [PDF_Accessibility repository](https://github.com/ASUCICREPO/PDF_Accessibility)
- **PDF-to-HTML Backend**: Deployed from [PDF_Accessibility repository](https://github.com/ASUCICREPO/PDF_Accessibility)

After deploying the backend, you'll need the **S3 bucket name(s)** created during deployment.

### System Requirements

1. **AWS Account** with appropriate permissions
   - Amplify, Cognito, Lambda, API Gateway, S3, IAM, CloudFormation
   - See [IAM Permissions Guide](docs/IAM_PERMISSIONS.md) for detailed requirements

2. **AWS CloudShell access** (recommended) or AWS CLI configured locally
   - Sign in to the AWS Management Console
   - Click the CloudShell icon in the top navigation bar
   - Wait for CloudShell to initialize

3. **Backend S3 Bucket Names**
   - PDF-to-PDF bucket name (starts with `pdfaccessibility-`)
   - PDF-to-HTML bucket name (starts with `pdf2html-bucket-`)
   - At least one bucket name is required

---

## Option A: Deploy from Public Repository

Use this option when you want to deploy directly from the upstream public GitHub repository. This is the simplest path — no fork required, no source connection to configure. Good for evaluations, demos, or deployments where you don't need to customize the code.

### Step 1: Clone and Run

```bash
git clone https://github.com/ASUCICREPO/PDF_accessability_UI.git
cd PDF_accessability_UI
chmod +x deploy.sh
./deploy.sh
```

### Step 2: Follow the Interactive Prompts

The script will guide you through:

1. **Bucket Configuration** — enter your backend S3 bucket names (at least one required)
2. **User Registration** — choose whether to enable self-service signup
   - **Yes** — anyone can create an account via the sign-up page
   - **No** (default) — only administrators can create user accounts through the Cognito console
3. **Automated Deployment** — the script will:
   - Create IAM roles with scoped permissions
   - Deploy backend infrastructure (Cognito, Lambda, API Gateway) via CDK
   - Build and deploy the React frontend to Amplify
   - Configure all integrations automatically

### Step 3: Access Your Application

After successful deployment (~8–15 minutes), the script displays:

```
✅ Frontend deployment completed successfully!
🌐 Frontend URL: https://main.{app-id}.amplifyapp.com
```

> **Note:** The public deploy script does not configure webhooks. Each deployment is a one-time build. To redeploy after code changes, re-run `./deploy.sh`.

---

## Option B: Deploy from Private Repository

Use this option when you have forked the repository into your own GitHub, Bitbucket, or GitLab account and want:

- **Automatic CI/CD** — pushes and PR merges to your target branch trigger builds automatically
- **File-scoped triggers** — backend and frontend builds only run when their respective files change
- **Non-interactive mode** — support for config files and environment variables for scripted/automated deployments
- **Private source control** — your fork can be private; authentication is handled via AWS CodeConnections

This is the recommended path for teams customizing the solution or running it in production.

### Prerequisites (in addition to the common prerequisites above)

- A fork of this repository in GitHub, Bitbucket, or GitLab
- An **AWS CodeConnections** connection to your source provider (not needed for CodeCommit)
  - Create one in the AWS Console under Developer Tools → Settings → Connections
  - The connection must be in `AVAILABLE` status

### Step 1: Clone Your Fork and Run

```bash
git clone https://github.com/your-org/PDF_accessability_UI.git
cd PDF_accessability_UI
chmod +x deploy-private.sh
./deploy-private.sh
```

### Step 2: Follow the Interactive Prompts

The script will ask for:

1. **Repository URL** — your fork's HTTPS clone URL
2. **Source Provider** — `github`, `bitbucket`, `gitlab`, or `codecommit`
3. **Target Branch** — the branch to build from (default: `main`)
4. **Connection ARN** — your AWS CodeConnections ARN (not required for CodeCommit)
5. **Bucket Configuration** — backend S3 bucket names (at least one required)
6. **User Registration** — enable or disable self-service signup (default: disabled)

### Non-Interactive Mode

For automated or scripted deployments, use a config file or environment variables:

**Using a config file:**

```bash
./deploy-private.sh --non-interactive --config pipeline.conf
```

Example `pipeline.conf`:

```
PRIVATE_REPO_URL=https://github.com/your-org/PDF_accessability_UI.git
SOURCE_PROVIDER=github
TARGET_BRANCH=main
CONNECTION_ARN=arn:aws:codeconnections:us-east-1:123456789:connection/abc-123
PDF_TO_PDF_BUCKET=pdfaccessibility-bucket-123456789-us-east-1
PDF_TO_HTML_BUCKET=pdf2html-bucket-123456789-us-east-1
SELF_SIGNUP=false
```

**Using environment variables:**

```bash
export PRIVATE_REPO_URL=https://github.com/your-org/PDF_accessability_UI.git
export SOURCE_PROVIDER=github
export TARGET_BRANCH=main
export CONNECTION_ARN=arn:aws:codeconnections:us-east-1:123456789:connection/abc-123
export PDF_TO_PDF_BUCKET=pdfaccessibility-bucket-123456789-us-east-1
export PDF_TO_HTML_BUCKET=pdf2html-bucket-123456789-us-east-1
export SELF_SIGNUP=false

./deploy-private.sh --non-interactive
```

### CLI Options

| Option | Description |
|---|---|
| `--config <path>` | Path to a key-value config file |
| `--non-interactive` | Fail with error instead of prompting (for CI/CD) |
| `--buildspec <path>` | Custom backend buildspec (default: `buildspec.yml`) |
| `--project-name <name>` | Custom CodeBuild project name prefix |
| `--profile <name>` | AWS CLI named profile to use |
| `--cleanup` | List and delete all `pdf-ui-*` pipeline resources |
| `--help` | Show help message |

### Automatic Build Triggers (Webhooks)

After the initial deployment, the script configures CodeBuild webhooks so that future code changes trigger builds automatically. Two separate CodeBuild projects are created with file-path-scoped triggers:

**Backend project** (`pdf-ui-xxxxx-backend`) triggers when any of these paths change:
- `cdk_backend/` — CDK stack and TypeScript infrastructure code
- `buildspec.yml` — backend build configuration
- `lambda/` — Lambda function source code

**Frontend project** (`pdf-ui-xxxxx-frontend`) triggers when any of these paths change:
- `pdf_ui/` — React application source code
- `buildspec-frontend.yml` — frontend build configuration

Each project has two webhook event types:
- **PUSH** to the target branch — direct pushes
- **MERGED** into the target branch — pull request merges

This means a commit that only changes React components won't trigger a CDK deployment, and a commit that only changes Lambda code won't trigger a frontend rebuild.

> **Note:** Webhooks are supported for GitHub, Bitbucket, and GitLab. CodeCommit does not support CodeBuild webhooks — builds must be triggered manually or via a separate EventBridge/CodePipeline setup.

### Manual Webhook Configuration

If you need to configure webhooks manually in the AWS Console (CodeBuild → Build projects → your project → Edit → Source → Webhook):

**Backend project — Event type 1:** select `PUSH`

| Condition | Type | Pattern (regex) |
|---|---|---|
| Start build | HEAD_REF | `^refs/heads/main$` |
| Start build | FILE_PATH | `^cdk_backend/\|^buildspec\.yml$\|^lambda/` |

**Backend project — Event type 2:** click "Add webhook event", select `MERGED`

| Condition | Type | Pattern (regex) |
|---|---|---|
| Start build | BASE_REF | `^refs/heads/main$` |
| Start build | FILE_PATH | `^cdk_backend/\|^buildspec\.yml$\|^lambda/` |

**Frontend project — Event type 1:** select `PUSH`

| Condition | Type | Pattern (regex) |
|---|---|---|
| Start build | HEAD_REF | `^refs/heads/main$` |
| Start build | FILE_PATH | `^pdf_ui/\|^buildspec-frontend\.yml$` |

**Frontend project — Event type 2:** click "Add webhook event", select `MERGED`

| Condition | Type | Pattern (regex) |
|---|---|---|
| Start build | BASE_REF | `^refs/heads/main$` |
| Start build | FILE_PATH | `^pdf_ui/\|^buildspec-frontend\.yml$` |

Replace `main` with your branch name if different.

### Cleaning Up Pipeline Resources

To remove all CodeBuild projects and IAM roles created by the script:

```bash
./deploy-private.sh --cleanup
```

This deletes all `pdf-ui-*` CodeBuild projects and their associated IAM roles. It does not destroy the CDK stack or Amplify app — use `cdk destroy` for that.

---

## Using the Application

### First-Time User Registration

1. **Navigate to the Application URL** — open the Amplify URL provided after deployment
2. **Create an Account** — click "Sign Up", enter your email, name, and password, then verify your email
3. **Complete Your Profile** — on first sign-in, enter your organization name and optionally your location

### Uploading and Processing PDFs

1. **Choose Output Format**
   - **PDF-to-PDF** — maintains PDF format with accessibility improvements
   - **PDF-to-HTML** — converts to accessible HTML format

2. **Upload Your PDF**
   - Click "Upload PDF" or drag and drop
   - File must meet your quota limits (default: 25 MB max size, 10 pages max)
   - The system validates your file before upload

3. **Monitor Processing** — real-time status updates; typical processing is 2–5 minutes per document

4. **Download Results**
   - PDF-to-PDF: accessibility-improved PDF
   - PDF-to-HTML: ZIP file containing HTML, images, and reports

### Understanding Your Quota

Your upload quota is displayed in the header showing current usage vs. maximum allowed.

| Group | Trigger | Max Files | Max Pages | Max Size (MB) |
|---|---|---|---|---|
| DefaultUsers | All users | 8 | 10 | 25 |
| AmazonUsers | @amazon.com email | 15 | 10 | 25 |
| AdminUsers | Manual assignment | 100 | 2500 | 1000 |

### Group Management

Administrators can change user groups through the AWS Cognito console:

1. Navigate to Amazon Cognito in AWS Console
2. Select the `PDF-Accessability-User-Pool`
3. Go to "Users and groups"
4. Select a user and add them to a group
5. User quotas update automatically via EventBridge

## Infrastructure Components

### AWS Resources Created

**Authentication & Authorization:**
- Amazon Cognito User Pool with custom attributes
- Cognito Identity Pool for S3 access
- Three user groups (Default, Amazon, Admin)
- Managed login UI (version 2)

**Backend APIs:**
- API Gateway REST API with Cognito authorizer
- Lambda functions for quota management and user profile updates
- EventBridge rules for automatic quota updates on group changes

**Frontend Hosting:**
- AWS Amplify application with manual deployment
- Automatic HTTPS
- SPA routing configuration

**Monitoring:**
- CloudWatch Logs for all Lambda functions
- CloudTrail for Cognito group changes
- API Gateway access logs

### Custom Cognito Attributes

```
custom:first_sign_in          - Boolean: First login flag
custom:total_files_uploaded   - Number: Total uploads
custom:max_files_allowed      - Number: Upload limit
custom:max_pages_allowed      - Number: Page limit per PDF
custom:max_size_allowed_MB    - Number: File size limit
custom:organization           - String: User's organization
custom:country                - String: User's country
custom:state                  - String: User's state
custom:city                   - String: User's city
custom:pdf2pdf                - Number: PDF-to-PDF conversions
custom:pdf2html               - Number: PDF-to-HTML conversions
```

## Monitoring

### CloudWatch Logs

| Log Group | Purpose |
|---|---|
| `/aws/lambda/PostConfirmationLambda` | User registration events |
| `/aws/lambda/UpdateAttributesFn` | Profile updates |
| `/aws/lambda/checkOrIncrementQuotaFn` | Quota checks and increments |
| `/aws/lambda/UpdateAttributesGroupsFn` | Group membership changes |

### Troubleshooting

**"You have reached your upload limit"** — quota exceeded. Contact an administrator or check your current usage in the header.

**"File size exceeds limit"** or **"PDF file cannot exceed X pages"** — reduce file size, split into smaller documents, or request a quota increase.

**"At least one bucket name is required"** — deploy the backend first and provide bucket names.

**"Failed to create IAM role"** — ensure your AWS user has IAM creation permissions.

**"CDK deployment failed"** — check CloudFormation console for details, ensure CDK is bootstrapped (`cdk bootstrap`), and verify all prerequisites are met.

### Getting Help

- **CloudWatch Logs**: most runtime issues are logged here
- **CloudFormation Events**: deployment issues show in the CloudFormation console
- **Email**: ai-cic@amazon.com
- **Issues**: [GitHub Issues](https://github.com/ASUCICREPO/PDF_accessability_UI/issues)

## Contributing

Contributions to this project are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

For major changes, please open an issue first to discuss proposed changes.

## License

This project is licensed under the terms specified in the LICENSE file.

## Support

For questions, issues, or support:

- **Email**: ai-cic@amazon.com
- **Issues**: [GitHub Issues](https://github.com/ASUCICREPO/PDF_accessability_UI/issues)

---

**Built by Arizona State University's AI Cloud Innovation Center (AI CIC)**
**Powered by AWS**
