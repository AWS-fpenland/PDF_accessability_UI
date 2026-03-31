# Implementation Plan: Observability and Usage Tracking

## Overview

This implementation plan enhances the existing CloudWatch logging infrastructure with user-centric tracking, structured logging, and long-term analytics capabilities using a batch export approach. The implementation follows a phased approach to maintain backward compatibility while adding new observability features.

## Tasks

- [x] 0. Create standalone observability CDK stack structure
  - [x] 0.1 Create observability_app.py entry point
    - Define CDK app for observability stack
    - Configure stack name: PDFAccessibilityObservability
    - Add context parameters for pdf_stack_name and ui_stack_name
    - _Deployment Strategy: Standalone Stack_
  
  - [x] 0.2 Create observability_stack.py
    - Define ObservabilityStack class extending cdk.Stack
    - Implement resource discovery by naming convention (no cross-stack dependencies)
    - Define log group names to monitor
    - Add stack description and tags
    - _Deployment Strategy: Standalone Stack_
  
  - [x] 0.3 Update cdk.json for observability stack
    - Add observability_app.py as additional CDK app
    - Configure context parameters
    - Set default values for stack names
    - _Deployment Strategy: Standalone Stack_
  
  - [x] 0.4 Create deployment documentation
    - Document standalone deployment commands
    - Document integration with existing deploy.sh
    - Document rollback procedures
    - Add troubleshooting guide
    - _Deployment Strategy: Standalone Stack_

- [x] 1. Set up data lake infrastructure in observability stack
  - Create new S3 bucket for data lake storage (separate from existing PDF processing buckets)
  - Configure bucket encryption with KMS
  - Set up lifecycle policies for intelligent tiering and 7-year retention
  - Create IAM roles for Lambda export function with CloudWatch Logs read permissions
  - Create IAM roles for Glue Crawler with S3 read permissions
  - All resources created in PDFAccessibilityObservability stack
  - _Requirements: 7.1, 7.2, 7.3, 8.1, 8.5_
  - _Deployment Strategy: Standalone Stack_

- [x] 2. Implement user context propagation
  - [x] 2.1 Add user_sub to S3 object metadata in React frontend upload component
    - Modify upload function to extract user_sub from Cognito session
    - Add user_sub and user_groups to S3 PutObject metadata
    - _Requirements: 1.1_
  
  - [x] 2.2 Extract user context in split_pdf Lambda function
    - Create UserContext dataclass in Python
    - Implement extract_user_context() function to read from S3 metadata
    - Pass user_sub to Step Functions execution input
    - _Requirements: 1.2_
  
  - [x] 2.3 Propagate user context to ECS tasks via environment variables
    - Update CDK stack to inject user_sub into ECS task environment
    - Modify Step Functions task definitions to pass user_sub
    - _Requirements: 1.3, 1.4_
  
  - [x] 2.4 Extract user context in merge and title Lambda functions
    - Implement context extraction from Step Functions input
    - _Requirements: 1.5, 1.6_
  
  - [ ]* 2.5 Write property test for user context propagation
    - **Property 1: User Context Propagation Completeness**
    - **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5, 1.6**

- [ ] 3. Implement structured logging module
  - [x] 3.1 Create Python EnhancedLogger class
    - Implement dual-output logging (legacy format + JSON)
    - Add _format_legacy() and _format_structured() methods
    - Support optional user context injection
    - _Requirements: 2.1, 2.2_
  
  - [ ] 3.2 Create JavaScript structured logger wrapper
    - Implement Node.js logger with dual output
    - Match Python logger interface for consistency
    - _Requirements: 2.1, 2.2_
  
  - [ ] 3.3 Create Java structured logger wrapper
    - Implement Java logger with dual output for merge Lambda
    - _Requirements: 2.1, 2.2_
  
  - [ ]* 3.4 Write property tests for structured logging
    - **Property 2: JSON Log Validity**
    - **Property 3: Mandatory Log Fields Presence**
    - **Property 4: Service-Specific Log Fields**
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8**

- [ ] 4. Integrate structured logging into existing components
  - [ ] 4.1 Update split_pdf Lambda to use EnhancedLogger
    - Replace existing logging.info() calls with enhanced_logger.info()
    - Add job_id generation and tracking
    - Log PDF metadata (filename, total_pages, file_size)
    - _Requirements: 2.3, 3.1, 6.1_
  
  - [ ] 4.2 Update Python ECS task (Adobe API) to use EnhancedLogger
    - Replace existing logging calls with structured logging
    - Log Adobe API operations with metrics
    - Log Bedrock invocations with token counts
    - _Requirements: 2.4, 4.1, 5.1, 5.2_
  
  - [ ] 4.3 Update JavaScript ECS task (LLM) to use structured logger
    - Replace console.log with structured logger
    - Log Bedrock invocations with metrics
    - _Requirements: 2.5, 4.2_
  
  - [ ] 4.4 Update merge Lambda to use structured logging
    - Add Java logger wrapper
    - Log merge operations with page counts
    - _Requirements: 2.6, 3.2_
  
  - [ ] 4.5 Update add_title Lambda to use EnhancedLogger
    - Log title generation with Bedrock metrics
    - _Requirements: 2.7, 4.3_
  
  - [ ]* 4.6 Write unit tests for logging integration
    - Test log format for each component
    - Test error logging scenarios
    - _Requirements: 2.3, 2.4, 2.5, 2.6, 2.7_

