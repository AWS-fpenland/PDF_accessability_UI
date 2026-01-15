# Product Overview

PDF Accessibility Solutions is a dual-repository system that provides automated PDF accessibility remediation through AWS-powered services.

## Components

**Backend (PDF_Accessibility)**: Two remediation engines
- PDF-to-PDF: Maintains PDF format while improving accessibility using Adobe API and AWS Bedrock
- PDF-to-HTML: Converts PDFs to accessible HTML using AWS Bedrock Data Automation

**Frontend (PDF_accessability_UI)**: Web-based user interface
- User authentication and quota management via AWS Cognito
- File upload/download with real-time processing status
- Support for both remediation solutions

## Key Features

- WCAG 2.1 Level AA compliance
- Bulk PDF processing
- User quota management with group-based permissions
- Real-time processing monitoring via CloudWatch dashboards
- Secure file handling with S3 and IAM

## Target Users

Organizations and individuals needing to convert existing PDF documents into accessibility-compliant formats, particularly for compliance with accessibility standards.
