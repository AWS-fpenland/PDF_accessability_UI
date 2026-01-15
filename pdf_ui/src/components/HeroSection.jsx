import React from 'react';

const HeroSection = () => {
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
    fontFamily: "'Roboto', 'Helvetica Neue', Arial, sans-serif",
    fontWeight: '600',
    fontSize: '28px',
    lineHeight: '36px',
    color: '#005bbb',
    margin: '0',
    whiteSpace: 'nowrap'
  };

  const heroDescriptionStyle = {
    fontFamily: "'Roboto', 'Helvetica Neue', Arial, sans-serif",
    fontWeight: '400',
    fontSize: '20px',
    lineHeight: '30px',
    color: '#002f56',
    margin: '0',
    maxWidth: '480px',
    width: '100%'
  };

  return (
    <div style={heroSectionStyle}>
      <div style={heroContentStyle}>
        <h1 style={heroTitleStyle}>PDF Accessibility Solution</h1>
        <p style={heroDescriptionStyle}>
          University at Buffalo's AI-powered solution designed to
          improve digital accessibility and WCAG compliance for everyone.
        </p>
      </div>
    </div>
  );
};

export default HeroSection;
