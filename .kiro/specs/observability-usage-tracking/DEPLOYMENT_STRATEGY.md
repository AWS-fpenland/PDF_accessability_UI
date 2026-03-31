# Observability Stack Deployment Strategy

## Overview

The observability infrastructure is deployed as a **standalone CDK stack** (`PDFAccessibilityObservability`) that operates independently from the existing PDF processing and UI infrastructure.

## Key Benefits

✅ **Zero Impact Deployment**
- No modifications to existing PDF processing or UI stacks required
- Existing workloads continue unaffected during observability deployment

✅ **Independent Lifecycle Management**
- Deploy, update, or destroy observability without touching production
- Easy rollback if issues arise
- Gradual rollout capability (dev → test → prod)

✅ **Resource Discovery**
- Automatically discovers existing log groups by naming convention
- No cross-stack dependencies or CloudFormation exports required
- No tight coupling between stacks

✅ **Optional Feature**
- Can be added to existing deployments at any time
- Not required for PDF processing to function
- Can be removed without affecting core functionality

## Stack Structure

```
PDF_Accessibility/
├── app.py                          # Existing: Main PDF processing stack
├── observability_app.py            # NEW: Observability stack entry point
├── cdk/
│   ├── cdk_stack.py               # Existing: PDF processing infrastructure
│   └── observability_stack.py     # NEW: Observability infrastructure
├── lambda/
│   └── log_export/                # NEW: Daily log export Lambda
│       ├── index.py
│       └── requirements.txt
└── cdk.json                        # Existing: CDK configuration
```

## Deployment Commands

### Deploy Observability Stack

```bash
# Navigate to PDF_Accessibility directory
cd PDF_Accessibility

# Deploy observability stack (after PDF processing is deployed)
cdk deploy PDFAccessibilityObservability

# Deploy with custom context parameters
cdk deploy PDFAccessibilityObservability \
  --context pdf_stack_name=PDFAccessibility \
  --context ui_stack_name=CdkBackendStack
```

### Update Observability Stack

```bash
# Update observability independently
cd PDF_Accessibility
cdk deploy PDFAccessibilityObservability
```

### Remove Observability Stack

```bash
# Remove observability without affecting PDF processing
cd PDF_Accessibility
cdk destroy PDFAccessibilityObservability

# PDF processing continues to function normally
```

### Deploy All Stacks Together (Optional)

```bash
# Deploy both PDF processing and observability
cd PDF_Accessibility
cdk deploy --all
```

## Integration with Existing Deployment Script

The observability stack can be optionally deployed as part of the existing `deploy.sh` workflow:

```bash
# After successful PDF processing deployment
echo ""
echo "Would you like to deploy the observability stack? (y/n)"
read -p "This enables usage tracking and chargeback reporting: " DEPLOY_OBSERVABILITY

if [[ "$DEPLOY_OBSERVABILITY" =~ ^[Yy]$ ]]; then
    print_status "🔍 Deploying observability stack..."
    
    cd PDF_Accessibility
    cdk deploy PDFAccessibilityObservability --require-approval never
    
    if [ $? -eq 0 ]; then
        print_success "✅ Observability stack deployed successfully!"
        print_status "   Data Lake Bucket: pdf-accessibility-data-lake-$ACCOUNT_ID-$REGION"
        print_status "   Athena Workgroup: pdf-accessibility-analytics"
    else
        print_error "❌ Observability deployment failed"
    fi
fi
```

## Resource Discovery Pattern

The observability stack discovers existing resources by naming convention, eliminating the need for cross-stack references:

```python
# Observability stack discovers log groups by name
LOG_GROUPS = [
    "/ecs/MyFirstTaskDef/PythonContainerLogGroup",
    "/ecs/MySecondTaskDef/JavaScriptContainerLogGroup",
    "/aws/states/MyStateMachine_PDFAccessibility",
    f"/aws/lambda/PDFAccessibility-SplitPDF-*",
    f"/aws/lambda/PDFAccessibility-JavaLambda-*",
    f"/aws/lambda/PDFAccessibility-AddTitleLambda-*",
]

# No CloudFormation exports or cross-stack dependencies required
```

## Verification Steps

### 1. Verify Stack Deployment

```bash
# Check stack status
aws cloudformation describe-stacks \
  --stack-name PDFAccessibilityObservability \
  --query 'Stacks[0].StackStatus'

# Expected output: CREATE_COMPLETE or UPDATE_COMPLETE
```

### 2. List Created Resources

```bash
# List all resources in the observability stack
aws cloudformation list-stack-resources \
  --stack-name PDFAccessibilityObservability
```

