# Customer Theming

Switch branding by setting `REACT_APP_THEME` at build time.

## Usage

```bash
# Default branding
REACT_APP_THEME=default npm run build

# University at Buffalo demo
REACT_APP_THEME=ub npm run build
```

If `REACT_APP_THEME` is unset, `default` is used.

## Adding a New Customer Theme

1. Copy an existing theme folder:
   ```bash
   cp -r pdf_ui/src/themes/default pdf_ui/src/themes/mycustomer
   ```

2. Edit `pdf_ui/src/themes/mycustomer/theme.json` — update colors, hero text, and meta.

3. Drop logo files into `pdf_ui/src/themes/mycustomer/assets/`.

4. Register the theme in `pdf_ui/src/themes/index.js`:
   ```js
   import mycustomerTheme from './mycustomer/theme.json';

   const themes = {
     default: defaultTheme,
     ub: ubTheme,
     mycustomer: mycustomerTheme,
   };
   ```

5. Build with `REACT_APP_THEME=mycustomer`.

## What's Themed

| Property | Source |
|---|---|
| Colors (primary, secondary, header, nav) | `theme.json` → `constants.jsx` → MUI theme |
| Hero title, description, fonts | `theme.json` → `HeroSection.jsx` |
| Meta tags (theme-color, description) | `theme.json` (manual for now) |
| Logos | `themes/<name>/assets/` |