- [ ] 5. Checkpoint - Verify structured logging works
  - Deploy updated Lambda functions and ECS tasks to test environment
  - Upload test PDF and verify logs appear in CloudWatch
  - Verify both legacy format (for dashboard) and JSON format are present
  - Verify existing CloudWatch Dashboard still functions correctly
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Implement batch log export Lambda function
  - [x] 6.1 Create log export Lambda function
    - Implement lambda_handler() to export previous day's logs
    - Implement export_log_group() to query CloudWatch Logs Insights
    - Implement wait_for_query() with timeout handling
    - Filter for JSON logs only (ignore legacy format)
    - _Requirements: 8.1, 8.2_
  
  - [ ] 6.2 Implement S3 writer with partitioning
    - Write logs to S3 with year/month/day/service partitioning
    - Implement extract_service_name() helper function
    - Add error handling for S3 write failures
    - _Requirements: 8.3_
  
  - [ ] 6.3 Add export state tracking (optional)
    - Create DynamoDB table to track export progress
    - Prevent duplicate exports
    - _Requirements: 8.1_
  
  - [ ]* 6.4 Write unit tests for export Lambda
    - Test CloudWatch Logs query construction
    - Test S3 key generation with partitioning
    - Test error handling for failed queries
    - _Requirements: 8.1, 8.2, 8.3_

- [ ] 7. Deploy log export infrastructure
  - [ ] 7.1 Create CDK construct for export Lambda
    - Define Lambda function with 15-minute timeout
    - Configure environment variables (DATA_LAKE_BUCKET, LOG_GROUPS)
    - Grant CloudWatch Logs read permissions
    - Grant S3 write permissions to data lake bucket
    - _Requirements: 7.1, 8.1_
  
  - [ ] 7.2 Create EventBridge scheduled rule
    - Configure cron schedule for daily execution at 2 AM UTC
    - Add Lambda function as target
    - _Requirements: 8.1_
  
  - [ ]* 7.3 Write CDK tests for export infrastructure
    - Test Lambda function configuration
    - Test IAM permissions
    - Test EventBridge rule schedule
    - _Requirements: 7.1, 8.1_

- [ ] 8. Checkpoint - Verify log export works
  - Deploy export Lambda and EventBridge rule to test environment
  - Manually trigger export Lambda to test functionality
  - Verify logs are exported to S3 with correct partitioning
  - Verify JSON format is valid
  - Wait for scheduled execution and verify it runs successfully
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Set up AWS Glue Data Catalog
  - [ ] 9.1 Create Glue database for usage tracking
    - Define database "pdf_accessibility_usage"
    - _Requirements: 9.1_
  
  - [ ] 9.2 Create Glue table for usage logs
    - Define table schema with all required columns
    - Configure JSON SerDe for reading JSON files
    - Set up partition keys (year, month, day, service)
    - Configure S3 location to point to data lake
    - _Requirements: 9.2, 9.3, 9.4, 9.5_
  
  - [ ] 9.3 Create Glue Crawler for automatic schema discovery
    - Configure crawler to run daily at 3 AM UTC (after export)
    - Set update behavior to UPDATE_IN_DATABASE
    - _Requirements: 9.6_
  
  - [ ]* 9.4 Write CDK tests for Glue infrastructure
    - Test database creation
    - Test table schema definition
    - Test crawler configuration
    - _Requirements: 9.1, 9.2, 9.6_

- [ ] 10. Set up Amazon Athena query infrastructure
  - [ ] 10.1 Create Athena workgroup
    - Configure query result bucket
    - Set up encryption for query results
    - _Requirements: 10.1, 10.2_
  
  - [ ] 10.2 Create saved queries for common use cases
    - Query 1: Total usage by user for date range
    - Query 2: Bedrock usage by model and user
    - Query 3: Adobe API usage patterns
    - Query 4: Error analysis by category
    - Query 5: Cost allocation by user group
    - _Requirements: 10.3, 10.4, 10.5, 10.6, 10.7, 10.8, 10.9_
  
  - [ ]* 10.3 Write integration tests for Athena queries
    - Test query execution with sample data
    - Verify query results match expected format
    - Test partition pruning optimization
    - _Requirements: 10.3, 10.4, 10.5, 10.6, 10.7, 10.8, 10.9_

