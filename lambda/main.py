import boto3
import uuid
import random
import string
import calendar
import logging
import json
from datetime import date, timedelta, datetime
from os import environ

# Get aws session
session = boto3.session.Session()
# Get lambda default logger handler
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def generate_msg_id():
    """
    Generates a random string that acts as the message id
    """
    # Generate a random UUID
    random_uuid = str(uuid.uuid4())

    # Generate a random string of lowercase letters
    random_letters = ''.join(random.choices(string.ascii_lowercase, k=8))

    # Generate a random string of digits
    random_digits = ''.join(random.choices(string.digits, k=12))

    # Concatenate the parts with the desired format
    random_string = f'{random_digits[:8]}-{random_digits[8:12]}-{random_letters[:4]}-{random_letters[4:]}-{random_uuid}'

    return random_string


def get_cost():
    """
    Calculates percentual increase/decrease of cost comparing current month forecast with previous month cost.
    """
    logger.info('Calculating cost')
    today = datetime.now()
    
    # current month
    first_day_current_month = date(today.year, today.month, 1)
    last_day_current_month = date(today.year, today.month, calendar.monthrange(today.year, today.month)[1])
    
    # previous month
    last_day_previous_month = today - timedelta(days=today.day)
    first_day_previous_month = date(last_day_previous_month.year, last_day_previous_month.month, 1)
    today = date(today.year, today.month, today.day)

    client = session.client('ce')
    response = client.get_cost_and_usage(
        TimePeriod={
            'Start': str(first_day_previous_month),
            'End': str(first_day_current_month) # End date is exclusive. Must use current month first day
        },
        Granularity='MONTHLY',
        Metrics=[
            'UnblendedCost',
        ],
    )

    logger.info(f'last month start: {first_day_previous_month}, last month end: {first_day_current_month}')

    previous_month_cost = float(response['ResultsByTime'][0]['Total']['UnblendedCost']['Amount'])

    logger.info(f'previous month:{previous_month_cost}')

    response = client.get_cost_and_usage(
        TimePeriod={
            'Start': str(first_day_current_month),
            'End': str(today)
        },
        Granularity='MONTHLY',
        Metrics=[
            'UnblendedCost',
        ],
    )

    logger.info(f'last month start: {first_day_previous_month}, last month end: {last_day_previous_month}')

    current_month_cost = float(response['ResultsByTime'][0]['Total']['UnblendedCost']['Amount'])
    
    logger.info(f'Current month:{current_month_cost}')
    
    # Forecast by the end of current month

    # By the end of the month, do a forecast between that day and the next one (1st day of next month)
    # to avoid api validation errors
    if today == last_day_current_month:
        last_day_current_month = last_day_current_month + timedelta(days=1)

    logger.info(f'Today: {today}, month end: {last_day_current_month}')

    response = client.get_cost_forecast(
        TimePeriod={
            'Start': str(today),
            'End': str(last_day_current_month)
        },
        Metric='UNBLENDED_COST',
        Granularity='MONTHLY'
    )

    forecasted_cost = float(response['Total']['Amount'])
    logger.info(f'Forecasted cost: {forecasted_cost}')
    
    return previous_month_cost, current_month_cost, forecasted_cost


def send_message_to_chatbot(topic_arn, message):
    """
    Posts message to SNS.
    """
    sns = session.client('sns')
    # Format the message payload for AWS Chatbot
    payload_json = json.dumps(message)

    logger.info(f'Sending to SNS. Paylod: {payload_json}')

    # Send the message to the specified topic
    response = sns.publish(
        TopicArn=topic_arn,
        Message=payload_json
    )
    logger.info(f'Response: {response}')

def message(previous, current, forecast):
    """
    craft the message that will be sent to SNS
    """
    now = datetime.now()
    up_down = "Up"
    previous = round(previous, 2)
    current = round(current, 2)
    forecast = round(forecast, 2)
    percent = int(abs(forecast/previous -1) * 100)
    
    if forecast < previous:
        up_down = "Down"
    
    msg = {
        "version": "0",
        "id": generate_msg_id(),
        "account": environ.get('ACCOUNT_ID'),
        "time": now.strftime('%Y-%m-%dT%H:%M:%SZ'),
        "region": environ.get('REGION'),
        "source": "aws.health",
        "detail-type": "AWS Health Event",
        "resources": [],
        "detail": {
        "eventDescription": [{
            "language": "en_US",
            "latestDescription": f'''AWS COST REPORT:
                Previous month cost: ${previous}
                Current month cost: ${current}
                Current month forecast: ${forecast}
                {up_down} {percent}% over last month'''
            }]
        }
    }
    return msg

def lambda_handler(event, context):
    """
    AWS lambda main function
    """
    logger.info('Main handler start')
    previous_month_cost, current_month_cost, forecasted_cost = get_cost()
    send_message_to_chatbot(environ.get('SNS_TOPIC_ARN'), message(previous_month_cost, current_month_cost, forecasted_cost))
    logger.info('Main handler end')