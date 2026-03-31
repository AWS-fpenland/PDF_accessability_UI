# Project Structure

```
PDF_accessability_UI/                    # Branch: fpenland/demo/UB
├── .kiro/
│   ├── steering/                        # AI development guidance (these files)
│   └── specs/                           # Feature specifications
│       └── observability-usage-tracking/ # Observability spec (from feature branch)
│
├── pdf_ui/                              # React frontend application
│   ├── public/
│   │   ├── index.html                   # UB meta tags, theme-color #005bbb
│   │   ├── ub-logo-two-line.png         # UB Libraries wordmark (landing page + footer)
│   │   ├── favicon.svg                  # PDF accessibility favicon
│   │   ├── _redirects                   # SPA redirect rules
│   │   └── manifest.json, robots.txt
│   │
│   ├── src/
│   │   ├── App.js                       # Root: AuthProvider + ThemeProvider + Routes
│   │   ├── App.css                      # Global styles (legacy — conflicts with MUI)
│   │   ├── MainApp.js                   # Auth shell: state hub, credentials, page routing
│   │   ├── index.js                     # ReactDOM entry with BrowserRouter
│   │   ├── theme.jsx                    # MUI theme (UB colors, Roboto font)
│   │   │
│   │   ├── pages/
│   │   │   ├── LandingPageNew.jsx       # ✅ ACTIVE — Modern SaaS landing (UB branded)
│   │   │   ├── LandingPage.jsx          # 📦 KEPT FOR REFERENCE — Original ASU-style landing
│   │   │   ├── CallbackPage.jsx         # OIDC callback → /app or /home
│   │   │   └── MaintenancePage.jsx      # Static maintenance page
│   │   │
│   │   ├── components/
│   │   │   ├── Header.jsx               # ✅ UB logo, usage bar, sign-out
│   │   │   ├── LeftNav.jsx              # ✅ UB branded — "UB PDF Accessibility"
│   │   │   ├── HeroSection.jsx          # ✅ UB branded hero text
│   │   │   ├── InformationBlurb.jsx     # ✅ UB branded feature cards
│   │   │   ├── UploadSection.jsx        # ✅ ACTIVE — format select + upload (CSS-based)
│   │   │   ├── UploadSection.css        # ⚠️ Still uses #8c1d40 (ASU maroon)
│   │   │   ├── ProcessingContainer.jsx  # S3 polling + progress UI
│   │   │   ├── ProcessingContainer.css  # ⚠️ Still uses #8c1d40 (ASU maroon)
│   │   │   ├── ResultsContainer.jsx     # Download + accessibility report
│   │   │   ├── ResultsContainer.css     # ⚠️ Still uses #8c1d40 (ASU maroon)
│   │   │   ├── AccessibilityChecker.jsx # Before/after report dialog
│   │   │   ├── FirstSignInDialog.jsx    # Profile collection modal
│   │   │   ├── DeploymentPopup.jsx      # ⚠️ Uses #8c1d40 (ASU maroon)
│   │   │   ├── ModernUploadSection.jsx  # 📦 UNUSED — alternative MUI upload
│   │   │   ├── FormatSelection.jsx      # 📦 UNUSED — standalone format picker
│   │   │   └── DownloadSection.jsx      # 📦 UNUSED — thin wrapper
│   │   │
│   │   ├── utilities/
│   │   │   ├── constants.jsx            # UB colors, env vars, bucket validation
│   │   │   ├── CustomCredentialsProvider.jsx # Cognito Identity federation
│   │   │   └── OldComponents/           # Deprecated (ignore)
│   │   │
│   │   └── assets/
│   │       ├── ub-logo.svg              # UB logo placeholder (header)
│   │       ├── pdf-accessability-logo.svg, pdf-icon.svg, pdf-html.svg, pdf-question.svg
│   │       ├── check.svg, dollar.svg, zap.svg  # Feature card icons
│   │       ├── Gradient.svg, bottom_gradient.svg  # Landing page backgrounds
│   │       ├── ASU_CIC_LOGO_WHITE.png   # ASU logo (used in old LandingPage.jsx)
│   │       └── POWERED_BY_AWS.png       # AWS logo
│   │
│   ├── .env.production                  # Auto-generated env vars (deploy script output)
│   └── package.json
│
├── cdk_backend/                         # AWS CDK infrastructure (TypeScript)
│   ├── bin/cdk_backend.ts               # CDK app entry
│   ├── lib/cdk_backend-stack.ts         # Cognito, Lambda, API GW, Amplify, EventBridge
│   ├── lambda/
│   │   ├── postConfirmation/index.py
│   │   ├── updateAttributes/index.py
│   │   ├── checkOrIncrementQuota/index.py
│   │   └── UpdateAttributesGroups/index.py
│   └── test/cdk_backend.test.ts         # Placeholder
│
├── docs/                                # UB-specific documentation
│   ├── UB_CUSTOMIZATION.md              # All branding changes tracked
│   ├── UB_BRANDING_SUMMARY.md           # Color/component quick reference
│   ├── MODERN_REDESIGN.md               # LandingPageNew design spec
│   ├── DEPLOYMENT_CHECKLIST.md          # Step-by-step deploy + verify
│   ├── DIRECT_AMPLIFY_DEPLOYMENT.md     # deploy-amplify-direct.sh guide
│   ├── FULL_STACK_LOCAL_DEPLOYMENT.md   # deploy-full-stack-local.sh guide
│   ├── DEPLOY_LOCAL_BRANCH.md           # Branch deployment guide
│   ├── LOCAL_TESTING.md                 # Local dev setup
│   └── IAM_PERMISSIONS.md               # Required AWS permissions
│
├── deploy.sh                            # Full stack (backend + frontend via CodeBuild)
├── deploy-frontend.sh                   # Frontend via CodeBuild (main branch)
├── deploy-frontend-ub.sh               # Frontend via CodeBuild (fpenland/demo/UB branch)
├── deploy-amplify-direct.sh            # Direct local build → Amplify deploy (frontend only)
├── deploy-full-stack-local.sh          # Full stack local (backend CDK + frontend direct)
├── UB_DEMO_README.md                    # UB demo overview
├── DEPLOYMENT_QUICK_START.md            # Quick start guide
├── report-viewer.html                   # Standalone accessibility report viewer
├── buildspec.yml                        # CodeBuild: backend CDK deploy
├── buildspec-frontend.yml               # CodeBuild: frontend build + Amplify deploy
└── README.md                            # Original project docs
```

