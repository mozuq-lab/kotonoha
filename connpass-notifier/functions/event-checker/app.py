"""
Event Checker Lambda Function

This function checks a user's connpass page for upcoming events
and stores them in DynamoDB.

Note: All times are stored in UTC and converted from JST when parsing.
"""

import json
import os
import re
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional
from urllib.parse import urljoin

import boto3
import requests
from bs4 import BeautifulSoup

# Timezone for Japan (JST = UTC+9)
JST = timezone(timedelta(hours=9))

# Configuration
CONNPASS_BASE_URL = 'https://connpass.com'
USER_AGENT = 'Mozilla/5.0 (compatible; ConnpassNotifier/1.0)'

# AWS clients (initialized lazily)
_dynamodb = None
_table = None


def get_table():
    """Get DynamoDB table instance (lazy initialization)."""
    global _dynamodb, _table
    if _table is None:
        _dynamodb = boto3.resource('dynamodb')
        _table = _dynamodb.Table(os.environ.get('EVENTS_TABLE_NAME', 'connpass-events'))
    return _table


def get_user_events(user_id: str) -> List[Dict]:
    """
    Fetch events from a connpass user's page.
    
    Args:
        user_id: Connpass user ID
        
    Returns:
        List of event dictionaries
    """
    events = []
    user_url = f'{CONNPASS_BASE_URL}/user/{user_id}/'
    
    try:
        response = requests.get(
            user_url,
            headers={'User-Agent': USER_AGENT},
            timeout=10
        )
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Find event items on the user's page
        event_items = soup.find_all('div', class_='event_list')
        
        for item in event_items:
            try:
                event = parse_event_item(item)
                if event:
                    events.append(event)
            except Exception as e:
                print(f"Error parsing event item: {e}")
                continue
                
    except requests.RequestException as e:
        print(f"Error fetching connpass page: {e}")
        raise
        
    return events


def parse_event_item(item) -> Optional[Dict]:
    """
    Parse an event item from connpass HTML.
    
    Args:
        item: BeautifulSoup element containing event information
        
    Returns:
        Event dictionary or None if parsing fails
    """
    try:
        # Extract event URL
        title_elem = item.find('a', class_='event_title')
        if not title_elem:
            return None
            
        event_url = title_elem.get('href', '')
        event_title = title_elem.get_text(strip=True)
        
        # Extract event ID from URL
        event_id_match = re.search(r'/event/(\d+)/', event_url)
        if not event_id_match:
            return None
        event_id = event_id_match.group(1)
        
        # Extract event date and time
        date_elem = item.find('time')
        if not date_elem:
            return None
            
        event_datetime_str = date_elem.get('datetime', '')
        if not event_datetime_str:
            event_datetime_str = date_elem.get_text(strip=True)
            
        # Parse datetime
        event_datetime = parse_datetime(event_datetime_str)
        if not event_datetime:
            return None
            
        # Only return future events (compare in UTC)
        now_utc = datetime.now(timezone.utc)
        if event_datetime < now_utc:
            return None
            
        # Extract location (if available)
        location_elem = item.find('span', class_='event_place')
        location = location_elem.get_text(strip=True) if location_elem else 'オンライン'
        
        return {
            'event_id': event_id,
            'title': event_title,
            'url': event_url if event_url.startswith('http') else urljoin(CONNPASS_BASE_URL, event_url),
            'datetime': event_datetime.isoformat(),
            'location': location,
        }
        
    except Exception as e:
        print(f"Error in parse_event_item: {e}")
        return None


def parse_datetime(datetime_str: str) -> Optional[datetime]:
    """
    Parse datetime string from connpass and convert to UTC.
    
    Args:
        datetime_str: Datetime string
        
    Returns:
        Datetime object in UTC or None
    """
    # Try ISO format first
    try:
        dt = datetime.fromisoformat(datetime_str.replace('Z', '+00:00'))
        # If it doesn't have timezone info, assume JST
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=JST)
        return dt.astimezone(timezone.utc)
    except (ValueError, AttributeError):
        pass
    
    # Try Japanese format: 2024/12/05(木) 19:00
    # These are in JST
    patterns = [
        r'(\d{4})/(\d{1,2})/(\d{1,2})\([月火水木金土日]\)\s+(\d{1,2}):(\d{2})',
        r'(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{2})',
        r'(\d{4})/(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})',
    ]
    
    for pattern in patterns:
        match = re.search(pattern, datetime_str)
        if match:
            year, month, day, hour, minute = match.groups()
            # Create datetime in JST and convert to UTC
            dt_jst = datetime(
                int(year), int(month), int(day),
                int(hour), int(minute),
                tzinfo=JST
            )
            return dt_jst.astimezone(timezone.utc)
    
    return None


def store_event(event: Dict) -> None:
    """
    Store event in DynamoDB.
    
    Args:
        event: Event dictionary
    """
    table = get_table()
    
    # Calculate TTL (30 days after event date)
    event_datetime = datetime.fromisoformat(event['datetime'])
    ttl = int((event_datetime + timedelta(days=30)).timestamp())
    
    item = {
        'event_id': event['event_id'],
        'event_date': event['datetime'],  # Already in UTC ISO format
        'title': event['title'],
        'url': event['url'],
        'location': event['location'],
        'notified': False,
        'created_at': datetime.now(timezone.utc).isoformat(),
        'ttl': ttl,
    }
    
    try:
        table.put_item(Item=item)
        print(f"Stored event: {event['title']}")
    except Exception as e:
        print(f"Error storing event in DynamoDB: {e}")
        raise


def lambda_handler(event, context):
    """
    Lambda handler function.
    
    Args:
        event: Lambda event object
        context: Lambda context object
        
    Returns:
        Response dictionary
    """
    user_id = os.environ.get('CONNPASS_USER_ID')
    
    if not user_id:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': 'CONNPASS_USER_ID environment variable not set'
            })
        }
    
    try:
        # Fetch events from connpass
        events = get_user_events(user_id)
        
        # Store events in DynamoDB
        stored_count = 0
        for event in events:
            try:
                store_event(event)
                stored_count += 1
            except Exception as e:
                print(f"Failed to store event {event.get('event_id')}: {e}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Events checked successfully',
                'events_found': len(events),
                'events_stored': stored_count,
            })
        }
        
    except Exception as e:
        print(f"Error in lambda_handler: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
