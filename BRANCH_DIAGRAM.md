# Branch Relationship Diagram

## Current State

```
ASUCICREPO/PDF_accessability_UI (upstream)
│
├── main (origin/main)
│   │
│   ├── 9e28497 ← Common ancestor (2-3 months ago)
│   │   │
│   │   ├─────────────────────────────────────────────┐
│   │   │                                             │
│   │   │ [Your branch diverged here]                 │
│   │   │                                             │
│   │   ↓                                             ↓
│   │   13 commits on main:                           20 commits on feature/job-history:
│   │   • Security fixes (PR #8)                      • UB branding changes
│   │   • Accessibility (PR #10)                      • Job history feature
│   │   • Disclaimers                                 • Observability specs
│   │   • Limit updates                               • Deployment improvements
│   │   • CORS updates                                • Documentation
│   │   • YouTube link                                • Tests
│   │   • IAM policy fixes                            • Direct deploy script
│   │   │                                             │
│   │   ↓                                             ↓
│   │   e68880d (current main)                        976d425 (feature/job-history)
│   │                                                  │
│   │                                                  ↓
│   │                                                  fork/feature/job-history
│   │                                                  (AWS-fpenland/PDF_accessability_UI)
│   │
│   └── pdf2html (other branch)
│
└── (other branches)


CONFLICT ZONE:
═══════════════════════════════════════════════════════════════
File: pdf_ui/src/pages/LandingPage.jsx (lines ~201-210)

main:                           feature/job-history:
color: '#FFC627' (ASU Gold)     color: '#00a69c' (UB Lake LaSalle)
text: "click 'Log In...'"       text: "click the button to the right"
═══════════════════════════════════════════════════════════════
```

---

## Proposed Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: Sync Your Feature Branch                               │
└─────────────────────────────────────────────────────────────────┘

origin/main (e68880d)
    │
    │ git fetch origin
    │ git merge origin/main
    ↓
feature/job-history (976d425)
    │
    │ [Resolve conflict - keep UB branding]
    │ git add LandingPage.jsx
    │ git commit
    ↓
feature/job-history (NEW: includes upstream changes + UB branding)
    │
    │ git push fork feature/job-history
    ↓
fork/feature/job-history (updated)


┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: Create Clean Merge Request Branch                      │
└─────────────────────────────────────────────────────────────────┘

origin/main (e68880d)
    │
    │ git checkout -b merge-request/job-history origin/main
    ↓
merge-request/job-history (clean slate)
    │
    │ git cherry-pick 1057686  # job history spec
    │ git cherry-pick 2c27c9b  # backend
    │ git cherry-pick e25e77b  # frontend
    │ git cherry-pick 22765bd  # deploy script
    │ git cherry-pick 220c78c  # fix
    │ git cherry-pick 845d6ff  # cognito fix
    ↓
merge-request/job-history (ONLY job history feature, NO UB branding)
    │
    │ git push fork merge-request/job-history
    ↓
fork/merge-request/job-history
    │
    │ [Create Pull Request on GitHub]
    ↓
ASUCICREPO/PDF_accessability_UI
    Pull Request: merge-request/job-history → main


┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: After PR is Merged                                     │
└─────────────────────────────────────────────────────────────────┘

origin/main (includes your job history feature!)
    │
    │ git fetch origin
    │ git checkout fpenland/demo/UB
    │ git merge origin/main
    ↓
fpenland/demo/UB (updated with upstream + keeps UB branding)
    │
    │ [Resolve any new branding conflicts]
    │ git push fork fpenland/demo/UB
    ↓
Your UB deployment stays current with upstream!
```

---

## Branch Purposes

```
┌──────────────────────────────────────────────────────────────────┐
│ Branch                    │ Purpose                              │
├──────────────────────────────────────────────────────────────────┤
│ origin/main               │ Upstream ASU project (read-only)     │
│ feature/job-history       │ Your working branch (all changes)    │
│ merge-request/job-history │ Clean branch for PR (job hist only)  │
│ fpenland/demo/UB          │ UB deployment branch (UB branding)   │
│ fork/feature/job-history  │ Your fork backup                     │
└──────────────────────────────────────────────────────────────────┘
```

---

## File Distribution

```
┌─────────────────────────────────────────────────────────────────────┐
│ What Goes Where?                                                    │
└─────────────────────────────────────────────────────────────────────┘