- [ ] 11. Implement error handling and validation
  - [ ] 11.1 Add error categorization logic
    - Implement categorize_error() function (user_error, system_error, external_service_error)
    - Add error logging with stack traces
    - _Requirements: 14.1, 14.2, 14.3_
  
  - [ ] 11.2 Implement log validation
    - Create JSON schema for log entries
    - Implement validate_log_entry() function
    - Handle validation failures gracefully (log error, continue processing)
    - _Requirements: 16.1, 16.2, 16.3_
  
  - [ ] 11.3 Add metric range validation
    - Validate numeric metrics are within expected ranges
    - _Requirements: 16.5_
  
  - [ ]* 11.4 Write property tests for error handling
    - **Property 18: Error Logging Completeness**
    - **Property 21: Malformed Log Handling**
    - **Property 23: Numeric Metric Range Validation**
    - **Validates: Requirements 14.1, 14.2, 14.3, 14.5, 16.1, 16.2, 16.3, 16.5**

- [ ] 12. Implement CloudWatch metrics and alarms
  - [ ] 12.1 Add EMF metric emission for critical errors
    - Emit CloudWatch metrics for system_error and external_service_error
    - _Requirements: 15.3_
  
  - [ ] 12.2 Create CloudWatch alarms for error rates
    - Alarm for high error rate (>5% of requests)
    - Alarm for validation failure rate (>5%)
    - _Requirements: 15.1, 15.2_
  
  - [ ]* 12.3 Write unit tests for metric emission
    - Test EMF format generation
    - Test metric emission for different error types
    - _Requirements: 15.3_

- [ ] 13. Implement performance optimizations
  - [ ] 13.1 Add asynchronous logging
    - Ensure logging calls are non-blocking
    - _Requirements: 13.2_
  
  - [ ] 13.2 Implement log batching
    - Batch log entries within 1-second window
    - _Requirements: 13.3_
  
  - [ ]* 13.3 Write performance tests
    - Measure logging overhead (<5% target)
    - Measure cold start impact
    - _Requirements: 13.1, 13.2, 13.3_

- [ ] 14. Final checkpoint - End-to-end testing
  - Deploy complete observability stack to test environment
  - Run full PDF processing workflow with test files
  - Verify user context propagates through all components
  - Verify structured logs appear in CloudWatch
  - Verify logs are exported to S3 daily
  - Verify Glue Crawler updates table schema
  - Execute Athena queries and verify results
  - Verify existing CloudWatch Dashboard still works
  - Verify no performance degradation in PDF processing
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 15. Documentation and deployment
  - [ ] 15.1 Update README with observability features
    - Document standalone stack deployment approach
    - Document new logging format
    - Document Athena query examples
    - Document cost estimates
    - Add section on deploying observability to existing environments
    - _Requirements: 17.1, 17.2_
    - _Deployment Strategy: Standalone Stack_
  
  - [ ] 15.2 Create runbook for common operations
    - How to deploy observability stack independently
    - How to query usage data
    - How to troubleshoot export failures
    - How to add new log fields
    - How to remove observability stack
    - _Requirements: 17.3_
    - _Deployment Strategy: Standalone Stack_
  
  - [ ] 15.3 Update deploy.sh with observability option
    - Add optional prompt to deploy observability after PDF processing
    - Integrate `cdk deploy PDFAccessibilityObservability` command
    - Add error handling for observability deployment
    - Document standalone deployment option
    - _Deployment Strategy: Standalone Stack_
  
  - [ ] 15.4 Deploy observability stack to test environment
    - Deploy PDFAccessibilityObservability stack
    - Verify no impact on existing PDF processing
    - Verify deployment success
    - Monitor for 24 hours to ensure stability
    - _Deployment Strategy: Standalone Stack_
  
  - [ ] 15.5 Deploy to production
    - Deploy PDFAccessibilityObservability stack to production
    - Verify deployment success
    - Monitor for 24 hours to ensure stability
    - _Deployment Strategy: Standalone Stack_

## Deployment Strategy Notes

**Standalone Stack Approach:**
- The observability infrastructure is deployed as a completely independent CDK stack
- No modifications to existing PDF processing or UI stacks required
- Can be deployed, updated, or destroyed without affecting production workloads
- Discovers existing resources by naming convention (no cross-stack dependencies)
- Optional feature that can be added to existing deployments at any time

**Deployment Commands:**
```bash
# Deploy observability independently
cd PDF_Accessibility
cdk deploy PDFAccessibilityObservability

# Remove observability without affecting PDF processing
cdk destroy PDFAccessibilityObservability

# Deploy as part of existing workflow (optional)
./deploy.sh  # Will prompt for observability deployment
```

**Key Benefits:**
- ✅ Zero impact on existing deployments
- ✅ Easy rollback if issues arise
- ✅ Gradual rollout capability (dev → test → prod)
- ✅ Independent lifecycle management
- ✅ No cross-stack dependencies or exports

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- The implementation maintains backward compatibility with existing logging and dashboard
- Batch export approach is cost-effective (~$83/year) and follows AWS best practices
- **Standalone stack deployment ensures zero impact on existing infrastructure**
