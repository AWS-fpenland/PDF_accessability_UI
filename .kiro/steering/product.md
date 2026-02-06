# Product Overview

## What This Is

A custom-branded deployment of the ASU AI CIC's PDF Accessibility Solution for University at Buffalo (UB) Libraries. This branch (`fpenland/demo/UB`) replaces all ASU branding with UB identity while preserving the full remediation functionality.

The upstream solution lives at [ASUCICREPO/PDF_Accessibility](https://github.com/ASUCICREPO/PDF_Accessibility). This repo is the frontend UI only — the backend must be deployed separately.

## Branch Context

- `main` — upstream ASU-branded UI
- `fpenland/demo/UB` — **this branch** — UB Libraries custom branding + modern landing page
- `fpenland/feature/observability` — observability/usage tracking feature work
- `DEV/fpenland` — development branch

This is a demo/non-production deployment. The footer explicitly states "NON-PRODUCTION • FOR DEMO USE ONLY".

## Core User Flows

1. **Landing → Auth**: `LandingPageNew.jsx` (modern SaaS-style, UB-branded) → Cognito Hosted UI (OIDC code flow) → `/callback` → `/app`
2. **First Sign-In**: Profile dialog collects organization + location → updates Cognito custom attributes via API Gateway
3. **Format Selection → Upload → Processing → Results**: Choose PDF-to-PDF or PDF-to-HTML → upload to S3 → poll for result → download
4. **Quota Management**: Three user groups (DefaultUsers, AmazonUsers, AdminUsers) with different limits stored in Cognito custom attributes

## UB Branding

| Element | Color | Hex |
|---|---|---|
| Primary (headers, buttons) | UB Blue | `#005bbb` |
| Accent (CTAs, success) | Lake LaSalle | `#00a69c` |
| Dark (nav, text) | Harriman Blue | `#002f56` |
| Secondary text | Townsend Gray | `#666666` |

Logo: `ub-logo.svg` (placeholder SVG) and `ub-logo-two-line.png` (UB Libraries wordmark). Both need replacement with official assets before production.

## Key Constraints

- Backend must be deployed first — UI validates bucket config at runtime
- Two separate S3 buckets: `pdfaccessibility-*` (PDF-to-PDF), `pdf2html-bucket-*` (PDF-to-HTML)
- File limits enforced client-side (pdf-lib page count, file size) AND server-side (quota Lambda)
- Presigned URLs for upload (PutObject) and download (GetObject)
- Contact emails (`ub-accessibility@buffalo.edu`, `library-accessibility@buffalo.edu`) are placeholders

## What Not To Change Without Discussion

- Cognito custom attribute schema
- S3 key path conventions (`pdf/`, `uploads/`, `result/COMPLIANT_`, `remediated/final_`)
- API Gateway endpoint contracts
- OIDC authentication flow and redirect URIs
- User group names and precedence logic