JOB HISTORY FEATURE (→ merge-request/job-history → upstream)
├── cdk_backend/lambda/jobHistory/index.py
├── cdk_backend/lib/cdk_backend-stack.ts (job history parts)
├── pdf_ui/src/components/JobHistory.jsx
├── pdf_ui/src/MainApp.js (job history integration)
├── pdf_ui/src/App.js (job history route)
├── pdf_ui/src/components/UploadSection.jsx (tracking)
├── pdf_ui/src/components/ProcessingContainer.jsx (tracking)
├── deploy-amplify-direct.sh (job history API env var)
├── .kiro/specs/job-history/
└── .gitignore

UB BRANDING (→ stays in feature/job-history & fpenland/demo/UB)
├── pdf_ui/src/pages/LandingPageNew.jsx
├── pdf_ui/src/assets/ub-logo.svg
├── pdf_ui/public/ub-logo-two-line.png
├── pdf_ui/src/pages/LandingPage.jsx (color changes)
├── pdf_ui/src/components/Header.jsx (UB branding)
├── pdf_ui/src/components/LeftNav.jsx (UB branding)
├── pdf_ui/src/components/HeroSection.jsx (UB branding)
├── pdf_ui/src/components/InformationBlurb.jsx (UB branding)
├── pdf_ui/src/theme.jsx (UB colors)
├── pdf_ui/src/utilities/constants.jsx (UB colors)
├── pdf_ui/public/index.html (UB meta tags)
├── docs/UB_*.md
├── UB_DEMO_README.md
└── deploy-frontend-ub.sh

INFRASTRUCTURE (→ can go to upstream if desired)
├── deploy-amplify-direct.sh
├── docs/DEPLOYMENT_CHECKLIST.md
├── docs/DIRECT_AMPLIFY_DEPLOYMENT.md
├── docs/LOCAL_TESTING.md
├── pdf_ui/src/components/UploadSection.test.jsx
├── pdf_ui/src/components/UploadSection.metadata.test.js
└── report-viewer.html

OBSERVABILITY (→ specs only, implementation incomplete)
├── .kiro/specs/observability-usage-tracking/
└── (no implementation files yet)

AI TOOLING (→ probably stays in your fork)
├── .kiro/steering/
└── (project-specific AI guidance)
```

---

## Commit Flow

```
YOUR FEATURE BRANCH (feature/job-history)
═══════════════════════════════════════════════════════════════════
2cd6ad4  docs: Add deployment checklist and testing guide
7e91e2d  docs: Add comprehensive UB demo README
ad8d816  feat: Add modern SaaS-style landing page for UB Libraries
a9868d8  docs: Add comprehensive modern redesign documentation
4fc0509  feat: Add UB Libraries logo to navigation and footer
ac6c76b  feat: Update footer with demo disclaimer and AWS attribution
95142c1  feat: Add UB-specific deployment script and comprehensive...
02bb34e  feat: Add direct Amplify deployment script for local builds
1b79f1f  fix: Improve direct deploy script with bucket parameters...
cdc8805  fix: Use correct Cognito OIDC discovery endpoint format...
756271a  report view and updated ignore file to exclude output
970d3f1  feat: create observability and usage tracking spec...
7e6f054  feat(ub): merge observability tracking and update steering...
1057686  docs: add job history & re-download feature spec ← INCLUDE
2c27c9b  feat(backend): add job history DynamoDB table... ← INCLUDE
845d6ff  fix(cdk): make Cognito domain prefix deterministic ← INCLUDE
e25e77b  feat(ui): add job history tab with tracking... ← INCLUDE
22765bd  feat(deploy): add REACT_APP_JOB_HISTORY_API... ← INCLUDE
220c78c  fix(ui): fix page count not showing in job history ← INCLUDE
976d425  added prod env file ← MAYBE INCLUDE


CLEAN MERGE REQUEST BRANCH (merge-request/job-history)
═══════════════════════════════════════════════════════════════════
[Only the commits marked ← INCLUDE above]
[Cherry-picked onto latest origin/main]
[No UB branding, no AI tooling, no incomplete features]
```

---

## Conflict Resolution Strategy

```
CONFLICT: pdf_ui/src/pages/LandingPage.jsx
═══════════════════════════════════════════════════════════════════

SCENARIO 1: Merging into feature/job-history (your working branch)
→ KEEP YOUR VERSION (UB branding)
→ This branch is for your work, including UB customization

<Box component="span" sx={{ color: '#00a69c', fontWeight: 'bold' }}>
  click the button to the right
