import boto3
import uuid
import random
import string
import calendar
import logging
import json
import threading
from datetime import date, timedelta, datetime
from os import environ


# Get aws session
session = boto3.session.Session()
# Get lambda default logger handler
logger = logging.getLogger()
logger.setLevel(logging.INFO)
# Global variables
previous_month_cost = 0
current_month_cost = 0
forecasted_cost = 0


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

def calculate_cost(start_date, end_date, client, mode):
    """
    Calculates costs, modifies global variables to allow the use of threads.
    In order to use threads, the boto3 client must instantiated on the main thread and passed as a parameter
    """
    
    logger.info(f'{mode} - start date: {start_date}, end date: {end_date}')

    if mode == 'last_month' or mode == 'current_month':
        response = client.get_cost_and_usage(
        TimePeriod={
            'Start': str(start_date),
            'End': str(end_date) # End date is exclusive.
            },
            Granularity='MONTHLY',
            Metrics=[
                'UnblendedCost',
            ],
        )
        
        cost = float(response['ResultsByTime'][0]['Total']['UnblendedCost']['Amount'])

        logger.info(f'{mode} - Cost:{cost}')
        
        if mode == 'last_month':
            global previous_month_cost
            previous_month_cost = cost
        else:
            global current_month_cost
            current_month_cost = cost
    
    elif mode == 'forecast':
        response = client.get_cost_forecast(
        TimePeriod={
            'Start': str(start_date),
            'End': str(end_date)
            },
            Metric='UNBLENDED_COST',
            Granularity='MONTHLY'
        )

        global forecasted_cost
        forecasted_cost = float(response['Total']['Amount'])
        logger.info(f'{mode} - Cost:{forecasted_cost}')
    else:
        raise Exception('mode parameter must be one of ["last_month", "current_month", "forecast"]')
    

def calculate_dates():
    """
    Calculates dates to be used in the calculate_costs function. First day and last day of month
    """
    logger.info('Calculating cost')
    today = datetime.now()
    
    # current month dates
    first_day_current_month = date(today.year, today.month, 1)
    last_day_current_month = date(today.year, today.month, calendar.monthrange(today.year, today.month)[1])
    
    # previous month dates
    last_day_previous_month = today - timedelta(days=today.day)
    first_day_previous_month = date(last_day_previous_month.year, last_day_previous_month.month, 1)
    today = date(today.year, today.month, today.day)

    # Forecast by the end of current month dates
    # By the end of the month, do a forecast between that day and the next one (1st day of next month)
    # to avoid api validation errors
    if today == last_day_current_month:
        last_day_current_month = last_day_current_month + timedelta(days=1)

    return (first_day_previous_month, first_day_current_month, today, last_day_current_month)

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
    percent = int(abs(forecast/(previous+0.001) -1) * 100)
    
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
    first_day_previous_month, first_day_current_month, today, last_day_current_month = calculate_dates()
    client = session.client('ce')
    threads = []
    thread_arguments = [
        (first_day_previous_month, first_day_current_month, client, 'last_month' ),
        (first_day_current_month, today, client, 'current_month' ),
        (today, last_day_current_month, client, 'forecast' )
        ]
    
    # start threads
    for arg in thread_arguments:
        t = threading.Thread(target=calculate_cost, args=arg)
        threads.append(t)
        t.start()
    
    # wait for threads to finish execution
    for t in threads:
        t.join()

    send_message_to_chatbot(environ.get('SNS_TOPIC_ARN'), message(previous_month_cost, current_month_cost, forecasted_cost))
    logger.info('Main handler end')