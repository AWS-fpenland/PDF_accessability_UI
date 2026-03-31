import defaultTheme from './default/theme.json';
import ubTheme from './ub/theme.json';

const themes = {
  default: defaultTheme,
  ub: ubTheme,
};

const activeThemeName = process.env.REACT_APP_THEME || 'default';
const activeTheme = themes[activeThemeName] || themes.default;

export default activeTheme;
