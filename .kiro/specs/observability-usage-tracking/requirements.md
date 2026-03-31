# Requirements Document: Observability and Usage Tracking

## Introduction

This specification defines an observability and usage tracking solution for the PDF Accessibility project. The system will collect granular usage metrics across all AWS services, associate them with Cognito user identities, and enable SQL-based analytics for chargeback reporting and operational insights. The solution focuses on data collection, structured storage, and query capabilities, with dashboard visualization deferred to a future phase.

## Glossary

- **System**: The observability and usage tracking infrastructure
- **User**: An authenticated Cognito user with a unique sub (subject identifier)
- **Job**: A single PDF processing workflow initiated by a user, tracked from upload through completion
- **Processing_Pipeline**: The Step Functions state machine orchestrating PDF remediation
- **Data_Lake**: S3-based storage for long-term retention of structured usage data
- **Query_Engine**: Amazon Athena service for SQL-based analytics
- **Structured_Log**: JSON-formatted log entry with standardized schema
- **Metric**: A quantifiable measurement of resource usage or system behavior
- **User_Context**: The Cognito user identity (sub, groups, attributes) associated with an operation
- **Chargeback_Report**: A usage summary aggregated by user for cost allocation

## Requirements

### Requirement 1: User Identity Propagation

**User Story:** As a system administrator, I want all processing operations to be associated with the initiating user's Cognito identity, so that I can track usage and costs per user.

#### Acceptance Criteria

1. WHEN a user uploads a PDF file, THE System SHALL capture the user's Cognito sub from the authenticated session
2. WHEN the split_pdf Lambda is triggered, THE System SHALL receive the user's sub as part of the S3 event metadata
3. WHEN the Step Functions execution starts, THE System SHALL include the user's sub in the execution input
4. WHEN ECS tasks execute, THE System SHALL receive the user's sub via environment variables
5. WHEN any Lambda function in the pipeline executes, THE System SHALL have access to the user's sub
6. FOR ALL log entries generated during processing, THE System SHALL include the user's sub in the structured log

### Requirement 2: Structured Logging

**User Story:** As a data analyst, I want all logs to follow a consistent JSON schema, so that I can reliably query and analyze usage data.

#### Acceptance Criteria

1. WHEN any component logs an event, THE System SHALL format the log as valid JSON
2. THE System SHALL include these mandatory fields in every log entry: timestamp, user_sub, job_id, service_name, event_type
3. WHEN a Lambda function logs, THE System SHALL include function_name, request_id, duration_ms, memory_used_mb
4. WHEN an ECS task logs, THE System SHALL include task_arn, container_name, cpu_used, memory_used_mb
5. WHEN a Step Functions state logs, THE System SHALL include execution_arn, state_name, state_type
6. WHEN a Bedrock API call is made, THE System SHALL log model_id, input_tokens, output_tokens, latency_ms
7. WHEN an Adobe API call is made, THE System SHALL log api_operation, response_time_ms, status_code
8. WHEN an S3 operation occurs, THE System SHALL log bucket_name, object_key, operation_type, bytes_transferred

### Requirement 3: Page-Level Tracking

**User Story:** As a billing administrator, I want to know how many pages each user has processed, so that I can implement page-based pricing.

#### Acceptance Criteria

1. WHEN a PDF is split, THE System SHALL log the total page count and associate it with the user's sub
2. WHEN each chunk is processed, THE System SHALL log the page range for that chunk
3. WHEN a job completes, THE System SHALL calculate and log the total pages processed for that user
4. FOR ALL page count metrics, THE System SHALL ensure accuracy by validating against the original PDF metadata

### Requirement 4: AWS Service Usage Tracking

**User Story:** As a cost analyst, I want detailed metrics for each AWS service used per user, so that I can allocate costs accurately.

#### Acceptance Criteria

1. WHEN a Lambda function executes, THE System SHALL log invocation count, duration, memory allocation, and billed duration per user
2. WHEN an ECS task runs, THE System SHALL log task duration, CPU units, memory allocation, and vCPU-hours per user
3. WHEN a Step Functions execution occurs, THE System SHALL log state transitions, execution duration, and number of states per user
4. WHEN S3 operations occur, THE System SHALL log storage bytes, GET requests, PUT requests, and data transfer per user
5. WHEN Bedrock is invoked, THE System SHALL log model ID, input tokens, output tokens, and invocation count per user
6. FOR ALL service metrics, THE System SHALL capture timestamps for start and end times

### Requirement 5: Adobe API Usage Tracking