## Data Flow

```
Browser
  ├── Auth: Cognito Hosted UI (OIDC) → /callback → /app
  ├── Upload: S3 PutObject (direct, via Cognito Identity creds)
  ├── Quota: API GW → checkOrIncrementQuota Lambda → Cognito admin API
  ├── Profile: API GW → updateAttributes Lambda → Cognito admin API
  ├── Poll: S3 HeadObject on result key (15s interval, 30min max)
  └── Download: S3 GetObject via presigned URL (8.3hr expiry)
```

## Branding Status by Component

| Component | UB Branded? | Notes |
|---|---|---|
| LandingPageNew | ✅ Yes | Full UB colors, logo, copy |
| Header | ✅ Yes | UB logo, MUI sx |
| LeftNav | ✅ Yes | "UB PDF Accessibility" |
| HeroSection | ✅ Yes | UB Blue title |
| InformationBlurb | ✅ Yes | UB Blue borders, Lake LaSalle icons |
| UploadSection | ⚠️ Partial | CSS uses #8c1d40 (ASU maroon) |
| ProcessingContainer | ⚠️ Partial | CSS uses #8c1d40 |
| ResultsContainer | ⚠️ Partial | CSS uses #8c1d40 |
| DeploymentPopup | ⚠️ Partial | Hardcoded #8c1d40 |
| FirstSignInDialog | ✅ Yes | Uses MUI theme colors |
| AccessibilityChecker | ✅ Yes | Uses MUI theme colors |

## Unused Files (kept for reference)

- `LandingPage.jsx` — original ASU landing page
- `ModernUploadSection.jsx` — alternative upload UI, never wired in
- `FormatSelection.jsx` — standalone format picker, merged into UploadSection
- `DownloadSection.jsx` — thin wrapper around ProcessingContainer
- `OldComponents/` — deprecated utilities
- `ASU_CIC_LOGO_WHITE.png` — ASU logo (only used by old LandingPage)
