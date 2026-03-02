# Step-by-Step: Syncing Your Branch with Upstream

## Current Situation
- Your branch: `feature/job-history` (20 commits ahead)
- Upstream: `origin/main` (13 commits ahead)
- Diverged at: commit `9e28497` (~2-3 months ago)
- Conflicts: 1 file (LandingPage.jsx)

---

## Option 1: Merge Upstream (Recommended for Feature Branch)

This preserves your complete history and is best for your working branch.

### Step 1: Backup Your Current Branch
```bash
# Create a backup in case something goes wrong
git branch feature/job-history-backup
```

### Step 2: Fetch Latest from Upstream
```bash
# Get all the latest changes from upstream
git fetch origin

# See what's new
git log --oneline feature/job-history..origin/main
```

### Step 3: Merge Upstream Main
```bash
# Make sure you're on your feature branch
git checkout feature/job-history

# Merge upstream main
git merge origin/main
```

**Expected output:**
```
Auto-merging cdk_backend/lib/cdk_backend-stack.ts
Auto-merging pdf_ui/src/pages/LandingPage.jsx
CONFLICT (content): Merge conflict in pdf_ui/src/pages/LandingPage.jsx
Automatic merge failed; fix conflicts and then commit the result.
```

### Step 4: Resolve the Conflict

Open `pdf_ui/src/pages/LandingPage.jsx` and find the conflict markers:

```jsx
<<<<<<< HEAD
<Box component="span" sx={{ color: '#00a69c', fontWeight: 'bold' }}>
  click the button to the right
=======
<Box component="span" sx={{ color: '#FFC627', fontWeight: 'bold' }}>
  click "Log In and Remediate My PDF"
>>>>>>> origin/main
```

**Decision**: Since you're keeping UB branding in your feature branch, keep YOUR version:

```jsx
<Box component="span" sx={{ color: '#00a69c', fontWeight: 'bold' }}>
  click the button to the right
</Box>
```

Remove the conflict markers and save the file.

### Step 5: Complete the Merge
```bash
# Mark the conflict as resolved
git add pdf_ui/src/pages/LandingPage.jsx

# Check status
git status

# Complete the merge
git commit -m "chore: merge upstream main into feature/job-history

- Resolved branding conflict in LandingPage.jsx (kept UB branding)
- Pulled in security fixes from PR #8
- Pulled in accessibility improvements from PR #10
- Pulled in disclaimers and limit updates"

# Verify the merge
git log --oneline --graph -10
```

### Step 6: Test Everything
```bash
# Install any new dependencies
cd pdf_ui
npm install

# Run tests
npm test

# Build to verify no errors
npm run build

# Test locally if possible
npm start
```

### Step 7: Push to Your Fork
```bash
# Push the updated branch
git push fork feature/job-history

# If you get a rejection, force push (safe since it's your fork)
git push fork feature/job-history --force-with-lease
```

---

## Option 2: Rebase (For Clean History)

This rewrites history to make it look like you branched from the latest main. **Only use this if you haven't shared your branch with others.**

### Step 1: Backup
```bash
git branch feature/job-history-backup
```

### Step 2: Fetch and Rebase
```bash
git checkout feature/job-history
git fetch origin
git rebase origin/main
```

### Step 3: Resolve Conflicts (Same as Above)
When you hit the conflict, resolve it the same way, then:

```bash
git add pdf_ui/src/pages/LandingPage.jsx
git rebase --continue
```

### Step 4: Force Push
```bash
# Rebase rewrites history, so you need force push
git push fork feature/job-history --force-with-lease
```

**⚠️ Warning**: Only use rebase if:
- You haven't shared this branch with others
- You're comfortable with git history rewriting
- You want a cleaner linear history

---

## Option 3: Create Clean Merge Request Branch (Recommended for PR)

This creates a new branch with ONLY the job history feature, excluding UB branding.

### Step 1: Start from Latest Main
```bash
# Fetch latest
git fetch origin

# Create new branch from upstream main
git checkout -b merge-request/job-history origin/main
```

### Step 2: Cherry-Pick Job History Commits

```bash
# Pick the core job history commits (in order)
git cherry-pick 1057686  # docs: add job history & re-download feature spec
git cherry-pick 2c27c9b  # feat(backend): add job history DynamoDB table, Lambda, and API endpoint
git cherry-pick e25e77b  # feat(ui): add job history tab with tracking and re-download
git cherry-pick 22765bd  # feat(deploy): add REACT_APP_JOB_HISTORY_API to direct deploy script
git cherry-pick 220c78c  # fix(ui): fix page count not showing in job history

# Optional: Pick infrastructure improvements
git cherry-pick 845d6ff  # fix(cdk): make Cognito domain prefix deterministic
git cherry-pick 02bb34e  # feat: Add direct Amplify deployment script (if desired)
```