**User Story:** As a vendor management analyst, I want to track Adobe API usage per user, so that I can manage third-party costs.

#### Acceptance Criteria

1. WHEN the Python ECS task calls Adobe AutoTag API, THE System SHALL log the API operation type and user sub
2. WHEN Adobe API responds, THE System SHALL log response time, status code, and any error messages
3. WHEN a job uses Adobe services, THE System SHALL aggregate total Adobe API calls per user
4. FOR ALL Adobe API calls, THE System SHALL include the job_id for traceability

### Requirement 6: Job-Level Correlation

**User Story:** As a support engineer, I want to trace all operations for a specific PDF processing job, so that I can troubleshoot issues efficiently.

#### Acceptance Criteria

1. WHEN a PDF upload triggers processing, THE System SHALL generate a unique job_id
2. WHEN the job_id is created, THE System SHALL associate it with the user's sub and original filename
3. WHEN any component processes part of the job, THE System SHALL include the job_id in all log entries
4. WHEN querying logs, THE System SHALL support filtering by job_id to retrieve all related events
5. FOR ALL job stages (split, process, merge, validate), THE System SHALL log stage transitions with timestamps

### Requirement 7: CloudWatch Logs Aggregation

**User Story:** As a platform engineer, I want all logs centralized in CloudWatch Logs, so that I have a single source of truth for operational data.

#### Acceptance Criteria

1. THE System SHALL configure all Lambda functions to send logs to CloudWatch Logs
2. THE System SHALL configure all ECS tasks to send logs to CloudWatch Logs
3. THE System SHALL configure Step Functions to send execution logs to CloudWatch Logs
4. WHEN logs are written, THE System SHALL use consistent log group naming: /aws/{service}/{resource-name}
5. THE System SHALL set log retention to 90 days for all log groups
6. FOR ALL log groups, THE System SHALL enable log insights queries

### Requirement 8: Data Lake Storage

**User Story:** As a data engineer, I want processed logs stored in S3, so that I can perform long-term analysis and meet compliance requirements.

#### Acceptance Criteria

1. THE System SHALL export CloudWatch Logs to S3 using a Lambda function triggered daily by EventBridge
2. WHEN logs are exported, THE System SHALL store them in JSON format for efficient querying
3. THE System SHALL partition S3 data by year, month, day, and service for query optimization
4. THE System SHALL optionally compress exported data using GZIP compression
5. THE System SHALL retain data in S3 for 7 years to meet compliance requirements
6. WHEN data is written to S3, THE System SHALL use a bucket with encryption enabled

### Requirement 9: AWS Glue Data Catalog

**User Story:** As a data analyst, I want a schema registry for usage data, so that I can discover and query datasets easily.

#### Acceptance Criteria

1. THE System SHALL create a Glue database named "pdf_accessibility_usage"
2. THE System SHALL define Glue tables for each log type: lambda_logs, ecs_logs, stepfunctions_logs, bedrock_logs, s3_logs
3. WHEN a new log schema is introduced, THE System SHALL update the Glue table schema automatically
4. THE System SHALL configure Glue crawlers to run daily and update table schemas
5. FOR ALL Glue tables, THE System SHALL define partition keys matching the S3 partitioning strategy

### Requirement 10: Amazon Athena Query Support

**User Story:** As a business analyst, I want to query usage data using SQL, so that I can generate custom reports without engineering support.

#### Acceptance Criteria

1. THE System SHALL configure Athena to use the Glue Data Catalog
2. THE System SHALL create an Athena workgroup named "pdf-accessibility-analytics"
3. WHEN queries execute, THE System SHALL store results in a dedicated S3 bucket
4. THE System SHALL support queries for total usage by user over a date range
5. THE System SHALL support queries for cost breakdown by service per user
6. THE System SHALL support queries for Adobe API usage patterns
7. THE System SHALL support queries for Bedrock token consumption by model and user
8. THE System SHALL support queries for job success/failure rates by user
9. FOR ALL queries, THE System SHALL optimize performance using partition pruning

### Requirement 11: Cognito Integration Review

**User Story:** As a solutions architect, I want to validate that Cognito attributes support observability needs, so that user context is complete.

#### Acceptance Criteria

1. THE System SHALL document all existing Cognito custom attributes relevant to usage tracking
2. WHEN evaluating observability requirements, THE System SHALL identify any missing user metadata
3. IF additional attributes are needed, THE System SHALL propose new custom attributes with justification
4. THE System SHALL ensure user groups (DefaultUsers, AmazonUsers, AdminUsers) are included in usage reports
5. FOR ALL usage queries, THE System SHALL support filtering by user group

