"""
AI Proxy Lambda Handler

This Lambda function proxies requests to the Virginia AI infrastructure,
communicating with the Bedrock AgentCore Gateway and AI Lambda functions.
"""

import json
import logging
import os
import time
import boto3
from botocore.config import Config

# Configure logging
log_level = os.environ.get('LOG_LEVEL', 'INFO')
logger = logging.getLogger()
logger.setLevel(log_level)

# Environment variables
VIRGINIA_LAMBDA_ARN = os.environ.get('VIRGINIA_LAMBDA_ARN', '')
VIRGINIA_GATEWAY_URL = os.environ.get('VIRGINIA_GATEWAY_URL', '')
PROJECT_NAME = os.environ.get('PROJECT_NAME', 'appsync-bahrain')

# AWS clients with cross-region configuration
lambda_client = boto3.client(
    'lambda',
    region_name='us-east-1',
    config=Config(
        retries={'max_attempts': 3},
        connect_timeout=10,
        read_timeout=120
    )
)


def lambda_handler(event, context):
    """
    Main Lambda handler for AI proxy requests.

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
        if field == 'getAIResponse':
            return handle_ai_response(arguments)
        elif field == 'searchKnowledgeBase':
            return handle_kb_search(arguments)
        elif field == 'processBooking':
            return handle_process_booking(arguments)
        elif field == 'chat':
            return handle_chat(arguments)
        else:
            logger.warning(f"Unknown field: {field}")
            return {'error': f"Unknown field: {field}"}

    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {'error': str(e)}


def handle_ai_response(arguments):
    """
    Handle getAIResponse query by invoking Virginia AI Lambda.
    """
    prompt = arguments.get('prompt', '')

    if not prompt:
        return {'error': 'Prompt is required'}

    start_time = time.time()

    try:
        # Invoke Virginia AI Lambda with 'message' key for chatbot
        response = invoke_virginia_lambda({
            'message': prompt
        })

        processing_time = time.time() - start_time

        return {
            'response': response.get('response', 'No response'),
            'model': response.get('model', 'amazon.nova-micro'),
            'processingTime': round(processing_time, 3)
        }

    except Exception as e:
        logger.error(f"Error getting AI response: {str(e)}")
        return {
            'response': f"Error: {str(e)}",
            'model': 'error',
            'processingTime': time.time() - start_time
        }


def handle_kb_search(arguments):
    """
    Handle searchKnowledgeBase query by invoking Virginia KB Search Lambda.
    """
    query = arguments.get('query', '')
    limit = arguments.get('limit', 5)

    if not query:
        return {'error': 'Query is required'}

    try:
        # Invoke Virginia KB Search Lambda
        response = invoke_virginia_lambda({
            'action': 'kb_search',
            'query': query,
            'limit': limit
        })

        return {
            'results': response.get('results', []),
            'total': response.get('total', 0)
        }

    except Exception as e:
        logger.error(f"Error searching knowledge base: {str(e)}")
        return {
            'results': [],
            'total': 0
        }


def handle_process_booking(arguments):
    """
    Handle processBooking mutation by invoking Virginia AI for booking processing.
    """
    booking_input = arguments.get('input', {})

    if not booking_input.get('brand'):
        return {
            'success': False,
            'message': 'Brand is required'
        }

    try:
        # Build booking prompt
        prompt = build_booking_prompt(booking_input)

        # Invoke Virginia AI Lambda
        response = invoke_virginia_lambda({
            'action': 'process_booking',
            'booking': booking_input,
            'prompt': prompt
        })

        return {
            'success': response.get('success', False),
            'bookingId': response.get('bookingId'),
            'message': response.get('message', 'Booking processed'),
            'details': {
                'brand': booking_input.get('brand'),
                'branch': booking_input.get('branch'),
                'date': booking_input.get('date'),
                'time': booking_input.get('time'),
                'confirmationCode': response.get('confirmationCode')
            }
        }

    except Exception as e:
        logger.error(f"Error processing booking: {str(e)}")
        return {
            'success': False,
            'message': f"Error: {str(e)}"
        }


def handle_chat(arguments):
    """
    Handle chat mutation by invoking Virginia AI for conversational response.
    """
    message = arguments.get('message', '')
    session_id = arguments.get('sessionId', '')

    if not message:
        return {'error': 'Message is required'}

    try:
        # Invoke Virginia AI Lambda with 'message' key for chatbot
        response = invoke_virginia_lambda({
            'message': message
        })

        return {
            'response': response.get('response', 'No response'),
            'sessionId': response.get('sessionId', session_id),
            'toolsUsed': response.get('toolsUsed', [])
        }

    except Exception as e:
        logger.error(f"Error in chat: {str(e)}")
        return {
            'response': f"Error: {str(e)}",
            'sessionId': session_id,
            'toolsUsed': []
        }


def invoke_virginia_lambda(payload):
    """
    Invoke the Virginia AI Lambda function.

    Args:
        payload: Request payload to send to Virginia Lambda

    Returns:
        Response from Virginia Lambda
    """
    if not VIRGINIA_LAMBDA_ARN:
        logger.warning("VIRGINIA_LAMBDA_ARN not configured, returning mock response")
        return get_mock_response(payload)

    try:
        logger.info(f"Invoking Virginia Lambda: {VIRGINIA_LAMBDA_ARN}")

        response = lambda_client.invoke(
            FunctionName=VIRGINIA_LAMBDA_ARN,
            InvocationType='RequestResponse',
            Payload=json.dumps(payload)
        )

        response_payload = json.loads(response['Payload'].read().decode('utf-8'))
        logger.info(f"Virginia Lambda response: {json.dumps(response_payload)}")

        # Parse body if response has statusCode/body structure
        if 'body' in response_payload:
            body = response_payload.get('body', '{}')
            if isinstance(body, str):
                return json.loads(body)
            return body

        return response_payload

    except Exception as e:
        logger.error(f"Error invoking Virginia Lambda: {str(e)}")
        raise


def build_booking_prompt(booking_input):
    """
    Build a natural language prompt for booking processing.
    """
    prompt = f"Process a booking request for {booking_input.get('brand', 'unknown brand')}"

    if booking_input.get('branch'):
        prompt += f" at {booking_input['branch']} branch"
    if booking_input.get('date'):
        prompt += f" on {booking_input['date']}"
    if booking_input.get('time'):
        prompt += f" at {booking_input['time']}"
    if booking_input.get('guests'):
        prompt += f" for {booking_input['guests']} guests"
    if booking_input.get('customerName'):
        prompt += f". Customer: {booking_input['customerName']}"

    return prompt


def get_mock_response(payload):
    """
    Return a mock response when Virginia Lambda is not configured.
    Used for testing and development.
    """
    action = payload.get('action', '')

    if action == 'query':
        return {
            'response': f"Mock response for: {payload.get('prompt', '')}",
            'model': 'mock'
        }
    elif action == 'kb_search':
        return {
            'results': [
                {'id': '1', 'content': 'Mock result 1', 'score': 0.9},
                {'id': '2', 'content': 'Mock result 2', 'score': 0.8}
            ],
            'total': 2
        }
    elif action == 'process_booking':
        return {
            'success': True,
            'bookingId': 'MOCK-12345',
            'message': 'Mock booking processed',
            'confirmationCode': 'MOCK-CONF-001'
        }
    elif action == 'chat':
        return {
            'response': f"Mock chat response for: {payload.get('message', '')}",
            'sessionId': payload.get('sessionId', 'mock-session'),
            'toolsUsed': []
        }
    else:
        return {'error': f"Unknown action: {action}"}