**If you get conflicts during cherry-pick:**
```bash
# Resolve the conflict
# Edit the conflicting file
git add <file>
git cherry-pick --continue

# Or skip if not relevant
git cherry-pick --skip

# Or abort and try again
git cherry-pick --abort
```

### Step 3: Review What You're Including
```bash
# See all changes
git diff origin/main

# See file list
git diff --name-status origin/main

# Make sure no UB branding is included
git diff origin/main -- pdf_ui/src/pages/LandingPage.jsx
git diff origin/main -- pdf_ui/src/theme.jsx
git diff origin/main -- pdf_ui/src/utilities/constants.jsx
```

### Step 4: Clean Up Unwanted Changes

If you accidentally included UB branding:

```bash
# Reset specific files to upstream version
git checkout origin/main -- pdf_ui/src/pages/LandingPage.jsx
git checkout origin/main -- pdf_ui/src/theme.jsx
git checkout origin/main -- pdf_ui/src/utilities/constants.jsx

# Commit the cleanup
git commit -m "chore: remove UB-specific branding from merge request"
```

### Step 5: Test the Clean Branch
```bash
cd pdf_ui
npm install
npm test
npm run build
```

### Step 6: Push to Your Fork
```bash
git push fork merge-request/job-history
```

### Step 7: Create Pull Request on GitHub
1. Go to https://github.com/ASUCICREPO/PDF_accessability_UI
2. Click "Pull requests" → "New pull request"
3. Click "compare across forks"
4. Set:
   - **base repository**: ASUCICREPO/PDF_accessability_UI
   - **base**: main
   - **head repository**: AWS-fpenland/PDF_accessability_UI
   - **compare**: merge-request/job-history
5. Click "Create pull request"
6. Fill in the title and description (use template from MERGE_REQUEST_REVIEW.md)

---

## Verification Checklist

After syncing, verify:

- [ ] All tests pass (`npm test`)
- [ ] Build succeeds (`npm run build`)
- [ ] No unexpected files changed (`git diff --name-status origin/main`)
- [ ] Job history feature works locally
- [ ] No UB branding in merge request branch (if using Option 3)
- [ ] Commit messages are clear and follow conventions
- [ ] No merge conflicts remain
- [ ] CDK stack can deploy (`cd cdk_backend && npx cdk synth`)

---

## Troubleshooting

### "I messed up the merge, how do I start over?"
```bash
# Abort the merge
git merge --abort

# Or reset to before the merge
git reset --hard feature/job-history-backup

# Or reset to your last good commit
git reset --hard HEAD~1
```

### "I have conflicts in multiple files"
```bash
# See all conflicting files
git diff --name-only --diff-filter=U

# Resolve each one, then:
git add <file>

# When all resolved:
git commit
```

### "Cherry-pick is failing with conflicts"
```bash
# See what's conflicting
git status

# Option 1: Resolve and continue
# Edit the file, then:
git add <file>
git cherry-pick --continue

# Option 2: Skip this commit
git cherry-pick --skip

# Option 3: Abort and try different approach
git cherry-pick --abort
```

### "I want to see what changed in upstream"
```bash
# See all upstream changes
git log --oneline origin/main ^feature/job-history

# See detailed changes in specific file
git diff feature/job-history origin/main -- cdk_backend/lib/cdk_backend-stack.ts

# See all changed files
git diff --name-status feature/job-history origin/main
```

### "How do I know if I'm including UB branding?"
```bash
# Check for UB colors
git diff origin/main | grep -i "005bbb\|00a69c\|002f56"

# Check for UB-specific files
git diff --name-status origin/main | grep -i "ub\|buffalo"

# Check specific branding files
git diff origin/main -- pdf_ui/src/theme.jsx
git diff origin/main -- pdf_ui/src/utilities/constants.jsx
git diff origin/main -- pdf_ui/src/pages/LandingPage.jsx
```

---

## Recommended Workflow

**For your working branch (feature/job-history):**
→ Use **Option 1 (Merge)** to keep all history and UB branding

**For the merge request:**
→ Use **Option 3 (Clean Branch)** to submit only job history feature

**For your UB deployment:**
→ Keep `fpenland/demo/UB` branch separate, merge from main after your PR is accepted

---

## Next Steps After Syncing

1. **Update your feature branch** with Option 1
2. **Create clean MR branch** with Option 3
3. **Test both branches** thoroughly
4. **Submit pull request** from clean branch
5. **Keep UB branch** updated separately

---

## Questions?

- **"Should I merge or rebase?"** → Merge for feature branches, rebase only if you want clean history and haven't shared the branch
- **"What about my UB branding?"** → Keep it in your feature branch, exclude from merge request
- **"How often should I sync?"** → Before submitting PR, and periodically (weekly/monthly) to avoid large conflicts
- **"What if upstream rejects my PR?"** → You still have your feature branch with all changes, can iterate based on feedback

---

**Ready to proceed?** Start with Option 1 to update your feature branch, then use Option 3 to create a clean merge request.
