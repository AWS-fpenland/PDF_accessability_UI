# UB Demo Deployment Checklist

## Pre-Deployment Checklist

### 1. Local Testing
- [ ] Run `cd pdf_ui && npm install`
- [ ] Run `npm start` to test locally at http://localhost:3000
- [ ] Verify UB Blue color scheme appears correctly
- [ ] Check all pages (Landing, Main App, Upload, Processing, Results)
- [ ] Test responsive design on mobile/tablet views
- [ ] Verify no console errors in browser DevTools

### 2. Branding Verification
- [ ] UB Blue (#005bbb) appears in headers and primary elements
- [ ] Lake LaSalle (#00a69c) appears in accent elements
- [ ] No ASU maroon/gold colors remain
- [ ] UB logo displays correctly (replace placeholder if needed)
- [ ] All text references University at Buffalo (not ASU)

### 3. Content Review
- [ ] Landing page text is UB-appropriate
- [ ] Support contact information is correct
- [ ] Links point to appropriate resources
- [ ] Terms and conditions are reviewed
- [ ] Privacy policy is appropriate for UB

### 4. Backend Configuration
- [ ] Backend PDF processing is deployed
- [ ] S3 bucket names are configured
- [ ] Cognito user pool is set up
- [ ] API Gateway endpoints are configured
- [ ] Environment variables are set correctly

## Deployment Steps

### Option 1: Full Deployment (Backend + Frontend)

```bash
cd PDF_accessability_UI
./deploy.sh
```

Follow the prompts to enter:
- PDF-to-PDF bucket name
- PDF-to-HTML bucket name
- AWS region

### Option 2: Frontend Only Deployment

```bash
cd PDF_accessability_UI
./deploy-frontend.sh
```

Use this if backend is already deployed and you only need to update the UI.

## Post-Deployment Verification

### 1. Functional Testing
- [ ] Navigate to the Amplify URL provided after deployment
- [ ] Test user registration flow
- [ ] Test user login
- [ ] Upload a test PDF (PDF-to-PDF)
- [ ] Upload a test PDF (PDF-to-HTML)
- [ ] Verify processing completes successfully
- [ ] Download and verify remediated files
- [ ] Test quota limits
- [ ] Test error handling

### 2. Visual Verification
- [ ] UB branding displays correctly on live site
- [ ] Colors match UB brand guidelines
- [ ] Logo is clear and properly sized
- [ ] Responsive design works on mobile
- [ ] All images load correctly

### 3. Performance Testing
- [ ] Page load times are acceptable
- [ ] File upload works smoothly
- [ ] Processing status updates in real-time
- [ ] Download links work correctly

### 4. Accessibility Testing
- [ ] Run WAVE browser extension
- [ ] Verify color contrast ratios
- [ ] Test keyboard navigation
- [ ] Test with screen reader
- [ ] Check ARIA labels

## Rollback Plan

If issues are discovered:

1. **Frontend Issues:**
   ```bash
   git checkout main
   ./deploy-frontend.sh
   ```

2. **Full Stack Issues:**
   - Use AWS Console to roll back CloudFormation stacks
   - Or redeploy from main branch

## Monitoring

### CloudWatch Logs
- `/aws/lambda/PostConfirmationLambda` - User registration
- `/aws/lambda/checkOrIncrementQuotaFn` - Quota management
- API Gateway logs - API requests

### Amplify Console
- Build logs
- Deployment status
- Custom domain configuration

## Demo Preparation

### Before Showing to UB Stakeholders

1. **Create Test Accounts:**
   - Create 2-3 test user accounts
   - Verify different quota levels work
   - Test group assignments

2. **Prepare Test Documents:**
   - Have 3-5 sample PDFs ready
   - Include various page counts (1, 5, 10 pages)
   - Include different complexity levels
   - Have before/after examples ready

3. **Demo Script:**
   - Landing page overview (30 seconds)
   - User registration (1 minute)
   - PDF upload and processing (2 minutes)
   - Results and download (1 minute)
   - Admin features (1 minute)

4. **Talking Points:**
   - WCAG 2.1 Level AA compliance
   - Cost savings vs manual remediation
   - Processing speed
   - Scalability
   - AWS security and reliability

## Troubleshooting

### Common Issues

**Issue: Colors not updating**
- Clear browser cache
- Hard refresh (Ctrl+Shift+R)
- Check if correct branch is deployed

**Issue: Logo not displaying**
- Verify ub-logo.svg exists in assets
- Check file path in components
- Verify build includes assets folder

**Issue: Environment variables not set**
- Check Amplify environment variables in AWS Console
- Redeploy after updating variables
- Verify .env files are not committed to git

**Issue: Backend connection fails**
- Verify backend is deployed
- Check S3 bucket names in environment
- Verify Cognito configuration
- Check API Gateway endpoints

## Support Contacts

- **Technical Issues**: fpenland@buffalo.edu
- **UB Branding**: UB Marketing Communications
- **AWS Support**: Your AWS account team
- **Original Solution**: ai-cic@amazon.com

## Next Steps After Successful Deployment

1. Gather feedback from UB stakeholders
2. Make any requested adjustments
3. Consider official UB logo integration
4. Plan for production deployment if approved
5. Document any UB-specific customizations
6. Set up monitoring and alerting
7. Create user documentation for UB users
