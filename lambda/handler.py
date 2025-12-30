"""
AppSync Resolver Lambda Handler

This Lambda function handles AppSync resolver requests for local operations
like health checks and basic queries.
"""

import json
import logging
import os
from datetime import datetime

# Configure logging
log_level = os.environ.get('LOG_LEVEL', 'INFO')
logger = logging.getLogger()
logger.setLevel(log_level)


def lambda_handler(event, context):
    """
    Main Lambda handler for AppSync resolver requests.

    Args:
        event: AppSync resolver event containing field and arguments
        context: Lambda context

    Returns:
        Response data for the GraphQL field
    """
    logger.info(f"Received event: {json.dumps(event)}")

    field = event.get('field', '')
    arguments = event.get('arguments', {})

    try:
        if field == 'healthCheck':
            return handle_health_check(context)
        else:
            logger.warning(f"Unknown field: {field}")
            return {
                'error': f"Unknown field: {field}"
            }

    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            'error': str(e)
        }


def handle_health_check(context):
    """
    Handle health check query.

    Returns service status information.
    """
    region = os.environ.get('REGION', 'unknown')
    project_name = os.environ.get('PROJECT_NAME', 'unknown')

    # Check various services
    services = {
        'lambda': 'healthy',
        'vpc': 'healthy',
        'virginiaConnection': check_virginia_connection()
    }

    return {
        'status': 'healthy',
        'region': region,
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'services': services
    }


def check_virginia_connection():
    """
    Check if Virginia VPC connection is available.

    This is a basic check - actual connectivity would need
    to be tested via network call.
    """
    virginia_lambda_arn = os.environ.get('VIRGINIA_LAMBDA_ARN', '')
    virginia_gateway_url = os.environ.get('VIRGINIA_GATEWAY_URL', '')

    if virginia_lambda_arn or virginia_gateway_url:
        return 'configured'
    else:
        return 'not_configured'