### 3. Verify Data Lake Bucket

```bash
# Check if data lake bucket was created
aws s3 ls | grep pdf-accessibility-data-lake
```

### 4. Verify Export Lambda

```bash
# Check if export Lambda was created
aws lambda list-functions \
  --query 'Functions[?contains(FunctionName, `LogExport`)].FunctionName'
```

### 5. Verify EventBridge Rule

```bash
# Check if daily export schedule was created
aws events list-rules \
  --query 'Rules[?contains(Name, `DailyLogExport`)].Name'
```

## Rollback Procedure

If issues arise with the observability stack:

```bash
# 1. Stop the export Lambda (if needed)
aws lambda update-function-configuration \
  --function-name <LogExportLambdaName> \
  --environment Variables={}

# 2. Disable the EventBridge rule
aws events disable-rule --name <DailyLogExportRuleName>

# 3. Destroy the observability stack
cd PDF_Accessibility
cdk destroy PDFAccessibilityObservability

# 4. Verify PDF processing is unaffected
# Upload a test PDF and verify it processes correctly
```

## Gradual Rollout Strategy

### Phase 1: Development Environment

```bash
# Deploy to dev environment first
cd PDF_Accessibility
cdk deploy PDFAccessibilityObservability \
  --context environment=dev \
  --profile dev-profile
```

### Phase 2: Test Environment

```bash
# After validating in dev, deploy to test
cdk deploy PDFAccessibilityObservability \
  --context environment=test \
  --profile test-profile
```

### Phase 3: Production Environment

```bash
# After validating in test, deploy to production
cdk deploy PDFAccessibilityObservability \
  --context environment=prod \
  --profile prod-profile
```

## Monitoring Observability Stack

### CloudWatch Metrics

Monitor the observability stack itself:

```bash
# Check export Lambda invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=<LogExportLambdaName> \
  --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

### CloudWatch Logs

Check export Lambda logs:

```bash
# View recent export Lambda logs
aws logs tail /aws/lambda/<LogExportLambdaName> --follow
```

### S3 Data Lake

Verify logs are being exported:

```bash
# List exported logs in data lake
aws s3 ls s3://pdf-accessibility-data-lake-$ACCOUNT_ID-$REGION/logs/ --recursive
```

## Cost Estimation

### Observability Stack Costs

- **S3 Data Lake**: ~$0.023/GB/month (Intelligent-Tiering)
- **Lambda Export**: ~$0.20/month (daily execution, 15-min duration)
- **Glue Crawler**: ~$0.44/month (daily execution)
- **Athena Queries**: $5/TB scanned (pay-per-query)
- **CloudWatch Logs**: Existing (no additional cost)

**Total Estimated Cost**: ~$7/month (~$83/year) for 10GB/day of logs

## Troubleshooting

### Issue: Stack deployment fails

```bash
# Check CloudFormation events
aws cloudformation describe-stack-events \
  --stack-name PDFAccessibilityObservability \
  --max-items 20
```

### Issue: Export Lambda fails

```bash
# Check Lambda logs for errors
aws logs tail /aws/lambda/<LogExportLambdaName> --since 1h
```

### Issue: No data in S3 data lake

```bash
# Manually trigger export Lambda
aws lambda invoke \
  --function-name <LogExportLambdaName> \
  --payload '{}' \
  response.json

# Check response
cat response.json
```

### Issue: Athena queries fail

```bash
# Check Glue table schema
aws glue get-table \
  --database-name pdf_accessibility_usage \
  --name usage_logs
```

## Best Practices

1. **Deploy to Non-Production First**: Always test in dev/test before production
2. **Monitor Initial Deployment**: Watch CloudWatch metrics for 24 hours after deployment
3. **Verify Data Export**: Check S3 data lake after first scheduled export
4. **Test Athena Queries**: Run sample queries to verify data is queryable
5. **Set Up Alerts**: Create CloudWatch alarms for export Lambda failures
6. **Document Custom Changes**: If you modify the stack, update this documentation
7. **Regular Reviews**: Review observability costs monthly
8. **Backup Strategy**: S3 data lake has versioning disabled; enable if needed

## Support and Documentation

- **Design Document**: `.kiro/specs/observability-usage-tracking/design.md`
- **Requirements**: `.kiro/specs/observability-usage-tracking/requirements.md`
- **Implementation Tasks**: `.kiro/specs/observability-usage-tracking/tasks.md`
- **AWS CDK Documentation**: https://docs.aws.amazon.com/cdk/
- **CloudWatch Logs Insights**: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html
- **Athena Documentation**: https://docs.aws.amazon.com/athena/
