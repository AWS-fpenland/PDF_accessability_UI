# Local Testing Guide

## Prerequisites

- Node.js (v16 or higher)
- npm (v8 or higher)

## Setup for Local Development

1. **Navigate to the React app directory:**
   ```bash
   cd PDF_accessability_UI/pdf_ui
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Create a local environment file (optional):**
   
   Create `.env.local` in the `pdf_ui` directory if you want to test with specific backend configurations:
   
   ```bash
   # Example .env.local
   REACT_APP_AUTHORITY=your-cognito-domain
   REACT_APP_AWS_REGION=us-east-1
   REACT_APP_PDF_BUCKET_NAME=your-pdf-bucket
   REACT_APP_HTML_BUCKET_NAME=your-html-bucket
   # ... other environment variables
   ```

4. **Start the development server:**
   ```bash
   npm start
   ```

   The application will automatically open in your browser at `http://localhost:3000`

## What You'll See

- **UB Blue color scheme** throughout the interface
- **University at Buffalo branding** in headers and text
- **Lake LaSalle accent colors** for interactive elements
- **Roboto font family** for clean, professional typography

## Hot Reload

The development server supports hot reload - any changes you make to the source files will automatically refresh in the browser.

## Testing UI Changes

### Color Changes
- Edit `pdf_ui/src/utilities/constants.jsx` to modify color values
- Changes will reflect immediately in the browser

### Component Changes
- Edit files in `pdf_ui/src/components/` to modify UI elements
- Save the file and see changes instantly

### Theme Changes
- Edit `pdf_ui/src/theme.jsx` to modify Material-UI theme settings

## Building for Production

To create a production build:

```bash
npm run build
```

This creates an optimized build in the `build/` directory.

## Common Issues

### Port Already in Use
If port 3000 is already in use:
```bash
# On Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# On Linux/Mac
lsof -ti:3000 | xargs kill -9
```

### Module Not Found
If you see module errors:
```bash
rm -rf node_modules package-lock.json
npm install
```

### Environment Variables Not Loading
- Ensure `.env.local` is in the `pdf_ui` directory (not the root)
- Restart the development server after changing environment variables
- Environment variables must start with `REACT_APP_`

## Deployment

Once you're satisfied with local testing, deploy using:

```bash
cd ..  # Back to PDF_accessability_UI root
./deploy-frontend.sh  # Frontend only
# OR
./deploy.sh  # Full deployment
```

## Tips

- Use browser DevTools to inspect elements and test responsive design
- Test on different screen sizes using browser responsive mode
- Check console for any warnings or errors
- Verify color contrast meets WCAG AA standards using browser extensions