### Requirement 12: Cost-Effective Data Retention

**User Story:** As a finance manager, I want cost-effective data storage, so that observability doesn't significantly increase operational costs.

#### Acceptance Criteria

1. THE System SHALL use S3 Intelligent-Tiering for data lake storage
2. WHEN data ages beyond 90 days, THE System SHALL transition it to Infrequent Access storage class
3. WHEN data ages beyond 1 year, THE System SHALL transition it to Glacier Flexible Retrieval
4. THE System SHALL use JSON format with optional GZIP compression to balance readability and storage costs
5. THE System SHALL implement lifecycle policies to automatically manage data transitions

### Requirement 13: Performance Impact Minimization

**User Story:** As a product owner, I want observability to have minimal impact on PDF processing performance, so that user experience is not degraded.

#### Acceptance Criteria

1. WHEN structured logging is added, THE System SHALL ensure Lambda cold start time increases by no more than 100ms
2. WHEN logging to CloudWatch, THE System SHALL use asynchronous writes to avoid blocking processing
3. THE System SHALL batch log entries when possible to reduce API calls
4. WHEN the export Lambda runs, THE System SHALL complete within 15 minutes for a day's worth of logs
5. FOR ALL processing operations, THE System SHALL ensure observability overhead is less than 5% of total execution time

### Requirement 14: Error and Exception Tracking

**User Story:** As a reliability engineer, I want all errors and exceptions logged with context, so that I can identify and resolve issues quickly.

#### Acceptance Criteria

1. WHEN an exception occurs in any component, THE System SHALL log the error message, stack trace, and user_sub
2. WHEN a job fails, THE System SHALL log the failure reason and the stage where it failed
3. THE System SHALL categorize errors by type: user_error, system_error, external_service_error
4. WHEN querying errors, THE System SHALL support filtering by error type, user, and time range
5. FOR ALL errors, THE System SHALL include the job_id for correlation

### Requirement 15: Real-Time Monitoring Support

**User Story:** As an operations engineer, I want near-real-time access to usage metrics, so that I can respond to issues promptly.

#### Acceptance Criteria

1. WHEN logs are written to CloudWatch, THE System SHALL make them available for querying within 30 seconds
2. THE System SHALL support CloudWatch Logs Insights queries for real-time analysis
3. WHEN critical errors occur, THE System SHALL emit CloudWatch metrics for alerting
4. THE System SHALL provide pre-built Logs Insights queries for common operational questions
5. FOR ALL real-time queries, THE System SHALL return results within 10 seconds for the last 24 hours of data

### Requirement 16: Data Quality and Validation

**User Story:** As a data governance officer, I want to ensure data quality in the usage tracking system, so that reports are accurate and trustworthy.

#### Acceptance Criteria

1. THE System SHALL validate that all required fields are present in structured logs before writing
2. WHEN a log entry is malformed, THE System SHALL log the validation error and continue processing
3. THE System SHALL implement schema validation for JSON logs using JSON Schema
4. WHEN data is exported to S3, THE System SHALL verify record counts match CloudWatch Logs
5. FOR ALL numeric metrics, THE System SHALL validate that values are within expected ranges

### Requirement 17: Security and Compliance

**User Story:** As a security officer, I want usage data protected and compliant with data privacy regulations, so that we meet security and legal requirements.

#### Acceptance Criteria

1. THE System SHALL encrypt all data at rest in S3 using AWS KMS
2. THE System SHALL encrypt all data in transit using TLS 1.2 or higher
3. THE System SHALL implement least-privilege IAM policies for all components
4. WHEN storing user data, THE System SHALL comply with data retention policies
5. THE System SHALL support data deletion requests for specific users (GDPR compliance)
6. FOR ALL access to usage data, THE System SHALL log access attempts in CloudTrail

### Requirement 18: Backward Compatibility

**User Story:** As a DevOps engineer, I want the observability solution to integrate with existing infrastructure without breaking changes, so that deployment is smooth.

#### Acceptance Criteria

1. WHEN observability components are deployed, THE System SHALL not modify existing Lambda function logic
2. THE System SHALL add observability through environment variables and IAM permissions only
3. WHEN new log groups are created, THE System SHALL not conflict with existing log groups
4. THE System SHALL support gradual rollout by allowing observability to be enabled per component
5. FOR ALL existing CloudWatch Dashboards, THE System SHALL preserve functionality
