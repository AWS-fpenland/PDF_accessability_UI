# Code Quality & Known Issues

## Branding Gaps (Primary Concern for This Branch)

The UB rebranding is incomplete. MUI-based components use UB colors correctly, but CSS-based components still use ASU maroon (`#8c1d40`):

- `UploadSection.css` — `.upload-btn`, `.progress-fill`, `.format-option.selected` all use `#8c1d40`
- `ProcessingContainer.css` — `.step-number.active`, `.upload-new-btn`, `.confirm-header`, `.confirm-btn-primary` use `#8c1d40`
- `ResultsContainer.css` — `.download-btn`, `.view-report-btn`, `.file-icon`, `.confirm-header` use `#8c1d40`
- `DeploymentPopup.jsx` — hardcoded `backgroundColor: '#8c1d40'` in sx props

To complete the rebrand, replace all `#8c1d40` with `#005bbb` (UB Blue) or `#00a69c` (Lake LaSalle) as appropriate.

## Architecture Issues

### State Management
- All auth-app state in `MainApp.js` with 10+ props drilled to `UploadSection`. Manageable at current size but would benefit from React Context if more features are added.

### Duplicate Logic
- `sanitizeFilename()` is copy-pasted between `UploadSection.jsx` and `ProcessingContainer.jsx`. Should be extracted to `utilities/`.
- Confirmation dialog CSS is duplicated between `ProcessingContainer.css` and `ResultsContainer.css`.

### CSS Conflicts
- `App.css` sets `div { margin: 20px }` globally — affects every div in the app, fighting MUI layouts.
- CSS files reference `Geist` font family which is never loaded. Falls back to system fonts, creating inconsistency with MUI's Roboto.

### Hardcoded Stale Values
- `LeftNav.jsx` says "8 PDF document uploads" but `postConfirmation` Lambda sets default to 8 for DefaultUsers. However, `LandingPage.jsx` (old, kept for reference) says "3". The values should come from the user's actual quota, not be hardcoded.
- `UpdateAttributesGroups/index.py` has `USER_POOL_ID = ''` — works for EventBridge invocations but manual invocations fail.

## Security Notes

- Lambda IAM roles use `resources: ['*']` for Cognito actions — functional but overly permissive
- CORS: `Access-Control-Allow-Origin: *` on all API responses
- `.env.production` committed with real Cognito pool IDs and API endpoints — not secrets, but should be `.gitignore`d and generated at deploy time
- Presigned URLs: 8.33-hour expiration (`expiresIn: 30000`). Consider reducing for sensitive documents.
- S3 uploads on this branch do NOT include user metadata (sub, groups, timestamp) — the `observability` branch adds this

## What's Done Well

- Cognito authorizer on all API Gateway endpoints
- Client-side AND server-side quota enforcement
- File type + size + page count validation before upload
- Bucket configuration validation with helpful deployment popup
- Comprehensive deploy scripts with auto-detection of CloudFormation outputs
- Good mobile responsiveness in MUI components

## Performance

- `ProcessingContainer` polls S3 every 15s for up to 30 minutes — reasonable
- `country-state-city` loads all world location data on import — adds to bundle for a one-time dialog
- `LandingPageNew` uses framer-motion animations — smooth but adds ~30KB to bundle

## Accessibility (for an Accessibility Tool)

- `UploadSection.jsx` format option cards use `onClick` on divs without `role="button"` or `tabIndex` — not keyboard accessible
- The unused `FormatSelection.jsx` actually has proper ARIA and keyboard handling
- Custom confirmation dialogs use raw divs instead of MUI Dialog — no focus trap or escape-key handling
- `Header.jsx` passes hex string to AppBar `color` prop instead of theme palette key

## Testing Gaps

- 3 test files: `App.test.js` (smoke), `UploadSection.test.jsx`, `UploadSection.metadata.test.js`
- No tests for: auth flow, quota management, S3 upload/download, processing polling, accessibility checker, landing page
- No CDK snapshot tests
- No E2E tests

## Placeholder Content

These need real values before production:
- `ub-logo.svg` — placeholder SVG, needs official UB logo
- `ub-accessibility@buffalo.edu` — placeholder email in LeftNav
- `library-accessibility@buffalo.edu` — placeholder email in LandingPageNew footer
- Footer: "NON-PRODUCTION • FOR DEMO USE ONLY" disclaimer
