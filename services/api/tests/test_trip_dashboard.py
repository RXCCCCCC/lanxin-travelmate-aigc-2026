from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_trip_dashboard_aggregates_persisted_trip_context():
    user_id = f'dashboard-user-{uuid4().hex}'
    trip_id = f'dashboard-trip-{uuid4().hex}'

    assert client.post('/api/trip/plan', json={
        'userId': user_id,
        'tripId': trip_id,
        'message': 'Plan a real weekend route.',
        'destination': 'Hangzhou',
        'preferences': ['night view'],
    }).status_code == 200
    assert client.post('/api/trip/route-points', json={
        'userId': user_id,
        'tripId': trip_id,
        'points': [
            {'label': 'Hotel', 'latitude': 30.25, 'longitude': 120.16},
            {'label': 'West Lake', 'latitude': 30.24, 'longitude': 120.15},
        ],
    }).status_code == 200
    assert client.post('/api/trip/reminders/trigger', json={
        'userId': user_id,
        'tripId': trip_id,
        'triggerType': 'location',
        'location': 'West Lake',
    }).status_code == 200
    assert client.post('/api/trip/blind-box/tasks/task-photo-night/status', json={
        'userId': user_id,
        'tripId': trip_id,
        'status': 'completed',
    }).status_code == 200
    assert client.post('/api/trip/avatar-state/events', json={
        'userId': user_id,
        'tripId': trip_id,
        'eventType': 'memory_confirmed',
        'title': 'Confirmed night-view memory',
        'deltas': {'rapport': 2},
    }).status_code == 200
    review = client.post('/api/trip/review', json={'userId': user_id, 'tripId': trip_id})
    assert review.status_code == 200

    dashboard = client.get('/api/trip/dashboard', params={'userId': user_id, 'tripId': trip_id})

    assert dashboard.status_code == 200
    payload = dashboard.json()
    assert payload['currentTrip']['tripId'] == trip_id
    route_text = payload['routePoints']['route']
    assert route_text.index('Hotel') < route_text.index('West Lake')
    assert payload['latestReview']['reviewId'] == review.json()['reviewId']
    assert payload['reminderHistory']['items']
    assert any(item['id'] == 'task-photo-night' and item['status'] == 'completed' for item in payload['blindBoxTasks']['items'])
    assert any(item['eventType'] == 'memory_confirmed' for item in payload['avatarStateEvents']['items'])


def test_trip_dashboard_does_not_expose_other_users_trip():
    trip_id = f'dashboard-private-trip-{uuid4().hex}'
    owner_id = f'dashboard-owner-{uuid4().hex}'
    stranger_id = f'dashboard-stranger-{uuid4().hex}'
    assert client.post('/api/trip/plan', json={
        'userId': owner_id,
        'tripId': trip_id,
        'message': 'Plan private trip.',
        'destination': 'Private Destination',
    }).status_code == 200

    dashboard = client.get('/api/trip/dashboard', params={'userId': stranger_id, 'tripId': trip_id})

    assert dashboard.status_code == 200
    payload = dashboard.json()
    assert payload['currentTrip']['status'] == 'empty'
    assert payload['currentTrip'].get('destination') is None
