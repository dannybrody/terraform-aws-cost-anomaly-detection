import uuid
import random
import string
import boto3
import calendar
import pytz
import logging
import json
from slack_sdk.webhook import WebhookClient
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
    utc = pytz.UTC
    today = datetime.now(utc)
    
    # this month
    last_day = calendar.monthrange(today.year, today.month)[1]
    month_end = date(today.year, today.month, last_day)
    
    # last month
    last_month_end = date(today.year, today.month, 1) - timedelta(days=1)
    last_month_start = date(last_month_end.year, last_month_end.month, 1)
    today = date(today.year, today.month, today.day)

    client = session.client('ce')
    response = client.get_cost_and_usage(
        TimePeriod={
            'Start': str(last_month_start),
            'End': str(last_month_end)
        },
        Granularity='MONTHLY',
        Metrics=[
            'UnblendedCost',
        ],
    )

    logger.info(f'last month start: {last_month_start}, last month end: {last_month_end}')

    previous_month_cost = float(response['ResultsByTime'][0]['Total']['UnblendedCost']['Amount'])
    
    logger.info(f'previous month:{previous_month_cost}')
    
    # By the end of the month, do a forecast between that day and the next one (1st day of next month)
    # to avoid api validation errors
    if today == month_end:
        month_end = month_end + timedelta(days=1)

    logger.info(f'Today: {today}, month end: {month_end}')

    response = client.get_cost_forecast(
        TimePeriod={
            'Start': str(today),
            'End': str(month_end)
        },
        Metric='UNBLENDED_COST',
        Granularity='MONTHLY'
    )

    forecasted_cost = float(response['Total']['Amount'])
    logger.info(f'Forecasted cost: {forecasted_cost}')
    percent = forecasted_cost/previous_month_cost * 100
    logger.info(f'Calculated percent: {percent}')

    return round(previous_month_cost, 2), round(forecasted_cost, 2), round(percent, 2)


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


def lambda_handler(event, context):
    """
    AWS lambda main function
    """
    now = datetime.now()
    # Format the datetime object as a string
    formatted_datetime = now.strftime('%Y-%m-%dT%H:%M:%SZ')
    sts = session.client("sts")
    account_id = sts.get_caller_identity()["Account"]
    sns_topic_arn = environ.get('SNS_TOPIC_ARN')
    previous_month_cost, forecasted_cost, percent = get_cost()
    msg = {
            "version": "0",
            "id": generate_msg_id(),
            "detail-type": "AWS COST REPORT",
            "source": "aws.events",
            "account": account_id,
            "time": formatted_datetime,
            "region": session.region_name,
            "resources": [
                f"Previous month: ${previous_month_cost}",
                f"Current month forecast: ${forecasted_cost}",
                f"Forecast Percent: {percent}%",
            ],
            "detail": {}
            }
    send_message_to_chatbot(sns_topic_arn, msg)