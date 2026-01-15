# Technology Stack

## Backend (PDF_Accessibility)

### Infrastructure
- **IaC**: AWS CDK (Python)
- **Runtime**: Python 3.12
- **Container Platform**: Docker, AWS ECS Fargate, AWS ECR
- **Orchestration**: AWS Step Functions
- **Compute**: AWS Lambda, ECS Tasks
- **Storage**: Amazon S3
- **AI/ML**: AWS Bedrock (Claude 3.5 Sonnet, Claude 3 Haiku, Nova Pro), Adobe PDF Services API
- **Monitoring**: CloudWatch Logs, CloudWatch Dashboards
- **Secrets**: AWS Secrets Manager

### Key Dependencies
```
aws-cdk-lib==2.147.2
constructs>=10.0.0,<11.0.0
```

### Architecture Patterns
- Event-driven processing (S3 triggers)
- Parallel processing with Step Functions Map state
- Containerized workloads for PDF processing
- Multi-stage pipeline: Split → Process → Merge → Validate

## Frontend (PDF_accessability_UI)

### UI Framework
- **Framework**: React 19.0.0
- **Build Tool**: react-scripts 5.0.1
- **UI Library**: Material-UI (MUI) 6.3.1
- **Routing**: react-router-dom 7.1.1
- **Animation**: framer-motion 11.16.4

### Backend Infrastructure
- **IaC**: AWS CDK (TypeScript)
- **Runtime**: Node.js with TypeScript 5.6.3
- **Hosting**: AWS Amplify
- **Authentication**: Amazon Cognito with react-oidc-context
- **API**: API Gateway with Lambda backends
- **Event Processing**: EventBridge for quota updates

### Key Dependencies
```json
{
  "aws-cdk-lib": "2.173.2",
  "@aws-cdk/aws-amplify-alpha": "^2.173.2-alpha.0",
  "@aws-sdk/client-s3": "^3.723.0",
  "@aws-sdk/client-cognito-identity": "^3.723.0",
  "react": "^19.0.0",
  "@mui/material": "^6.3.1"
}
```

## Common Commands

### Backend Deployment (PDF_Accessibility)
```bash
# One-click deployment
chmod +x deploy.sh
./deploy.sh

# Manual CDK deployment
cdk bootstrap  # First time only
cdk synth
cdk deploy

# Redeploy via CodeBuild
aws codebuild start-build --project-name YOUR-PROJECT-NAME --source-version main
```

### Frontend Deployment (PDF_accessability_UI)
```bash
# One-click deployment (includes backend)
chmod +x deploy.sh
./deploy.sh

# Frontend only deployment
chmod +x deploy-frontend.sh
./deploy-frontend.sh

# Local development
cd pdf_ui
npm install
npm start  # Runs on http://localhost:3000

# Build for production
npm run build

# Run tests
npm test
```

### Backend CDK (TypeScript)
```bash
cd cdk_backend
npm install
npm run build    # Compile TypeScript
npm run watch    # Watch mode
npm test         # Run tests
npm run cdk      # CDK commands
```

## Build Systems

- **Python Backend**: CDK with Docker image builds for Lambda and ECS
- **TypeScript Backend**: CDK with npm/tsc compilation
- **React Frontend**: Create React App (react-scripts) with npm

## Testing

- **Frontend**: Jest with React Testing Library
- **Backend CDK**: Jest with ts-jest

## Platform Requirements

- AWS Account with appropriate IAM permissions
- AWS CloudShell or AWS CLI configured locally
- Docker (for local builds and PDF-to-HTML solution)
- Node.js and npm (for frontend and TypeScript CDK)
- Python 3.12+ (for Python CDK)
