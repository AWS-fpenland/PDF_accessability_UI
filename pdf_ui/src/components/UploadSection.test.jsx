import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { useAuth } from 'react-oidc-context';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import UploadSection from './UploadSection';

// Mock dependencies
jest.mock('react-oidc-context');
jest.mock('@aws-sdk/client-s3');
jest.mock('pdf-lib', () => ({
  PDFDocument: {
    load: jest.fn()
  }
}));
jest.mock('../utilities/constants', () => ({
  region: 'us-east-1',
  PDFBucket: 'test-pdf-bucket',
  HTMLBucket: 'test-html-bucket',
  CheckAndIncrementQuota: 'https://api.test.com/quota',
  validateBucketConfiguration: jest.fn(() => ({ needsFullDeployment: false })),
  validateFormatBucket: jest.fn(() => ({ isConfigured: true, needsDeployment: false }))
}));

describe('UploadSection - User Metadata', () => {
  const mockAuth = {
    user: {
      profile: {
        sub: 'test-user-sub-123',
        email: 'test@example.com',
        'cognito:groups': ['DefaultUsers', 'TestGroup']
      },
      id_token: 'mock-id-token'
    }
  };

  const mockAwsCredentials = {
    accessKeyId: 'test-key',
    secretAccessKey: 'test-secret',
    sessionToken: 'test-token'
  };

  const mockOnUploadComplete = jest.fn();
  const mockOnUsageRefresh = jest.fn();
  const mockSetUsageCount = jest.fn();

  let mockS3Send;

  beforeEach(() => {
    jest.clearAllMocks();
    useAuth.mockReturnValue(mockAuth);
    
    // Mock S3Client
    mockS3Send = jest.fn().mockResolvedValue({});
    S3Client.mockImplementation(() => ({
      send: mockS3Send
    }));

    // Mock fetch for quota API
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ newCount: 1 })
      })
    );

    // Mock PDFDocument.load
    const { PDFDocument } = require('pdf-lib');
    PDFDocument.load.mockResolvedValue({
      getPageCount: () => 5
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('adds user_sub and user_groups to S3 object metadata', async () => {
    render(
      <UploadSection
        onUploadComplete={mockOnUploadComplete}
        awsCredentials={mockAwsCredentials}
        currentUsage={0}
        maxFilesAllowed={3}
        maxPagesAllowed={10}
        maxSizeAllowedMB={25}
        onUsageRefresh={mockOnUsageRefresh}
        setUsageCount={mockSetUsageCount}
        isFileUploaded={false}
      />
    );

    // Select PDF format
    const pdfOption = screen.getByText('PDF to PDF').closest('.format-option');
    fireEvent.click(pdfOption);

    // Wait for format to be selected
    await waitFor(() => {
      expect(screen.getByText('Upload PDF')).toBeInTheDocument();
    });

    // Create a mock PDF file
    const file = new File(['mock pdf content'], 'test.pdf', { type: 'application/pdf' });
    
    // Simulate file selection
    const uploadButton = screen.getByText('Upload PDF');
    fireEvent.click(uploadButton);

    // Simulate file input change
    const fileInput = document.querySelector('input[type="file"]');
    Object.defineProperty(fileInput, 'files', {
      value: [file],
      writable: false
    });
    fireEvent.change(fileInput);

    // Wait for the upload to complete
    await waitFor(() => {
      expect(PutObjectCommand).toHaveBeenCalled();
    }, { timeout: 3000 });

    // Verify PutObjectCommand was called with correct metadata
    const putObjectCall = PutObjectCommand.mock.calls[0][0];
    expect(putObjectCall.Metadata).toBeDefined();
    expect(putObjectCall.Metadata['user-sub']).toBe('test-user-sub-123');
    expect(putObjectCall.Metadata['user-groups']).toBe('DefaultUsers,TestGroup');
    expect(putObjectCall.Metadata['upload-timestamp']).toBeDefined();
  });

  test('handles empty user groups correctly', async () => {
    // Mock auth with no groups
    const authWithoutGroups = {
      user: {
        profile: {
          sub: 'test-user-sub-456',
          email: 'test2@example.com',
          'cognito:groups': []
        },
        id_token: 'mock-id-token'
      }
    };
    useAuth.mockReturnValue(authWithoutGroups);

    render(
      <UploadSection
        onUploadComplete={mockOnUploadComplete}
        awsCredentials={mockAwsCredentials}
        currentUsage={0}
        maxFilesAllowed={3}
        maxPagesAllowed={10}
        maxSizeAllowedMB={25}
        onUsageRefresh={mockOnUsageRefresh}
        setUsageCount={mockSetUsageCount}
        isFileUploaded={false}
      />
    );

    // Select PDF format
    const pdfOption = screen.getByText('PDF to PDF').closest('.format-option');
    fireEvent.click(pdfOption);

    await waitFor(() => {
      expect(screen.getByText('Upload PDF')).toBeInTheDocument();
    });

    // Create a mock PDF file
    const file = new File(['mock pdf content'], 'test.pdf', { type: 'application/pdf' });
    
    // Simulate file selection
    const uploadButton = screen.getByText('Upload PDF');
    fireEvent.click(uploadButton);

    const fileInput = document.querySelector('input[type="file"]');
    Object.defineProperty(fileInput, 'files', {
      value: [file],
      writable: false
    });
    fireEvent.change(fileInput);

    // Wait for the upload to complete
    await waitFor(() => {
      expect(PutObjectCommand).toHaveBeenCalled();
    }, { timeout: 3000 });

    // Verify metadata has empty string for groups
    const putObjectCall = PutObjectCommand.mock.calls[0][0];
    expect(putObjectCall.Metadata['user-sub']).toBe('test-user-sub-456');
    expect(putObjectCall.Metadata['user-groups']).toBe('');
  });

  test('includes upload timestamp in ISO format', async () => {
    render(
      <UploadSection
        onUploadComplete={mockOnUploadComplete}
        awsCredentials={mockAwsCredentials}
        currentUsage={0}
        maxFilesAllowed={3}
        maxPagesAllowed={10}
        maxSizeAllowedMB={25}
        onUsageRefresh={mockOnUsageRefresh}
        setUsageCount={mockSetUsageCount}
        isFileUploaded={false}
      />
    );

    // Select PDF format
    const pdfOption = screen.getByText('PDF to PDF').closest('.format-option');
    fireEvent.click(pdfOption);

    await waitFor(() => {
      expect(screen.getByText('Upload PDF')).toBeInTheDocument();
    });

    // Create a mock PDF file
    const file = new File(['mock pdf content'], 'test.pdf', { type: 'application/pdf' });
    
    const uploadButton = screen.getByText('Upload PDF');
    fireEvent.click(uploadButton);

    const fileInput = document.querySelector('input[type="file"]');
    Object.defineProperty(fileInput, 'files', {
      value: [file],
      writable: false
    });
    fireEvent.change(fileInput);

    // Wait for the upload to complete
    await waitFor(() => {
      expect(PutObjectCommand).toHaveBeenCalled();
    }, { timeout: 3000 });

    // Verify timestamp is in ISO format
    const putObjectCall = PutObjectCommand.mock.calls[0][0];
    const timestamp = putObjectCall.Metadata['upload-timestamp'];
    expect(timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/);
  });
});
