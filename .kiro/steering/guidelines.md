# Development Guidelines

## Before Making Changes

1. You are on the `fpenland/demo/UB` branch — a UB-branded fork. Do not merge to `main` without review.
2. Check the branding status table in `structure.md` — some components still have ASU colors in CSS.
3. Any new `REACT_APP_*` env var must also be added to `cdk_backend-stack.ts` `mainBranch.addEnvironment()` AND the deploy scripts.

## Branding Rules

- Use UB colors from `constants.jsx` — never hardcode hex values
- New components: use MUI `sx` prop, not CSS files
- If editing a CSS file, replace any `#8c1d40` (ASU maroon) with `#005bbb` (UB Blue) or `#00a69c` (Lake LaSalle)
- Responsive: use MUI breakpoints (`{ xs: ..., sm: ..., md: ... }`)
- Touch targets: minimum 44px (enforced in theme.jsx)
- Font: Roboto (set in theme.jsx). Do not use `Geist`.

## Component Patterns

### Adding a New Page
1. Create in `src/pages/`
2. Add route in `App.js` `AppRoutes`
3. If authenticated, wrap with `auth.isAuthenticated` check
4. Add Amplify rewrite rule in `cdk_backend-stack.ts`

### Adding a New API Endpoint
1. Lambda in `cdk_backend/lambda/<name>/index.py`
2. Construct + API GW resource in `cdk_backend-stack.ts`
3. `REACT_APP_<NAME>_API` env var → Amplify branch + deploy scripts
4. Constant in `constants.jsx`
5. Call with `fetch()` + `Authorization: Bearer ${auth.user?.id_token}`

### Modifying Cognito Attributes
- Defined in CDK stack — cannot be deleted after creation
- Frontend reads: `auth.user?.profile?.['custom:<name>']`
- Backend reads/writes: `cognito_client.admin_get_user` / `admin_update_user_attributes`

## S3 Key Conventions (DO NOT CHANGE)

| Format | Upload Key | Result Key |
|---|---|---|
| PDF-to-PDF | `pdf/<unique_filename>` | `result/COMPLIANT_<unique_filename>` |
| PDF-to-HTML | `uploads/<unique_filename>` | `remediated/final_<sanitized_filename>.zip` |
| Accessibility Reports | — | `temp/<name>/accessability-report/*.json` |

## Error Handling

- API errors: try/catch → set error state → MUI Snackbar
- S3 errors: retry with backoff (see AccessibilityChecker)
- Auth errors: check "No matching state found" → force re-auth (MainApp.js)

## Deployment (UB Branch)

Preferred method — direct local build:
```bash
cd PDF_accessability_UI
./deploy-amplify-direct.sh [PDF_BUCKET] [HTML_BUCKET]
```

This script:
1. Reads CloudFormation outputs from `CdkBackendStack`
2. Generates `.env.production`
3. Builds React app locally
4. Zips and uploads to Amplify
5. Monitors deployment status

### Verification Checklist
1. Landing page loads with UB branding at Amplify URL
2. Sign up → verify email → first sign-in dialog appears
3. Choose format → upload PDF → processing starts
4. Download result → verify accessibility report (PDF-to-PDF only)
5. Quota increments correctly in header
6. Sign out returns to landing page
