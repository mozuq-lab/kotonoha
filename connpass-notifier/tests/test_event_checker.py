"""
Unit tests for event-checker Lambda function
"""

import json
import os
import sys
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock, patch, Mock

import pytest

# Add parent directory to path
event_checker_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../functions/event-checker'))
sys.path.insert(0, event_checker_path)


# Mock environment variables before importing app
@pytest.fixture(autouse=True)
def mock_env():
    """Mock environment variables for all tests"""
    with patch.dict(os.environ, {
        'AWS_DEFAULT_REGION': 'ap-northeast-1',
        'EVENTS_TABLE_NAME': 'test-events-table',
        'CONNPASS_USER_ID': 'test-user',
        'NOTIFICATION_EMAIL': 'test@example.com',
        'SENDER_EMAIL': 'sender@example.com'
    }):
        yield


from app import lambda_handler, parse_datetime, parse_event_item


class TestParseDatetime:
    """Tests for parse_datetime function"""
    
    def test_iso_format(self):
        """Test parsing ISO format datetime"""
        result = parse_datetime('2024-12-05T19:00:00+09:00')
        assert result is not None
        assert result.year == 2024
        assert result.month == 12
        assert result.day == 5
        
    def test_japanese_format_with_weekday(self):
        """Test parsing Japanese format with weekday"""
        result = parse_datetime('2024/12/05(木) 19:00')
        assert result is not None
        assert result.year == 2024
        assert result.month == 12
        assert result.day == 5
        # JST 19:00 = UTC 10:00 (JST is UTC+9)
        assert result.hour == 10
        assert result.minute == 0
        assert result.tzinfo == timezone.utc
        
    def test_invalid_format(self):
        """Test parsing invalid datetime format"""
        result = parse_datetime('invalid datetime')
        assert result is None


class TestParseEventItem:
    """Tests for parse_event_item function"""
    
    def test_valid_event_item(self):
        """Test parsing a valid event item"""
        from bs4 import BeautifulSoup
        
        # Use a simple future date that parse_datetime can handle
        html = """
        <div class="event_list">
            <a href="/event/123456/" class="event_title">テストイベント</a>
            <time datetime="2025-12-10 19:00">2025/12/10(水) 19:00</time>
            <span class="event_place">東京</span>
        </div>
        """
        
        soup = BeautifulSoup(html, 'html.parser')
        item = soup.find('div', class_='event_list')
        
        result = parse_event_item(item)
            
        assert result is not None
        assert result['event_id'] == '123456'
        assert result['title'] == 'テストイベント'
        assert '/event/123456/' in result['url']
        assert result['location'] == '東京'


@patch('app.get_table')
class TestLambdaHandler:
    """Tests for lambda_handler function"""
    
    @patch('app.get_user_events')
    @patch('app.store_event')
    def test_successful_execution(self, mock_store, mock_get_events, mock_get_table):
        """Test successful lambda execution"""
        # Mock table
        mock_table = Mock()
        mock_get_table.return_value = mock_table
        
        # Mock event data
        mock_events = [
            {
                'event_id': '123456',
                'title': 'Test Event',
                'url': 'https://connpass.com/event/123456/',
                'datetime': (datetime.now() + timedelta(days=7)).isoformat(),
                'location': 'Tokyo',
            }
        ]
        mock_get_events.return_value = mock_events
        
        # Execute lambda
        response = lambda_handler({}, None)
        
        # Verify
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['events_found'] == 1
        assert body['events_stored'] == 1
        
        # Verify store_event was called
        assert mock_store.call_count == 1
        
    def test_missing_user_id(self, mock_get_table):
        """Test error when CONNPASS_USER_ID is not set"""
        with patch.dict(os.environ, {}, clear=True):
            with patch.dict(os.environ, {'EVENTS_TABLE_NAME': 'test-table'}):
                response = lambda_handler({}, None)
        
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert 'error' in body
