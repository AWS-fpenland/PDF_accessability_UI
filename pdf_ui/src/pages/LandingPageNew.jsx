import React, { useState, useEffect } from 'react';
import { useAuth } from 'react-oidc-context';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Button,
  Container,
  Grid,
  Card,
  CardContent,
  Stack,
  Chip,
  useTheme,
  useMediaQuery,
} from '@mui/material';
import {
  CheckCircleOutline,
  Speed,
  Security,
  CloudUpload,
  AutoFixHigh,
  Assessment,
  ArrowForward,
  PlayArrow,
} from '@mui/icons-material';
import { motion } from 'framer-motion';

const MotionBox = motion(Box);
const MotionCard = motion(Card);

const LandingPageNew = () => {
  const auth = useAuth();
  const navigate = useNavigate();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (auth.isLoading) return;
    if (auth.isAuthenticated) {
      navigate('/app', { replace: true });
    }
  }, [auth.isLoading, auth.isAuthenticated, navigate]);

  const handleGetStarted = () => {
    setIsLoading(true);
    setTimeout(() => {
      auth.signinRedirect();
    }, 500);
  };

  const features = [
    {
      icon: <Speed sx={{ fontSize: 40 }} />,
      title: 'Lightning Fast',
      description: 'Process PDFs in minutes, not hours. Automated remediation saves time and resources.',
    },
    {
      icon: <CheckCircleOutline sx={{ fontSize: 40 }} />,
      title: 'WCAG 2.1 AA Compliant',
      description: 'Meet accessibility standards with confidence. Full compliance with federal requirements.',
    },
    {
      icon: <AutoFixHigh sx={{ fontSize: 40 }} />,
      title: 'AI-Powered',
      description: 'Advanced AI generates alt text, fixes structure, and ensures proper tagging automatically.',
    },
    {
      icon: <Security sx={{ fontSize: 40 }} />,
      title: 'Secure & Private',
      description: 'Your documents stay secure with enterprise-grade AWS infrastructure and encryption.',
    },
    {
      icon: <Assessment sx={{ fontSize: 40 }} />,
      title: 'Detailed Reports',
      description: 'Get comprehensive accessibility reports before and after remediation for full transparency.',
    },
    {
      icon: <CloudUpload sx={{ fontSize: 40 }} />,
      title: 'Easy Upload',
      description: 'Simple drag-and-drop interface. Upload, process, and download in just a few clicks.',
    },
  ];

  const steps = [
    {
      number: '01',
      title: 'Upload Your PDF',
      description: 'Drag and drop or select your PDF document. We support files up to 25MB and 10 pages.',
    },
    {
      number: '02',
      title: 'AI Processing',
      description: 'Our AI analyzes and remediates your document, adding tags, alt text, and fixing structure.',
    },
    {
      number: '03',
      title: 'Download Results',
      description: 'Get your accessible PDF plus detailed reports showing all improvements made.',
    },
  ];

  if (auth.isLoading) {
    return (
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '100vh' }}>
        <Typography>Loading...</Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ backgroundColor: '#fff', minHeight: '100vh' }}>
      {/* Navigation Bar */}
      <Box
        sx={{
          backgroundColor: '#005bbb',
          color: '#fff',
          py: 2,
          position: 'sticky',
          top: 0,
          zIndex: 1000,
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
        }}
      >
        <Container maxWidth="lg">
          <Stack direction="row" justifyContent="space-between" alignItems="center">
            <Stack direction="row" alignItems="center" spacing={2}>
              <Box
                component="img"
                src="/ub-logo-two-line.png"
                alt="University at Buffalo Libraries"
                sx={{
                  height: { xs: 40, sm: 50 },
                  width: 'auto',
                }}
              />
              <Chip label="PDF Accessibility" size="small" sx={{ backgroundColor: '#00a69c', color: '#fff' }} />
            </Stack>
            <Button
              variant="contained"
              onClick={handleGetStarted}
              disabled={isLoading}
              sx={{
                backgroundColor: '#fff',
                color: '#005bbb',
                '&:hover': { backgroundColor: '#f0f0f0' },
                fontWeight: 600,
              }}
            >
              Sign In
            </Button>
          </Stack>
        </Container>
      </Box>

      {/* Hero Section */}
      <Box
        sx={{
          background: 'linear-gradient(135deg, #005bbb 0%, #002f56 100%)',
          color: '#fff',
          py: { xs: 8, md: 12 },
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        <Container maxWidth="lg">
          <Grid container spacing={4} alignItems="center">
            <Grid item xs={12} md={6}>
              <MotionBox
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6 }}
              >
                <Chip
                  label="Powered by AWS & AI"
                  sx={{ backgroundColor: 'rgba(255,255,255,0.2)', color: '#fff', mb: 2 }}
                />
                <Typography variant="h2" fontWeight="800" gutterBottom sx={{ fontSize: { xs: '2rem', md: '3rem' } }}>
                  Make Your PDFs Accessible
                </Typography>
                <Typography variant="h5" sx={{ mb: 4, opacity: 0.95, fontWeight: 400 }}>
                  Automated PDF remediation for University at Buffalo Libraries. WCAG 2.1 AA compliant in minutes.
                </Typography>
                <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
                  <Button
                    variant="contained"
                    size="large"
                    endIcon={<ArrowForward />}
                    onClick={handleGetStarted}
                    disabled={isLoading}
                    sx={{
                      backgroundColor: '#00a69c',
                      color: '#fff',
                      py: 1.5,
                      px: 4,
                      fontSize: '1.1rem',
                      '&:hover': { backgroundColor: '#008c84' },
                    }}
                  >
                    Get Started Free
                  </Button>
                  <Button
                    variant="outlined"
                    size="large"
                    startIcon={<PlayArrow />}
                    sx={{
                      borderColor: '#fff',
                      color: '#fff',
                      py: 1.5,
                      px: 4,
                      '&:hover': { borderColor: '#fff', backgroundColor: 'rgba(255,255,255,0.1)' },
                    }}
                  >
                    Watch Demo
                  </Button>
                </Stack>
              </MotionBox>
            </Grid>
            <Grid item xs={12} md={6}>
              <MotionBox
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.6, delay: 0.2 }}
                sx={{
                  backgroundColor: 'rgba(255,255,255,0.1)',
                  borderRadius: 4,
                  p: 4,
                  backdropFilter: 'blur(10px)',
                }}
              >
                <Typography variant="h6" gutterBottom fontWeight="600">
                  ✓ WCAG 2.1 Level AA Compliant
                </Typography>
                <Typography variant="h6" gutterBottom fontWeight="600">
                  ✓ AI-Powered Alt Text Generation
                </Typography>
                <Typography variant="h6" gutterBottom fontWeight="600">
                  ✓ Automated Structure Tagging
                </Typography>
                <Typography variant="h6" gutterBottom fontWeight="600">
                  ✓ Detailed Accessibility Reports
                </Typography>
                <Typography variant="h6" fontWeight="600">
                  ✓ Secure Cloud Processing
                </Typography>
              </MotionBox>
            </Grid>
          </Grid>
        </Container>
      </Box>

      {/* Features Section */}
      <Container maxWidth="lg" sx={{ py: { xs: 8, md: 12 } }}>
        <Box textAlign="center" mb={6}>
          <Typography variant="h3" fontWeight="700" gutterBottom color="#002f56">
            Why Choose Our Solution?
          </Typography>
          <Typography variant="h6" color="text.secondary" maxWidth="800px" mx="auto">
            Built specifically for academic institutions, our platform combines cutting-edge AI with proven accessibility standards.
          </Typography>
        </Box>

        <Grid container spacing={4}>
          {features.map((feature, index) => (
            <Grid item xs={12} sm={6} md={4} key={index}>
              <MotionCard
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                sx={{
                  height: '100%',
                  borderRadius: 3,
                  boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
                  transition: 'transform 0.3s, box-shadow 0.3s',
                  '&:hover': {
                    transform: 'translateY(-8px)',
                    boxShadow: '0 8px 30px rgba(0,91,187,0.15)',
                  },
                }}
              >
                <CardContent sx={{ p: 4 }}>
                  <Box
                    sx={{
                      width: 70,
                      height: 70,
                      borderRadius: 2,
                      backgroundColor: '#e6f0ff',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      mb: 2,
                      color: '#005bbb',
                    }}
                  >
                    {feature.icon}
                  </Box>
                  <Typography variant="h6" fontWeight="700" gutterBottom color="#002f56">
                    {feature.title}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {feature.description}
                  </Typography>
                </CardContent>
              </MotionCard>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* How It Works Section */}
      <Box sx={{ backgroundColor: '#f8f9fa', py: { xs: 8, md: 12 } }}>
        <Container maxWidth="lg">
          <Box textAlign="center" mb={6}>
            <Typography variant="h3" fontWeight="700" gutterBottom color="#002f56">
              How It Works
            </Typography>
            <Typography variant="h6" color="text.secondary">
              Three simple steps to accessible PDFs
            </Typography>
          </Box>

          <Grid container spacing={4}>
            {steps.map((step, index) => (
              <Grid item xs={12} md={4} key={index}>
                <MotionBox
                  initial={{ opacity: 0, x: -20 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: index * 0.2 }}
                  textAlign="center"
                >
                  <Typography
                    variant="h2"
                    fontWeight="800"
                    sx={{ color: '#00a69c', opacity: 0.3, mb: 2 }}
                  >
                    {step.number}
                  </Typography>
                  <Typography variant="h5" fontWeight="700" gutterBottom color="#002f56">
                    {step.title}
                  </Typography>
                  <Typography variant="body1" color="text.secondary">
                    {step.description}
                  </Typography>
                </MotionBox>
              </Grid>
            ))}
          </Grid>
        </Container>
      </Box>

      {/* CTA Section */}
      <Box
        sx={{
          background: 'linear-gradient(135deg, #00a69c 0%, #006570 100%)',
          color: '#fff',
          py: { xs: 8, md: 10 },
        }}
      >
        <Container maxWidth="md">
          <Box textAlign="center">
            <Typography variant="h3" fontWeight="700" gutterBottom>
              Ready to Get Started?
            </Typography>
            <Typography variant="h6" sx={{ mb: 4, opacity: 0.95 }}>
              Join University at Buffalo Libraries in making digital content accessible to everyone.
            </Typography>
            <Button
              variant="contained"
              size="large"
              endIcon={<ArrowForward />}
              onClick={handleGetStarted}
              disabled={isLoading}
              sx={{
                backgroundColor: '#fff',
                color: '#00a69c',
                py: 2,
                px: 5,
                fontSize: '1.1rem',
                fontWeight: 600,
                '&:hover': { backgroundColor: '#f0f0f0' },
              }}
            >
              Start Remediating PDFs
            </Button>
          </Box>
        </Container>
      </Box>

      {/* Footer */}
      <Box sx={{ backgroundColor: '#002f56', color: '#fff', py: 6 }}>
        <Container maxWidth="lg">
          <Grid container spacing={4}>
            <Grid item xs={12} md={6}>
              <Box
                component="img"
                src="/ub-logo-two-line.png"
                alt="University at Buffalo Libraries"
                sx={{
                  height: 60,
                  width: 'auto',
                  mb: 2,
                  filter: 'brightness(0) invert(1)', // Makes logo white
                }}
              />
              <Typography variant="body2" sx={{ opacity: 0.8 }}>
                Powered by AWS and built for academic excellence. Making digital content accessible to all.
              </Typography>
            </Grid>
            <Grid item xs={12} md={6}>
              <Typography variant="h6" fontWeight="700" gutterBottom>
                Support
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.8 }}>
                Questions? Contact UB Libraries IT Services
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.8 }}>
                Email: library-accessibility@buffalo.edu
              </Typography>
            </Grid>
          </Grid>
          <Box sx={{ borderTop: '1px solid rgba(255,255,255,0.1)', mt: 4, pt: 4, textAlign: 'center' }}>
            <Typography variant="body2" sx={{ opacity: 0.6 }}>
              © 2025 University at Buffalo Libraries. All rights reserved.
            </Typography>
          </Box>
        </Container>
      </Box>
    </Box>
  );
};

export default LandingPageNew;
