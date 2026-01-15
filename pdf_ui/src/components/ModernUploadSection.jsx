import React, { useState, useCallback } from 'react';
import {
  Box,
  Typography,
  Button,
  Card,
  CardContent,
  Stack,
  LinearProgress,
  Chip,
  Alert,
  ToggleButtonGroup,
  ToggleButton,
  Paper,
} from '@mui/material';
import {
  CloudUpload,
  Description,
  CheckCircle,
  PictureAsPdf,
  Code,
} from '@mui/icons-material';
import { useDropzone } from 'react-dropzone';
import { motion } from 'framer-motion';

const MotionBox = motion(Box);
const MotionCard = motion(Card);

const ModernUploadSection = ({
  onUploadComplete,
  awsCredentials,
  currentUsage,
  maxFilesAllowed,
  maxPagesAllowed,
  maxSizeAllowedMB,
  onUsageRefresh,
  setUsageCount,
  isFileUploaded,
  onShowDeploymentPopup,
}) => {
  const [selectedFormat, setSelectedFormat] = useState('pdf');
  const [uploadProgress, setUploadProgress] = useState(0);
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState('');
  const [selectedFile, setSelectedFile] = useState(null);

  const onDrop = useCallback((acceptedFiles) => {
    if (acceptedFiles.length > 0) {
      const file = acceptedFiles[0];
      
      // Validate file
      if (file.type !== 'application/pdf') {
        setError('Please upload a PDF file');
        return;
      }

      if (file.size > maxSizeAllowedMB * 1024 * 1024) {
        setError(`File size exceeds ${maxSizeAllowedMB}MB limit`);
        return;
      }

      setSelectedFile(file);
      setError('');
    }
  }, [maxSizeAllowedMB]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: { 'application/pdf': ['.pdf'] },
    multiple: false,
    disabled: isUploading || currentUsage >= maxFilesAllowed,
  });

  const handleUpload = async () => {
    if (!selectedFile) return;

    setIsUploading(true);
    setUploadProgress(0);

    // Simulate upload progress
    const interval = setInterval(() => {
      setUploadProgress((prev) => {
        if (prev >= 90) {
          clearInterval(interval);
          return 90;
        }
        return prev + 10;
      });
    }, 200);

    try {
      // Your actual upload logic here
      // For now, simulating completion
      setTimeout(() => {
        clearInterval(interval);
        setUploadProgress(100);
        onUploadComplete(selectedFile.name, selectedFile.name, selectedFormat);
        setIsUploading(false);
        setSelectedFile(null);
      }, 2000);
    } catch (err) {
      setError(err.message);
      setIsUploading(false);
      clearInterval(interval);
    }
  };

  const usagePercentage = (currentUsage / maxFilesAllowed) * 100;

  return (
    <Box sx={{ maxWidth: 900, mx: 'auto', py: 4 }}>
      {/* Usage Stats */}
      <MotionCard
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        sx={{
          mb: 4,
          background: 'linear-gradient(135deg, #005bbb 0%, #002f56 100%)',
          color: '#fff',
        }}
      >
        <CardContent>
          <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
            <Typography variant="h6" fontWeight="600">
              Your Usage
            </Typography>
            <Chip
              label={`${currentUsage} / ${maxFilesAllowed} files`}
              sx={{ backgroundColor: 'rgba(255,255,255,0.2)', color: '#fff', fontWeight: 600 }}
            />
          </Stack>
          <LinearProgress
            variant="determinate"
            value={usagePercentage}
            sx={{
              height: 8,
              borderRadius: 4,
              backgroundColor: 'rgba(255,255,255,0.2)',
              '& .MuiLinearProgress-bar': {
                backgroundColor: usagePercentage > 80 ? '#ff6b6b' : '#00a69c',
                borderRadius: 4,
              },
            }}
          />
          <Typography variant="caption" sx={{ mt: 1, opacity: 0.8 }}>
            Max {maxPagesAllowed} pages • Max {maxSizeAllowedMB}MB per file
          </Typography>
        </CardContent>
      </MotionCard>

      {/* Format Selection */}
      <Box sx={{ mb: 4, textAlign: 'center' }}>
        <Typography variant="h6" gutterBottom fontWeight="600" color="#002f56">
          Choose Output Format
        </Typography>
        <ToggleButtonGroup
          value={selectedFormat}
          exclusive
          onChange={(e, newFormat) => newFormat && setSelectedFormat(newFormat)}
          sx={{ mt: 2 }}
        >
          <ToggleButton
            value="pdf"
            sx={{
              px: 4,
              py: 2,
              '&.Mui-selected': {
                backgroundColor: '#005bbb',
                color: '#fff',
                '&:hover': { backgroundColor: '#004a99' },
              },
            }}
          >
            <Stack direction="row" spacing={1} alignItems="center">
              <PictureAsPdf />
              <Box textAlign="left">
                <Typography variant="body2" fontWeight="600">
                  PDF to PDF
                </Typography>
                <Typography variant="caption">Maintain format</Typography>
              </Box>
            </Stack>
          </ToggleButton>
          <ToggleButton
            value="html"
            sx={{
              px: 4,
              py: 2,
              '&.Mui-selected': {
                backgroundColor: '#005bbb',
                color: '#fff',
                '&:hover': { backgroundColor: '#004a99' },
              },
            }}
          >
            <Stack direction="row" spacing={1} alignItems="center">
              <Code />
              <Box textAlign="left">
                <Typography variant="body2" fontWeight="600">
                  PDF to HTML
                </Typography>
                <Typography variant="caption">Web accessible</Typography>
              </Box>
            </Stack>
          </ToggleButton>
        </ToggleButtonGroup>
      </Box>

      {/* Upload Area */}
      <MotionCard
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: 0.2 }}
        sx={{
          border: isDragActive ? '3px dashed #005bbb' : '2px dashed #ccc',
          backgroundColor: isDragActive ? '#e6f0ff' : '#fafafa',
          transition: 'all 0.3s',
          cursor: currentUsage >= maxFilesAllowed ? 'not-allowed' : 'pointer',
          opacity: currentUsage >= maxFilesAllowed ? 0.5 : 1,
        }}
      >
        <CardContent>
          <Box
            {...getRootProps()}
            sx={{
              py: 6,
              textAlign: 'center',
              outline: 'none',
            }}
          >
            <input {...getInputProps()} />
            <CloudUpload sx={{ fontSize: 64, color: '#005bbb', mb: 2 }} />
            <Typography variant="h6" gutterBottom fontWeight="600" color="#002f56">
              {isDragActive ? 'Drop your PDF here' : 'Drag & drop your PDF here'}
            </Typography>
            <Typography variant="body2" color="text.secondary" mb={2}>
              or click to browse files
            </Typography>
            <Button
              variant="outlined"
              disabled={currentUsage >= maxFilesAllowed}
              sx={{
                borderColor: '#005bbb',
                color: '#005bbb',
                '&:hover': { borderColor: '#004a99', backgroundColor: '#e6f0ff' },
              }}
            >
              Select File
            </Button>
          </Box>

          {selectedFile && (
            <MotionBox
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              sx={{ mt: 3 }}
            >
              <Paper sx={{ p: 2, backgroundColor: '#e6f0ff' }}>
                <Stack direction="row" spacing={2} alignItems="center">
                  <Description sx={{ color: '#005bbb', fontSize: 40 }} />
                  <Box flex={1}>
                    <Typography variant="body1" fontWeight="600">
                      {selectedFile.name}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {(selectedFile.size / 1024 / 1024).toFixed(2)} MB
                    </Typography>
                  </Box>
                  {!isUploading && (
                    <Button
                      variant="contained"
                      onClick={handleUpload}
                      sx={{
                        backgroundColor: '#00a69c',
                        '&:hover': { backgroundColor: '#008c84' },
                      }}
                    >
                      Upload & Process
                    </Button>
                  )}
                </Stack>
              </Paper>
            </MotionBox>
          )}

          {isUploading && (
            <Box sx={{ mt: 3 }}>
              <Stack direction="row" justifyContent="space-between" mb={1}>
                <Typography variant="body2">Uploading...</Typography>
                <Typography variant="body2" fontWeight="600">
                  {uploadProgress}%
                </Typography>
              </Stack>
              <LinearProgress
                variant="determinate"
                value={uploadProgress}
                sx={{
                  height: 8,
                  borderRadius: 4,
                  '& .MuiLinearProgress-bar': {
                    backgroundColor: '#00a69c',
                  },
                }}
              />
            </Box>
          )}

          {error && (
            <Alert severity="error" sx={{ mt: 2 }}>
              {error}
            </Alert>
          )}

          {currentUsage >= maxFilesAllowed && (
            <Alert severity="warning" sx={{ mt: 2 }}>
              You've reached your upload limit. Contact support to increase your quota.
            </Alert>
          )}
        </CardContent>
      </MotionCard>

      {/* Features */}
      <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} sx={{ mt: 4 }}>
        {[
          { icon: <CheckCircle />, text: 'WCAG 2.1 AA Compliant' },
          { icon: <CheckCircle />, text: 'AI-Powered Alt Text' },
          { icon: <CheckCircle />, text: 'Detailed Reports' },
        ].map((feature, index) => (
          <Paper
            key={index}
            sx={{
              flex: 1,
              p: 2,
              textAlign: 'center',
              backgroundColor: '#f8f9fa',
              border: '1px solid #e0e0e0',
            }}
          >
            <Stack direction="row" spacing={1} alignItems="center" justifyContent="center">
              <Box sx={{ color: '#00a69c' }}>{feature.icon}</Box>
              <Typography variant="body2" fontWeight="600">
                {feature.text}
              </Typography>
            </Stack>
          </Paper>
        ))}
      </Stack>
    </Box>
  );
};

export default ModernUploadSection;
