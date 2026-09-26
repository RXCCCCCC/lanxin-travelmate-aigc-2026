from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def _guest_headers(device_id: str) -> tuple[str, dict[str, str]]:
    response = client.post("/api/auth/guest", json={"deviceId": device_id, "displayName": "Dashboard Test Guest"})
    assert response.status_code == 200
    payload = response.json()
    return payload["userId"], {"Authorization": f"Bearer {payload['accessToken']}"}


def test_trip_dashboard_aggregates_persisted_trip_context():
    user_id, headers = _guest_headers(f'dashboard-user-{uuid4().hex}')
    trip_id = f'dashboard-trip-{uuid4().hex}'

    assert client.post('/api/trip/plan', json={
        'userId': user_id,
        'tripId': trip_id,
        'message': 'Plan a real weekend route.',
        'destination': 'Hangzhou',
        'preferences': ['night view'],
    }, headers=headers).status_code == 200
    assert client.post('/api/trip/route-points', json={
        'userId': user_id,
        'tripId': trip_id,
        'points': [
            {'label': 'Hotel', 'latitude': 30.25, 'longitude': 120.16},
            {'label': 'West Lake', 'latitude': 30.24, 'longitude': 120.15},
        ],
    }, headers=headers).status_code == 200
    assert client.post('/api/trip/reminders/trigger', json={
        'userId': user_id,
        'tripId': trip_id,
        'triggerType': 'location',
        'location': 'West Lake',
    }, headers=headers).status_code == 200
    assert client.post('/api/trip/blind-box/tasks/task-photo-night/status', json={
        'userId': user_id,
        'tripId': trip_id,
        'status': 'completed',
    }, headers=headers).status_code == 200
    assert client.post('/api/trip/avatar-state/events', json={
        'userId': user_id,
        'tripId': trip_id,
        'eventType': 'memory_confirmed',
        'title': 'Confirmed night-view memory',
        'deltas': {'rapport': 2},
    }, headers=headers).status_code == 200
    review = client.post(
        '/api/trip/review',
        json={'userId': user_id, 'tripId': trip_id},
        headers=headers,
    )
    assert review.status_code == 200

    dashboard = client.get(
        '/api/trip/dashboard',
        params={'userId': user_id, 'tripId': trip_id},
        headers=headers,
    )

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
    owner_id, owner_headers = _guest_headers(f'dashboard-owner-{uuid4().hex}')
    stranger_id, stranger_headers = _guest_headers(f'dashboard-stranger-{uuid4().hex}')
    assert client.post('/api/trip/plan', json={
        'userId': owner_id,
        'tripId': trip_id,
        'message': 'Plan private trip.',
        'destination': 'Private Destination',
    }, headers=owner_headers).status_code == 200

    dashboard = client.get(
        '/api/trip/dashboard',
        params={'userId': stranger_id, 'tripId': trip_id},
        headers=stranger_headers,
    )

    assert dashboard.status_code == 200
    payload = dashboard.json()
    assert payload['currentTrip']['status'] == 'empty'
    assert payload['currentTrip'].get('destination') is None


def test_trip_dashboard_uses_default_current_trip_for_unplanned_photo_flow():
    user_id, headers = _guest_headers(f'dashboard-default-device-{uuid4().hex}')
    trip_id = f'current-{user_id}-trip'

    task = client.post('/api/trip/blind-box/tasks/task-photo-night/status', json={
        'userId': user_id,
        'tripId': trip_id,
        'status': 'completed',
    }, headers=headers)
    assert task.status_code == 200
    photo = client.post('/api/photo/candidates', json={
        'id': f'dashboard-default-photo-{uuid4().hex}',
        'userId': user_id,
        'tripId': trip_id,
        'remoteUrl': 'https://cdn.example.test/default-photo.jpg',
        'location': '默认行程旅拍',
        'score': 8.8,
        'description': '默认行程下上传的旅拍',
        'tags': ['旅拍'],
        'canAddToReview': True,
    }, headers=headers)
    assert photo.status_code == 200

    dashboard = client.get('/api/trip/dashboard', params={'userId': user_id}, headers=headers)

    assert dashboard.status_code == 200
    payload = dashboard.json()
    assert payload['tripId'] == trip_id
    assert payload['currentTrip']['tripId'] == trip_id
    assert any(item['id'] == 'task-photo-night' and item['status'] == 'completed' for item in payload['blindBoxTasks']['items'])
    assert any(item['location'] == '默认行程旅拍' for item in payload['photoCandidates']['items'])
