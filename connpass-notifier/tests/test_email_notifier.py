"""
Unit tests for email-notifier Lambda function
"""

import json
import os
import sys
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch, Mock

import pytest

# Add parent directory to path
email_notifier_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../functions/email-notifier'))
if email_notifier_path in sys.path:
    sys.path.remove(email_notifier_path)
sys.path.insert(0, email_notifier_path)


# Mock environment variables before importing app
@pytest.fixture(autouse=True)
def mock_env():
    """Mock environment variables for all tests"""
    with patch.dict(os.environ, {
        'AWS_DEFAULT_REGION': 'ap-northeast-1',
        'EVENTS_TABLE_NAME': 'test-events-table',
        'SENDER_EMAIL': 'sender@example.com',
        'NOTIFICATION_EMAIL': 'recipient@example.com',
        'NOTIFICATION_HOURS_BEFORE': '24'
    }):
        yield


from app import lambda_handler, get_upcoming_events


@patch('app.get_table')
@patch('app.get_ses_client')
class TestLambdaHandler:
    """Tests for lambda_handler function"""
    
    @patch('app.get_upcoming_events')
    @patch('app.send_email_notification')
    @patch('app.mark_events_as_notified')
    def test_successful_notification(self, mock_mark, mock_send, mock_get_events, 
                                    mock_get_ses, mock_get_table):
        """Test successful email notification"""
        # Mock table and SES
        mock_table = Mock()
        mock_get_table.return_value = mock_table
        mock_ses = Mock()
        mock_get_ses.return_value = mock_ses
        
        # Mock upcoming events
        event_datetime = datetime.now() + timedelta(hours=12)
        mock_events = [
            {
                'event_id': '123456',
                'event_date': event_datetime.isoformat(),
                'title': 'Test Event',
                'url': 'https://connpass.com/event/123456/',
                'location': 'Tokyo',
                'notified': False,
            }
        ]
        mock_get_events.return_value = mock_events
        
        # Execute lambda
        response = lambda_handler({}, None)
        
        # Verify
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['events_notified'] == 1
        
        # Verify functions were called
        mock_send.assert_called_once_with(mock_events)
        mock_mark.assert_called_once_with(mock_events)
        
    @patch('app.get_upcoming_events')
    def test_no_events_to_notify(self, mock_get_events, mock_get_ses, mock_get_table):
        """Test when there are no events to notify"""
        mock_get_events.return_value = []
        
        # Execute lambda
        response = lambda_handler({}, None)
        
        # Verify
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['events_checked'] == 0
        assert 'No events to notify' in body['message']


class TestGetUpcomingEvents:
    """Tests for get_upcoming_events function"""
    
    @patch('app.get_table')
    def test_filter_upcoming_events(self, mock_get_table):
        """Test filtering upcoming events"""
        # Mock DynamoDB table
        mock_table = Mock()
        mock_get_table.return_value = mock_table
        
        # Mock DynamoDB response
        event_datetime = datetime.now() + timedelta(hours=12)
        mock_table.scan.return_value = {
            'Items': [
                {
                    'event_id': '123456',
                    'event_date': event_datetime.isoformat(),
                    'title': 'Upcoming Event',
                    'notified': False,
                }
            ]
        }
        
        # Execute
        events = get_upcoming_events()
        
        # Verify
        assert len(events) == 1
        assert events[0]['event_id'] == '123456'
