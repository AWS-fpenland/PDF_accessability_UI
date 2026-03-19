import json
import os
import re
import uuid
import boto3
from datetime import datetime
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
table = dynamodb.Table(os.environ['TABLE_NAME'])

CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,OPTIONS',
    'Content-Type': 'application/json'
}


def handler(event, context):
    method = event['httpMethod']
    user_sub = extract_user_sub(event)

    if not user_sub:
        return response(401, {'message': 'Unauthorized: user identity not found'})

    try:
        if method == 'POST':
            return create_job(user_sub, json.loads(event['body']))
        elif method == 'GET':
            return list_jobs(user_sub)
        elif method == 'PUT':
            return update_job(user_sub, json.loads(event['body']))
        else:
            return response(405, {'message': f'Method {method} not allowed'})
    except Exception as e:
        print(f"Error: {e}")
        return response(500, {'message': 'Internal server error'})


def extract_user_sub(event):
    try:
        return event['requestContext']['authorizer']['claims']['sub']
    except (KeyError, TypeError):
        return None


def create_job(user_sub, body):
    created_at = datetime.utcnow().isoformat() + 'Z'
    item = {
        'user_sub': user_sub,
        'created_at': created_at,
        'job_id': str(uuid.uuid4()),
        'filename': body['filename'],
        'format': body['format'],
        'status': 'processing',
        's3_bucket': body['s3_bucket'],
        's3_upload_key': body['s3_upload_key'],
        'page_count': body.get('page_count', 0),
    }
    table.put_item(Item=item)
    return response(200, item)


def list_jobs(user_sub):
    result = table.query(
        KeyConditionExpression=Key('user_sub').eq(user_sub),
        ScanIndexForward=False
    )
    jobs = result['Items']

    for job in jobs:
        if job.get('status') == 'processing':
            _check_and_complete(job)

    return response(200, {'jobs': jobs})


def _derive_result_key(job):
    """Derive the expected S3 result key from the upload key and format."""
    upload_key = job.get('s3_upload_key', '')
    fmt = job.get('format', 'pdf')

    if fmt == 'pdf' and upload_key.startswith('pdf/'):
        # pdf/{name}.pdf -> result/COMPLIANT_{name}.pdf
        filename = upload_key[len('pdf/'):]
        return f'result/COMPLIANT_{filename}'
    elif fmt == 'html' and upload_key.startswith('uploads/'):
        # uploads/{name}.pdf -> remediated/final_{sanitized_name}.zip
        filename = upload_key[len('uploads/'):]
        sanitized = _sanitize_for_s3(filename.rsplit('.', 1)[0]) + '.zip'
        return f'remediated/final_{sanitized}'
    return None


def _sanitize_for_s3(name):
    """Match the frontend sanitization logic for HTML result keys."""
    s = re.sub(r'\s', '_', name)
    s = re.sub(r'[\x00-\x1f\x7f{^}%`\]">\[~<#|&\\*?/$!\'":@+=]', '_', s)
    while '__' in s:
        s = s.replace('__', '_')
    return s.strip('_')


def _check_and_complete(job):
    """Check S3 for the result file; if found, update job in-place and in DynamoDB."""
    result_key = _derive_result_key(job)
    if not result_key:
        return

    bucket = job['s3_bucket']
    try:
        s3.head_object(Bucket=bucket, Key=result_key)
    except s3.exceptions.ClientError:
        return

    now = datetime.utcnow().isoformat() + 'Z'
    table.update_item(
        Key={'user_sub': job['user_sub'], 'created_at': job['created_at']},
        UpdateExpression='SET #s = :status, s3_result_key = :key, completed_at = :ts',
        ExpressionAttributeNames={'#s': 'status'},
        ExpressionAttributeValues={
            ':status': 'complete',
            ':key': result_key,
            ':ts': now,
        },
    )
    # Update the in-memory dict so the response reflects the new state
    job['status'] = 'complete'
    job['s3_result_key'] = result_key
    job['completed_at'] = now


def update_job(user_sub, body):
    created_at = body['created_at']
    update_expr = 'SET #s = :status'
    expr_names = {'#s': 'status'}
    expr_values = {':status': body['status']}

    if body.get('s3_result_key'):
        update_expr += ', s3_result_key = :result_key'
        expr_values[':result_key'] = body['s3_result_key']

    if body['status'] == 'complete':
        update_expr += ', completed_at = :completed_at'
        expr_values[':completed_at'] = datetime.utcnow().isoformat() + 'Z'

    table.update_item(
        Key={'user_sub': user_sub, 'created_at': created_at},
        UpdateExpression=update_expr,
        ExpressionAttributeNames=expr_names,
        ExpressionAttributeValues=expr_values,
    )
    return response(200, {'message': 'Job updated'})


def response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': CORS_HEADERS,
        'body': json.dumps(body, default=str)
    }
