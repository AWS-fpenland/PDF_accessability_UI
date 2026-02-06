# Technology Stack & Conventions

## Frontend (pdf_ui/)

- **React 19** with Create React App (react-scripts 5.0.1)
- **MUI 6.3.1** (@mui/material, @mui/icons-material, @mui/lab)
- **react-router-dom 7** — routes: `/home`, `/callback`, `/app`
- **react-oidc-context 3** — Cognito OIDC authentication
- **framer-motion 11** — page transitions and landing page animations
- **pdf-lib** — client-side PDF page count validation
- **AWS SDK v3** — S3 (upload/download), Cognito Identity (federated credentials)
- **country-state-city** — location picker for first-sign-in dialog

### Coding Conventions

- Components are `.jsx`, one per file. No TypeScript in the frontend.
- Utilities in `src/utilities/`, pages in `src/pages/`, components in `src/components/`
- Environment variables: `REACT_APP_*` prefix (CRA convention), sourced from `.env.production` or Amplify env vars
- Theme: `src/theme.jsx` using MUI `createTheme`, colors from `constants.jsx`
- No state management library — `MainApp.js` is the state hub with prop drilling
- Auth: `useAuth()` hook from react-oidc-context
- AWS credentials: `CustomCredentialsProvider` class → Cognito Identity `getId` + `getCredentialsForIdentity`

### Styling Approach (Mixed — Historical)

The codebase has two styling patterns due to its evolution:

1. **CSS files** — `UploadSection.css`, `ProcessingContainer.css`, `ResultsContainer.css`. These use the `Geist` font (never loaded — falls back to system fonts) and ASU maroon `#8c1d40` for accent colors. These predate the UB branding work.
2. **MUI `sx` prop** — Header, LeftNav, HeroSection, InformationBlurb, LandingPageNew, FirstSignInDialog. These use UB colors from `constants.jsx`.

New code should use MUI `sx` prop with theme colors. The CSS files are candidates for migration.

### UB Color Palette (constants.jsx)

| Constant | Value | Name |
|---|---|---|
| `PRIMARY_MAIN` | `#005bbb` | UB Blue |
| `SECONDARY_MAIN` | `#00a69c` | Lake LaSalle |
| `CHAT_LEFT_PANEL_BACKGROUND` | `#002f56` | Harriman Blue |
| `HEADER_BACKGROUND` | `#005bbb` | UB Blue |
| `primary_50` | `#e6f0ff` | Light UB Blue |

Note: CSS files still use `#8c1d40` (ASU maroon) for upload/processing/results UI. This is the main remaining branding inconsistency.

## Backend Infrastructure (cdk_backend/)

- **AWS CDK 2.173.2** with TypeScript 5.6
- **@aws-cdk/aws-amplify-alpha** — Amplify app construct
- Lambda runtime: **Python 3.12**
- API Gateway REST API with Cognito authorizer
- EventBridge → CloudTrail for group membership change events

### Lambda Functions

| Function | Purpose | Trigger |
|---|---|---|
| `postConfirmation` | Init user attributes + assign group on signup | Cognito PostConfirmation |
| `updateAttributes` | Update profile on first sign-in | API Gateway POST |
| `checkOrIncrementQuota` | Check or increment upload quota | API Gateway POST |
| `UpdateAttributesGroups` | Sync limits on group membership change | EventBridge |

## Build & Deploy

### UB-Specific Deployment (this branch)

```bash
# Direct deploy (recommended) — builds locally, pushes to Amplify
./deploy-amplify-direct.sh [PDF_BUCKET] [HTML_BUCKET]

# UB frontend via CodeBuild — deploys fpenland/demo/UB branch
./deploy-frontend-ub.sh <PROJECT_NAME> <PDF_BUCKET> <HTML_BUCKET> <ROLE_ARN>

# Full stack (backend CDK + frontend)
./deploy.sh
```

### Local Development

```bash
cd pdf_ui && npm install && npm start  # port 3000
# Requires .env with all REACT_APP_* vars
# Commented-out localhost redirect URIs in App.js
```

### CDK Backend

```bash
cd cdk_backend && npm install && npm run build
npx cdk deploy -c PDF_TO_PDF_BUCKET=<name> -c PDF_TO_HTML_BUCKET=<name>
```

## Testing

- Jest + React Testing Library. Minimal coverage:
  - `App.test.js` — smoke test
  - `UploadSection.test.jsx` — upload component tests
  - `UploadSection.metadata.test.js` — metadata tests
- CDK: single placeholder test
- No E2E tests
