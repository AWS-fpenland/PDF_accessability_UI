# Project Structure

This workspace contains two related repositories for PDF accessibility solutions.

## Repository: PDF_accessability_UI

Frontend web application and backend API infrastructure.

```
PDF_accessability_UI/
├── pdf_ui/                      # React frontend application
│   ├── src/                     # React source code
│   ├── public/                  # Static assets
│   └── package.json             # Frontend dependencies
│
├── cdk_backend/                 # AWS CDK infrastructure (TypeScript)
│   ├── bin/                     # CDK app entry point
│   ├── lib/                     # CDK stack definitions
│   ├── lambda/                  # Lambda function code
│   ├── test/                    # CDK tests
│   └── package.json             # CDK dependencies
│
├── docs/                        # Documentation
├── deploy.sh                    # Unified deployment script
├── deploy-frontend.sh           # Frontend-only deployment
└── buildspec*.yml               # CodeBuild specifications
```

### Key Patterns
- Cognito User Pool with custom attributes for quota management
- Lambda functions for user profile and quota operations
- EventBridge rules trigger quota updates on group changes
- Amplify hosts the React SPA with automatic HTTPS

## Repository: PDF_Accessibility

Backend processing engines for PDF remediation.

```
PDF_Accessibility/
├── app.py                       # Main CDK application (Python)
├── cdk/                         # CDK stack definitions
│   ├── __init__.py
│   └── cdk_stack.py
│
├── lambda/                      # Lambda functions
│   ├── split_pdf/               # PDF splitting logic
│   ├── add_title/               # Title generation
│   ├── java_lambda/             # PDF merger (Java)
│   ├── accessibility_checker_before_remidiation/
│   └── accessability_checker_after_remidiation/
│
├── docker_autotag/              # Python container for Adobe API processing
├── javascript_docker/           # Node.js container for LLM alt text
│
├── pdf2html/                    # PDF-to-HTML solution
│   ├── cdk/                     # TypeScript CDK for pdf2html
│   ├── content_accessibility_utility_on_aws/
│   │   ├── pdf2html/            # PDF to HTML conversion
│   │   ├── remediate/           # Accessibility remediation
│   │   ├── audit/               # Compliance checking
│   │   └── batch/               # Batch processing
│   ├── lambda_function.py       # Lambda entry point
│   └── Dockerfile               # Container definition
│
├── docs/                        # Documentation
├── deploy.sh                    # Unified deployment script
├── cdk.json                     # CDK configuration
└── requirements.txt             # Python dependencies
```

### Key Patterns

**PDF-to-PDF Pipeline**:
1. S3 upload triggers split_pdf Lambda
2. Lambda starts Step Functions state machine
3. Parallel execution:
   - Pre-check accessibility (a11y_precheck)
   - Map state processes chunks in parallel:
     - ECS Task 1: Adobe AutoTag + extraction (Python)
     - ECS Task 2: LLM alt text generation (Node.js)
   - Java Lambda merges processed chunks
   - add_title Lambda generates document title
   - Post-check accessibility (a11y_postcheck)
4. Results stored in S3 result/ folder

**PDF-to-HTML Pipeline**:
1. S3 upload to uploads/ folder triggers Lambda
2. Lambda container processes PDF using Bedrock Data Automation
3. Generates HTML, images, and remediation report
4. Outputs to remediated/ folder as zip file

## Naming Conventions

- **S3 Buckets**: 
  - PDF-to-PDF: `pdfaccessibility-*`
  - PDF-to-HTML: `pdf2html-bucket-*`
- **Lambda Functions**: Descriptive names (SplitPDF, AddTitleLambda, etc.)
- **ECS Tasks**: MyFirstTaskDef (Python), MySecondTaskDef (JavaScript)
- **Log Groups**: `/aws/lambda/{function-name}`, `/ecs/{task-def}/{container}`
- **Cognito Attributes**: `custom:*` prefix for all custom user attributes

## Configuration Files

- `cdk.json`: CDK app configuration and feature flags
- `buildspec*.yml`: CodeBuild build specifications
- `package.json`: Node.js dependencies and scripts
- `requirements.txt`: Python dependencies
- `tsconfig.json`: TypeScript compiler options

## Environment Variables

Lambda and ECS tasks receive configuration via environment variables:
- `S3_BUCKET_NAME`, `S3_FILE_KEY`, `S3_CHUNK_KEY`
- `STATE_MACHINE_ARN`
- `BUCKET_NAME`
- `model_arn_image`, `model_arn_link`
- `AWS_REGION`

## Deployment Artifacts

- Docker images pushed to ECR
- Lambda deployment packages (zip or container)
- CloudFormation stacks created by CDK
- Amplify app for frontend hosting
