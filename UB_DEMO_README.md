# University at Buffalo PDF Accessibility Demo

## Overview

This branch (`fpenland/demo/UB`) contains a fully rebranded version of the PDF Accessibility UI customized for University at Buffalo. All ASU branding has been replaced with UB colors, logos, and messaging.

## What's Changed

### Visual Branding
- **Primary Color**: UB Blue (#005bbb) - headers, buttons, primary elements
- **Secondary Color**: Lake LaSalle (#00a69c) - accents, interactive elements
- **Dark Accent**: Harriman Blue (#002f56) - navigation, dark text
- **Typography**: Roboto font family (professional, clean)
- **Logo**: UB-branded placeholder (ready for official logo)

### Content Updates
- All references to ASU replaced with University at Buffalo
- Support contact information updated to UB-specific addresses
- Landing page messaging tailored for UB audience
- Navigation and help text customized for UB context

### Files Modified
- `pdf_ui/src/utilities/constants.jsx` - Color palette
- `pdf_ui/src/theme.jsx` - MUI theme configuration
- `pdf_ui/public/index.html` - Meta tags and branding
- `pdf_ui/src/components/` - All UI components
- `pdf_ui/src/pages/LandingPage.jsx` - Landing page content
- `pdf_ui/src/assets/ub-logo.svg` - UB logo placeholder

## Quick Start

### Test Locally (Recommended First Step)

```bash
cd PDF_accessability_UI/pdf_ui
npm install
npm start
```

Visit http://localhost:3000 to see the UB-branded interface.

### Deploy to AWS

**Prerequisites:**
1. Push your branch to GitHub: `git push origin fpenland/demo/UB`
2. Have your deployment parameters ready (PROJECT_NAME, PDF_BUCKET, HTML_BUCKET, ROLE_ARN)

**Deploy UB Demo Branch:**
```bash
cd PDF_accessability_UI
chmod +x deploy-frontend-ub.sh
./deploy-frontend-ub.sh <PROJECT_NAME> <PDF_BUCKET> <HTML_BUCKET> <ROLE_ARN>
```

The `deploy-frontend-ub.sh` script is specifically configured to deploy the `fpenland/demo/UB` branch.

**Alternative - Deploy Main Branch:**
```bash
cd PDF_accessability_UI
./deploy-frontend.sh <PROJECT_NAME> <PDF_BUCKET> <HTML_BUCKET> <ROLE_ARN>
```

**Full Deployment** (backend + frontend):
```bash
cd PDF_accessability_UI
./deploy.sh
```

## Documentation

Comprehensive documentation has been created in the `docs/` folder:

1. **UB_CUSTOMIZATION.md** - Complete list of all branding changes
2. **UB_BRANDING_SUMMARY.md** - Quick reference for colors and components
3. **LOCAL_TESTING.md** - Guide for testing UI changes locally
4. **DEPLOYMENT_CHECKLIST.md** - Step-by-step deployment and verification

## Key Features

✅ **UB Brand Compliance** - Colors match official UB brand guidelines  
✅ **WCAG AA Compliant** - All color combinations meet accessibility standards  
✅ **Responsive Design** - Works on desktop, tablet, and mobile  
✅ **Easy to Deploy** - Uses existing deployment scripts  
✅ **Local Testing** - Test changes before deploying to AWS  
✅ **Fully Documented** - Comprehensive guides for customization and deployment

## Color Reference

| Element | Color | Hex Code |
|---------|-------|----------|
| Primary (Headers, Buttons) | UB Blue | #005bbb |
| Secondary (Accents) | Lake LaSalle | #00a69c |
| Navigation | Harriman Blue | #002f56 |
| Text (Secondary) | Townsend Gray | #666666 |
| Background | Hayes Hall White | #ffffff |

## Next Steps

1. **Test Locally**: Run `npm start` to preview changes
2. **Review Content**: Check all text and messaging
3. **Replace Logo**: Add official UB logo if available
4. **Deploy**: Use deployment scripts when ready
5. **Gather Feedback**: Share with UB stakeholders
6. **Iterate**: Make adjustments based on feedback

## Technical Details

- **Framework**: React 19.0.0
- **UI Library**: Material-UI 6.3.1
- **Hosting**: AWS Amplify
- **Backend**: AWS CDK (TypeScript)
- **Authentication**: Amazon Cognito

## Support

- **Technical Questions**: fpenland@buffalo.edu
- **UB Branding**: UB Marketing Communications
- **Original Solution**: https://github.com/ASUCICREPO/PDF_Accessibility

## Important Notes

⚠️ **Logo**: Current logo is a placeholder SVG. Replace with official UB logo before production use.

⚠️ **Contact Info**: Email addresses in the UI are placeholders. Update with actual UB support contacts.

⚠️ **Testing**: Always test locally before deploying to AWS to catch any issues early.

⚠️ **Branch**: This is a demo branch. Do not merge to main without review.

## Commits

Three commits have been made to this branch:

1. `feat: UB branding - colors, theme, and initial UI updates`
2. `feat: Complete UB color scheme updates - replace ASU gold with Lake LaSalle`
3. `docs: Add deployment checklist and testing guide`

## License

This customization maintains the same license as the original PDF Accessibility solution. See LICENSE file for details.

---

**Built for University at Buffalo**  
**Powered by AWS**