</Box>


SCENARIO 2: Creating merge-request/job-history (for upstream PR)
→ DON'T INCLUDE THIS FILE AT ALL
→ Or cherry-pick commits that don't touch LandingPage.jsx
→ Or reset this file to origin/main version

<Box component="span" sx={{ color: '#FFC627', fontWeight: 'bold' }}>
  click "Log In and Remediate My PDF"
</Box>


SCENARIO 3: Updating fpenland/demo/UB (your deployment)
→ KEEP UB VERSION (same as scenario 1)
→ This is your production UB deployment
```

---

## Timeline

```
PAST                    NOW                     FUTURE
═══════════════════════════════════════════════════════════════════

2-3 months ago          Today                   After PR merge
     │                    │                           │
     │                    │                           │
9e28497 ←─────────────────┼───────────────────────────┤
(common                   │                           │
ancestor)                 │                           │
     │                    │                           │
     ├─→ main             │                           │
     │   (13 commits)     │                           │
     │        │           │                           │
     │        ↓           │                           │
     │    e68880d ←───────┤                           │
     │    (current        │                           │
     │     main)          │                           │
     │                    │                           │
     ├─→ feature/         │                           │
     │   job-history      │                           │
     │   (20 commits)     │                           │
     │        │           │                           │
     │        ↓           │                           │
     │    976d425 ←───────┤                           │
     │    (your           │                           │
     │     branch)        │                           │
     │                    │                           │
     │                    ↓                           │
     │              [SYNC NOW]                        │
     │                    │                           │
     │                    ├─→ merge origin/main       │
     │                    │   into feature/           │
     │                    │   job-history             │
     │                    │                           │
     │                    ├─→ create merge-           │
     │                    │   request/                │
     │                    │   job-history             │
     │                    │                           │
     │                    ├─→ submit PR               │
     │                    │                           │
     │                    │                           ↓
     │                    │                    [PR MERGED]
     │                    │                           │
     │                    │                           ├─→ main now has
     │                    │                           │   job history!
     │                    │                           │
     │                    │                           ├─→ update UB
     │                    │                           │   branch from
     │                    │                           │   new main
     │                    │                           │
     │                    │                           ↓
     │                    │                    [STAY CURRENT]
```

---

## Decision Matrix

```
┌─────────────────────────────────────────────────────────────────┐
│ Question                  │ Answer                              │
├─────────────────────────────────────────────────────────────────┤
│ Merge or Rebase?          │ MERGE (preserves history)           │
│ Include UB branding?      │ NO (keep in separate branch)        │
│ Include observability?    │ SPECS ONLY (implementation incomplete)│
│ Include .kiro/steering/?  │ NO (project-specific)               │
│ Include tests?            │ YES (valuable addition)             │
│ Include deploy scripts?   │ YES (but not UB-specific one)       │
│ Include documentation?    │ YES (but not UB-specific docs)      │
│ Fix Cognito domain?       │ YES (good fix for everyone)         │
│ Include .gitignore?       │ YES (good practice)                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Success Criteria

```
✅ BEFORE SUBMITTING PR:
├── [ ] feature/job-history merged with origin/main
├── [ ] All tests pass
├── [ ] Build succeeds
├── [ ] merge-request/job-history created from origin/main
├── [ ] Only job history commits cherry-picked
├── [ ] No UB branding in merge request branch
├── [ ] No .kiro/steering/ files in merge request
├── [ ] No incomplete features in merge request
├── [ ] Conflict resolved (if any)
├── [ ] Screenshots prepared
└── [ ] PR description written

✅ AFTER PR MERGED:
├── [ ] fpenland/demo/UB updated from new main
├── [ ] UB branding preserved in deployment branch
├── [ ] All features working in UB deployment
└── [ ] Documentation updated
```

---

## Quick Reference Commands

```bash
# See what's different between branches
git diff --name-status main...feature/job-history

# See commits unique to your branch
git log --oneline main..feature/job-history

# See commits on main you don't have
git log --oneline feature/job-history..main

# Find common ancestor
git merge-base main feature/job-history

# Test merge without committing
git merge --no-commit --no-ff main

# Abort merge
git merge --abort

# See conflicting files
git diff --name-only --diff-filter=U

# Cherry-pick a commit
git cherry-pick <commit-hash>

# Reset file to upstream version
git checkout origin/main -- <file>

# See what would be in PR
git diff origin/main...merge-request/job-history
```
