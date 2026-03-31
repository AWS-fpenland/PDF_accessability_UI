import React from 'react';
import activeTheme from '../themes';

const HeroSection = () => {
  const { hero } = activeTheme;

  const heroSectionStyle = {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    padding: '80px 20px 20px 20px',
    textAlign: 'center'
  };

  const heroContentStyle = {
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
    alignItems: 'center',
    maxWidth: '480px'
  };

  const heroTitleStyle = {
    fontFamily: hero.fontFamily,
    fontWeight: '600',
    fontSize: '28px',
    lineHeight: '36px',
    color: hero.titleColor,
    margin: '0',
    whiteSpace: 'nowrap'
  };

  const heroDescriptionStyle = {
    fontFamily: hero.fontFamily,
    fontWeight: '400',
    fontSize: '20px',
    lineHeight: '30px',
    color: hero.descriptionColor,
    margin: '0',
    maxWidth: '480px',
    width: '100%'
  };

  return (
    <div style={heroSectionStyle}>
      <div style={heroContentStyle}>
        <h1 style={heroTitleStyle}>{hero.title}</h1>
        <p style={heroDescriptionStyle}>{hero.description}</p>
      </div>
    </div>
  );
};

export default HeroSection;
