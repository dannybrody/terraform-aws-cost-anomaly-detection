import unittest
from unittest.mock import patch
from datetime import date, datetime
import calendar
from freezegun import freeze_time
import src.main


class CostAnomalyDetectionTests(unittest.TestCase):
    def setUp(self):
        src.main.previous_month_cost = 0.0  # make sure the state is defined at test start

    @patch('src.main.boto3.session.Session.client')
    def test_calculate_cost_last_month(self, mock_client):
        mock_response = {
            'ResultsByTime': [{
                'TimePeriod': {'Start': '2023-01-01', 'End': '2023-02-01'},
                'Total': {'UnblendedCost': {'Amount': '100.0'}}
            }]
        }
        mock_client.return_value.get_cost_and_usage.return_value = mock_response

        start_date = datetime(2023, 1, 1)
        end_date = datetime(2023, 2, 1)
        client = mock_client('ce')

        src.main.calculate_cost(start_date, end_date, client, 'last_month')
        self.assertEqual(src.main.previous_month_cost, 100.0)

    @patch('src.main.boto3.session.Session.client')
    def test_calculate_cost_current_month(self, mock_client):
        mock_response = {
            'ResultsByTime': [{
                'TimePeriod': {'Start': '2023-02-01', 'End': '2023-03-01'},
                'Total': {'UnblendedCost': {'Amount': '150.0'}}
            }]
        }
        mock_client.return_value.get_cost_and_usage.return_value = mock_response

        start_date = datetime(2023, 2, 1)
        end_date = datetime(2023, 3, 1)
        client = mock_client('ce')

        src.main.calculate_cost(start_date, end_date, client, 'current_month')

        self.assertEqual(src.main.current_month_cost, 150.0)

    @patch('src.main.boto3.session.Session.client')
    def test_calculate_cost_forecast(self, mock_client):
        mock_response = {'Total': {'Amount': '200.0'}}
        mock_client.return_value.get_cost_forecast.return_value = mock_response

        start_date = datetime(2023, 2, 10)
        end_date = datetime(2023, 3, 1)
        client = mock_client('ce')

        src.main.calculate_cost(start_date, end_date, client, 'forecast')

        self.assertEqual(src.main.forecasted_cost, 200.0)

    @patch('src.main.boto3.session.Session.client')
    def test_calculate_cost_error(self, mock_client):
        mock_response = {
            'ResultsByTime': [{
                'TimePeriod': {'Start': '2023-01-01', 'End': '2023-02-01'},
                'Total': {'UnblendedCost': {'Amount': '100.0'}}
            }]
        }
        mock_client.return_value.get_cost_and_usage.return_value = mock_response

        start_date = datetime(2023, 1, 1)
        end_date = datetime(2023, 2, 1)
        client = mock_client('ce')
        
        with self.assertRaises(Exception):
            src.main.calculate_cost(start_date, end_date, client, 'trigger_error')

    def test_generate_msg_id(self):
        msg_id = src.main.generate_msg_id()
        self.assertEqual(len(msg_id), 60)  # UUID length

    def test_message(self):
        previous = 100.0
        current = 150.0
        forecast = 200.0
        msg = src.main.message(previous, current, forecast)

        self.assertIn('AWS COST REPORT', msg['detail']['eventDescription'][0]['latestDescription'])
        self.assertIn('Previous month cost: $100.0', msg['detail']['eventDescription'][0]['latestDescription'])
        self.assertIn('Current month cost: $150.0', msg['detail']['eventDescription'][0]['latestDescription'])
        self.assertIn('Current month forecast: $200.0', msg['detail']['eventDescription'][0]['latestDescription'])

    def test_message_less_forecast(self):
        previous = 50.0
        current = 20.0
        forecast = 40.0
        msg = src.main.message(previous, current, forecast)
        self.assertIn('Down', msg['detail']['eventDescription'][0]['latestDescription'])

    @freeze_time("2023-12-30")
    def test_calculate_dates(self):
        today = datetime.now()
        first_day_previous_month, first_day_current_month, _, last_day_current_month = src.main.calculate_dates()
        self.assertEqual(first_day_previous_month, date(today.year, today.month - 1, 1))
        self.assertEqual(first_day_current_month, date(today.year, today.month, 1))
        self.assertEqual(last_day_current_month, date(today.year, today.month, calendar.monthrange(today.year, today.month)[1]))

    @freeze_time("2023-12-31")
    def test_calculate_dates_last_day_month(self):
        today = datetime.now()
        first_day_previous_month, first_day_current_month, _, last_day_current_month = src.main.calculate_dates()
        self.assertEqual(first_day_previous_month, date(today.year, today.month - 1, 1))
        self.assertEqual(first_day_current_month, date(today.year, today.month, 1))
        self.assertEqual(today.date(), date(today.year, today.month, calendar.monthrange(today.year, today.month)[1]))

    @patch('src.main.boto3.session.Session.client')
    def test_send_message_to_chatbot(self, mock_client):
        mock_response = {'MessageId': 'mock_message_id'}
        mock_client.return_value.publish.return_value = mock_response

        topic_arn = 'arn:arn:aws:sns:us-east-1:123456789012:TestTopic'
        message = 'Test message'
        src.main.send_message_to_chatbot(topic_arn, message)
        self.assertLogs('Response', 'INFO')

    @patch('src.main.send_message_to_chatbot')
    @patch('src.main.calculate_cost')
    def test_lambda_handler(self, mock_calculate_cost, mock_send_message):
        event = {}
        context = {}
        src.main.lambda_handler(event, context)
        # Add assertions based on your specific logic and mocks
        mock_calculate_cost.assert_called()
        mock_send_message.assert_called()

if __name__ == '__main__':
    unittest.main()
