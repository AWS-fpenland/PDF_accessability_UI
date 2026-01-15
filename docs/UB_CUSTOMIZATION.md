# University at Buffalo Customization Guide

## Overview
This document tracks the customizations made to rebrand the PDF Accessibility UI for University at Buffalo.

## Branch
- **Branch Name**: `fpenland/demo/UB`
- **Purpose**: UB-specific demo deployment

## Branding Changes

### Color Scheme
Based on UB Brand Guidelines (https://buffalo.edu/brand/creative/color/color-palette.html):

**Primary Colors:**
- UB Blue: `#005bbb` (PMS 2935) - Primary brand color
- Hayes Hall White: `#ffffff` - Primary background
- Harriman Blue: `#002f56` - Darker UB blue for navigation

**Secondary Colors:**
- Lake LaSalle: `#00a69c` - Accent color (replaces ASU gold)
- Townsend Gray: `#666666` - Secondary text

### Files Modified

1. **`pdf_ui/src/utilities/constants.jsx`**
   - Updated PRIMARY_MAIN to UB Blue (#005bbb)
   - Updated SECONDARY_MAIN to Lake LaSalle (#00a69c)
   - Updated CHAT_LEFT_PANEL_BACKGROUND to Harriman Blue (#002f56)
   - Updated HEADER_BACKGROUND to UB Blue (#005bbb)

2. **`pdf_ui/src/theme.jsx`**
   - Changed font family from Lato to Roboto (more standard, professional)

3. **`pdf_ui/public/index.html`**
   - Updated theme-color meta tag to UB Blue
   - Updated description to reference University at Buffalo

4. **`pdf_ui/src/components/HeroSection.jsx`**
   - Updated title to "PDF Accessibility Solution"
   - Updated description to reference UB
   - Changed colors to UB Blue and Harriman Blue

5. **`pdf_ui/src/components/InformationBlurb.jsx`**
   - Changed border color to UB Blue
   - Changed icon background to Lake LaSalle
   - Updated text colors to UB palette

6. **`pdf_ui/src/components/Header.jsx`**
   - Updated logo import to use ub-logo.svg

7. **`pdf_ui/src/components/LeftNav.jsx`**
   - Updated header text to "UB PDF Accessibility"
   - Changed support contact information to UB-specific

8. **`pdf_ui/src/pages/LandingPage.jsx`**
   - Updated link colors to UB Blue
   - Changed top bar to UB Blue
   - Updated branding text to reference UB
   - Changed logo references

9. **`pdf_ui/src/assets/ub-logo.svg`**
   - Created new UB-branded logo placeholder

## Typography
- Primary Font: Roboto, Helvetica Neue, Arial, sans-serif
- Maintains accessibility and readability standards

## Testing Locally

To test the UI changes locally before deploying:

```bash
cd PDF_accessability_UI/pdf_ui
npm install
npm start
```

The application will run on `http://localhost:3000`

## Deployment

The existing deployment scripts work without modification:

```bash
# Full deployment (backend + frontend)
cd PDF_accessability_UI
./deploy.sh

# Frontend only
./deploy-frontend.sh
```

## Notes

- All changes maintain WCAG 2.1 Level AA compliance
- Color contrast ratios meet accessibility standards
- UB brand guidelines followed for proper color usage
- Logo is a placeholder - replace with official UB assets if available
- Contact information updated to UB-specific addresses

## Future Enhancements

1. Replace placeholder logo with official UB logo (requires permission)
2. Add UB-specific footer with university links
3. Integrate with UB single sign-on if needed
4. Customize quota limits for UB users
5. Add UB-specific analytics tracking

## Contact

For questions about this customization:
- Technical: fpenland@buffalo.edu
- UB Branding: UB Marketing Communications
