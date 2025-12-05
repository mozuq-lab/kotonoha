"""
Email Notifier Lambda Function

This function checks for upcoming events in DynamoDB and sends
email notifications before they start.

Note: All times are stored in UTC. Event times are converted to JST for display in emails.
"""

import json
import os
from datetime import datetime, timedelta, timezone
from typing import Dict, List

import boto3
from boto3.dynamodb.conditions import Attr

# Timezone for Japan (JST = UTC+9)
JST = timezone(timedelta(hours=9))

# Configuration
NOTIFICATION_HOURS_BEFORE = int(os.environ.get('NOTIFICATION_HOURS_BEFORE', 24))
SENDER_EMAIL = os.environ.get('SENDER_EMAIL', '')
NOTIFICATION_EMAIL = os.environ.get('NOTIFICATION_EMAIL', '')

# AWS clients (initialized lazily)
_dynamodb = None
_table = None
_ses = None


def get_table():
    """Get DynamoDB table instance (lazy initialization)."""
    global _dynamodb, _table
    if _table is None:
        _dynamodb = boto3.resource('dynamodb')
        _table = _dynamodb.Table(os.environ.get('EVENTS_TABLE_NAME', 'connpass-events'))
    return _table


def get_ses_client():
    """Get SES client instance (lazy initialization)."""
    global _ses
    if _ses is None:
        _ses = boto3.client('ses')
    return _ses


def get_upcoming_events() -> List[Dict]:
    """
    Fetch upcoming events that haven't been notified yet.
    
    Returns:
        List of event dictionaries
    """
    table = get_table()
    now = datetime.now(timezone.utc)
    notification_window_start = now
    notification_window_end = now + timedelta(hours=NOTIFICATION_HOURS_BEFORE + 1)
    
    try:
        # Scan for events that:
        # 1. Haven't been notified yet
        # 2. Are within the notification window
        response = table.scan(
            FilterExpression=Attr('notified').eq(False) &
                           Attr('event_date').gte(notification_window_start.isoformat()) &
                           Attr('event_date').lte(notification_window_end.isoformat())
        )
        
        events = response.get('Items', [])
        
        # Filter events that need notification
        events_to_notify = []
        for event in events:
            # Parse event datetime (stored in UTC)
            event_datetime_str = event['event_date']
            try:
                event_datetime = datetime.fromisoformat(event_datetime_str)
                if event_datetime.tzinfo is None:
                    event_datetime = event_datetime.replace(tzinfo=timezone.utc)
            except (ValueError, AttributeError):
                continue
                
            time_until_event = event_datetime - now
            
            # Notify if event is within notification window
            if timedelta(0) <= time_until_event <= timedelta(hours=NOTIFICATION_HOURS_BEFORE):
                events_to_notify.append(event)
        
        return events_to_notify
        
    except Exception as e:
        print(f"Error fetching events from DynamoDB: {e}")
        raise


def send_email_notification(events: List[Dict]) -> None:
    """
    Send email notification for upcoming events.
    
    Args:
        events: List of event dictionaries
    """
    if not events:
        return
    
    ses = get_ses_client()
    
    # Build email body
    subject = f"【connpass】{len(events)}件の参加予定イベントが近づいています"
    
    body_parts = [
        "以下のイベントが近づいています：\n",
    ]
    
    for event in events:
        event_datetime = datetime.fromisoformat(event['event_date'])
        if event_datetime.tzinfo is None:
            event_datetime = event_datetime.replace(tzinfo=timezone.utc)
        
        # Convert to JST for display
        event_datetime_jst = event_datetime.astimezone(JST)
        time_until = event_datetime - datetime.now(timezone.utc)
        hours_until = int(time_until.total_seconds() / 3600)
        
        body_parts.append(f"\n【{event['title']}】")
        body_parts.append(f"日時: {event_datetime_jst.strftime('%Y年%m月%d日 %H:%M')} (JST)")
        body_parts.append(f"開始まで: 約{hours_until}時間")
        body_parts.append(f"場所: {event['location']}")
        body_parts.append(f"URL: {event['url']}")
        body_parts.append("-" * 50)
    
    body_parts.append("\n\nこのメールは自動送信されています。")
    
    body_text = "\n".join(body_parts)
    
    # Create HTML version
    html_parts = [
        "<html><body>",
        "<h2>以下のイベントが近づいています</h2>",
    ]
    
    for event in events:
        event_datetime = datetime.fromisoformat(event['event_date'])
        if event_datetime.tzinfo is None:
            event_datetime = event_datetime.replace(tzinfo=timezone.utc)
        
        # Convert to JST for display
        event_datetime_jst = event_datetime.astimezone(JST)
        time_until = event_datetime - datetime.now(timezone.utc)
        hours_until = int(time_until.total_seconds() / 3600)
        
        html_parts.append("<div style='margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px;'>")
        html_parts.append(f"<h3>{event['title']}</h3>")
        html_parts.append(f"<p><strong>日時:</strong> {event_datetime_jst.strftime('%Y年%m月%d日 %H:%M')} (JST)</p>")
        html_parts.append(f"<p><strong>開始まで:</strong> 約{hours_until}時間</p>")
        html_parts.append(f"<p><strong>場所:</strong> {event['location']}</p>")
        html_parts.append(f"<p><a href='{event['url']}' style='color: #0066cc;'>イベントページを見る</a></p>")
        html_parts.append("</div>")
    
    html_parts.append("<p style='color: #666; font-size: 12px; margin-top: 30px;'>")
    html_parts.append("このメールは自動送信されています。")
    html_parts.append("</p>")
    html_parts.append("</body></html>")
    
    body_html = "\n".join(html_parts)
    
    try:
        # Send email via SES
        response = ses.send_email(
            Source=SENDER_EMAIL,
            Destination={
                'ToAddresses': [NOTIFICATION_EMAIL],
            },
            Message={
                'Subject': {
                    'Data': subject,
                    'Charset': 'UTF-8',
                },
                'Body': {
                    'Text': {
                        'Data': body_text,
                        'Charset': 'UTF-8',
                    },
                    'Html': {
                        'Data': body_html,
                        'Charset': 'UTF-8',
                    },
                },
            },
        )
        
        print(f"Email sent successfully. MessageId: {response['MessageId']}")
        
    except Exception as e:
        print(f"Error sending email via SES: {e}")
        raise


def mark_events_as_notified(events: List[Dict]) -> None:
    """
    Mark events as notified in DynamoDB.
    
    Args:
        events: List of event dictionaries
    """
    table = get_table()
    for event in events:
        try:
            table.update_item(
                Key={
                    'event_id': event['event_id'],
                    'event_date': event['event_date'],
                },
                UpdateExpression='SET notified = :notified, notified_at = :notified_at',
                ExpressionAttributeValues={
                    ':notified': True,
                    ':notified_at': datetime.now(timezone.utc).isoformat(),
                },
            )
            print(f"Marked event as notified: {event['title']}")
        except Exception as e:
            print(f"Error marking event {event['event_id']} as notified: {e}")


def lambda_handler(event, context):
    """
    Lambda handler function.
    
    Args:
        event: Lambda event object
        context: Lambda context object
        
    Returns:
        Response dictionary
    """
    try:
        # Get upcoming events that need notification
        events_to_notify = get_upcoming_events()
        
        if not events_to_notify:
            print("No events to notify")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'No events to notify',
                    'events_checked': 0,
                })
            }
        
        # Send email notification
        send_email_notification(events_to_notify)
        
        # Mark events as notified
        mark_events_as_notified(events_to_notify)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Notifications sent successfully',
                'events_notified': len(events_to_notify),
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
