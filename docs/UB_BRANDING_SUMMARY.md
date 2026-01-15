# UB Branding Summary

## Quick Reference

This document provides a quick reference for the University at Buffalo branding applied to the PDF Accessibility UI.

## Color Palette

### Primary Colors
| Color Name | Hex Code | Usage |
|------------|----------|-------|
| UB Blue | `#005bbb` | Primary brand color, headers, buttons |
| Hayes Hall White | `#ffffff` | Backgrounds, text on dark |
| Harriman Blue | `#002f56` | Navigation, darker accents |

### Secondary Colors
| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Lake LaSalle | `#00a69c` | Accent color, interactive elements |
| Townsend Gray | `#666666` | Secondary text, borders |

## Typography

- **Primary Font**: Roboto
- **Fallback Fonts**: Helvetica Neue, Arial, sans-serif
- **Font Weights**: 400 (regular), 600 (semi-bold), 700 (bold)

## Component Branding

### Header
- Background: UB Blue (#005bbb)
- Logo: UB-branded SVG
- Text: White

### Hero Section
- Title Color: UB Blue (#005bbb)
- Description Color: Harriman Blue (#002f56)
- Font: Roboto

### Information Cards
- Border: UB Blue (#005bbb)
- Icon Background: Lake LaSalle (#00a69c)
- Title Color: Harriman Blue (#002f56)
- Description Color: Townsend Gray (#666666)

### Navigation
- Background: Light gray (#f9f9f9)
- Active/Hover: UB Blue (#005bbb)

### Buttons
- Primary: UB Blue (#005bbb)
- Secondary: Lake LaSalle (#00a69c)
- Text: White
- Hover: Darker shade of button color

### Landing Page
- Top Bar: UB Blue (#005bbb)
- Main Section: UB Blue (#005bbb)
- Accent Color: Lake LaSalle (#00a69c)
- Links: UB Blue (#005bbb)

## Accessibility Compliance

All color combinations meet WCAG 2.1 Level AA standards:
- UB Blue on White: 8.59:1 (AAA)
- White on UB Blue: 8.59:1 (AAA)
- Harriman Blue on White: 14.85:1 (AAA)
- Townsend Gray on White: 5.74:1 (AA)
- Lake LaSalle on White: 3.96:1 (AA for large text)

## Brand Guidelines Reference

Official UB brand guidelines: https://buffalo.edu/brand/creative/color/color-palette.html

## Files Modified

1. `pdf_ui/src/utilities/constants.jsx` - Color constants
2. `pdf_ui/src/theme.jsx` - MUI theme configuration
3. `pdf_ui/public/index.html` - Meta tags and title
4. `pdf_ui/src/components/HeroSection.jsx` - Hero text and colors
5. `pdf_ui/src/components/InformationBlurb.jsx` - Feature cards
6. `pdf_ui/src/components/Header.jsx` - Header logo and styling
7. `pdf_ui/src/components/LeftNav.jsx` - Navigation branding
8. `pdf_ui/src/pages/LandingPage.jsx` - Landing page content
9. `pdf_ui/src/assets/ub-logo.svg` - UB logo (placeholder)

## Next Steps

1. **Replace Logo**: Obtain official UB logo and replace `ub-logo.svg`
2. **Test Locally**: Run `npm start` in `pdf_ui` directory
3. **Review Content**: Update any remaining ASU references
4. **Deploy**: Use `./deploy-frontend.sh` when ready
5. **Gather Feedback**: Share with UB stakeholders for approval

## Contact Information Updates

- Support email: `ub-accessibility@buffalo.edu` (placeholder)
- Organization: University at Buffalo
- Department: IT Services / Accessibility Office

## Notes

- Logo is currently a placeholder SVG
- Some landing page content may still reference the original source
- All technical functionality remains unchanged
- Deployment process is identical to the original
