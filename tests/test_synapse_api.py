#!/usr/bin/env python3
"""
Matrix Synapse API End-to-End Tests
Comprehensive test suite for Matrix Synapse server functionality
"""

import pytest
import requests
import json
import time
import os
import tempfile
from typing import Dict, Any, Optional
from dataclasses import dataclass
from pathlib import Path
import mimetypes


@dataclass
class TestConfig:
    """Test configuration from environment variables"""
    synapse_url: str = os.getenv('SYNAPSE_URL', 'http://localhost:8008')
    server_name: str = os.getenv('SYNAPSE_SERVER_NAME', 'matrix.byte-box.org')
    admin_token: Optional[str] = os.getenv('SYNAPSE_ADMIN_TOKEN')
    registration_secret: str = os.getenv('REGISTRATION_SHARED_SECRET', 'test_secret')
    test_user_password: str = os.getenv('TEST_USER_PASSWORD', 'TestPassword123!')


class MatrixClient:
    """Matrix client for API interactions"""
    
    def __init__(self, config: TestConfig):
        self.config = config
        self.session = requests.Session()
        self.access_token: Optional[str] = None
        self.user_id: Optional[str] = None
        
    def _api_url(self, endpoint: str) -> str:
        """Build full API URL"""
        return f"{self.config.synapse_url}/_matrix{endpoint}"
    
    def _admin_api_url(self, endpoint: str) -> str:
        """Build full admin API URL"""
        return f"{self.config.synapse_url}/_synapse/admin{endpoint}"
        
    def register_user(self, username: str, password: str, admin: bool = False) -> Dict[str, Any]:
        """Register a new user using registration shared secret"""
        import hmac
        import hashlib
        
        # Get nonce
        nonce_resp = self.session.get(self._api_url("/client/r0/admin/register"))
        nonce_resp.raise_for_status()
        nonce = nonce_resp.json()["nonce"]
        
        # Create HMAC
        mac = hmac.new(
            key=self.config.registration_secret.encode(),
            digestmod=hashlib.sha1
        )
        
        mac.update(nonce.encode())
        mac.update(b"\x00")
        mac.update(username.encode())
        mac.update(b"\x00")
        mac.update(password.encode())
        mac.update(b"\x00")
        mac.update(b"admin" if admin else b"notadmin")
        
        data = {
            "nonce": nonce,
            "username": username,
            "password": password,
            "admin": admin,
            "mac": mac.hexdigest()
        }
        
        resp = self.session.post(self._api_url("/client/r0/admin/register"), json=data)
        resp.raise_for_status()
        return resp.json()
    
    def login(self, username: str, password: str) -> Dict[str, Any]:
        """Login user and store access token"""
        data = {
            "type": "m.login.password",
            "user": username,
            "password": password
        }
        
        resp = self.session.post(self._api_url("/client/r0/login"), json=data)
        resp.raise_for_status()
        
        result = resp.json()
        self.access_token = result["access_token"]
        self.user_id = result["user_id"]
        
        # Set authorization header for future requests
        self.session.headers.update({"Authorization": f"Bearer {self.access_token}"})
        
        return result
    
    def create_room(self, name: str, topic: str = None, public: bool = False) -> Dict[str, Any]:
        """Create a new room"""
        data = {
            "name": name,
            "preset": "public_chat" if public else "private_chat",
            "visibility": "public" if public else "private"
        }
        
        if topic:
            data["topic"] = topic
            
        resp = self.session.post(self._api_url("/client/r0/createRoom"), json=data)
        resp.raise_for_status()
        return resp.json()
    
    def send_message(self, room_id: str, message: str, msg_type: str = "m.text") -> Dict[str, Any]:
        """Send message to room"""
        txn_id = int(time.time() * 1000)
        
        data = {
            "msgtype": msg_type,
            "body": message
        }
        
        resp = self.session.put(
            self._api_url(f"/client/r0/rooms/{room_id}/send/m.room.message/{txn_id}"),
            json=data
        )
        resp.raise_for_status()
        return resp.json()
    
    def get_messages(self, room_id: str, limit: int = 10) -> Dict[str, Any]:
        """Get messages from room"""
        params = {"limit": limit, "dir": "b"}
        resp = self.session.get(
            self._api_url(f"/client/r0/rooms/{room_id}/messages"),
            params=params
        )
        resp.raise_for_status()
        return resp.json()
    
    def upload_media(self, file_path: str) -> Dict[str, Any]:
        """Upload media file"""
        with open(file_path, 'rb') as f:
            content = f.read()
            
        content_type = mimetypes.guess_type(file_path)[0] or 'application/octet-stream'
        filename = Path(file_path).name
        
        resp = self.session.post(
            self._api_url("/media/r0/upload"),
            data=content,
            headers={"Content-Type": content_type},
            params={"filename": filename}
        )
        resp.raise_for_status()
        return resp.json()
    
    def download_media(self, mxc_url: str) -> bytes:
        """Download media from MXC URL"""
        # Parse mxc://server/media_id
        if not mxc_url.startswith("mxc://"):
            raise ValueError("Invalid MXC URL")
            
        parts = mxc_url[6:].split("/", 1)
        if len(parts) != 2:
            raise ValueError("Invalid MXC URL format")
            
        server_name, media_id = parts
        
        resp = self.session.get(
            self._api_url(f"/media/r0/download/{server_name}/{media_id}")
        )
        resp.raise_for_status()
        return resp.content


class TestMatrixSynapse:
    """Test suite for Matrix Synapse functionality"""
    
    @pytest.fixture(scope="class")
    def config(self):
        """Test configuration"""
        return TestConfig()
    
    @pytest.fixture(scope="class")
    def admin_client(self, config):
        """Admin client for user management"""
        client = MatrixClient(config)
        
        # Register admin user for testing
        try:
            admin_user = client.register_user("test_admin", config.test_user_password, admin=True)
            client.login("test_admin", config.test_user_password)
        except requests.HTTPError as e:
            if e.response.status_code == 400:  # User might already exist
                client.login("test_admin", config.test_user_password)
            else:
                raise
                
        return client
    
    @pytest.fixture(scope="class")
    def user_clients(self, config):
        """Create test user clients"""
        clients = []
        usernames = ["alice", "bob"]
        
        for username in usernames:
            client = MatrixClient(config)
            
            # Register user
            try:
                client.register_user(f"test_{username}", config.test_user_password)
                client.login(f"test_{username}", config.test_user_password)
            except requests.HTTPError as e:
                if e.response.status_code == 400:  # User might already exist
                    client.login(f"test_{username}", config.test_user_password)
                else:
                    raise
                    
            clients.append(client)
            
        return clients
    
    def test_server_health(self, config):
        """Test server startup and health endpoint"""
        resp = requests.get(f"{config.synapse_url}/health")
        assert resp.status_code == 200
        
        # Test federation disabled (should return 404 for federation endpoints)
        resp = requests.get(f"{config.synapse_url}/_matrix/federation/v1/version")
        assert resp.status_code == 404  # Federation should be disabled
    
    def test_server_version(self, config):
        """Test server version endpoint"""
        resp = requests.get(f"{config.synapse_url}/_matrix/client/versions")
        assert resp.status_code == 200
        
        data = resp.json()
        assert "versions" in data
        assert isinstance(data["versions"], list)
        assert len(data["versions"]) > 0
    
    def test_user_registration_admin_only(self, config):
        """Test that user registration is admin-only"""
        client = MatrixClient(config)
        
        # Direct registration should fail
        data = {
            "username": "should_fail",
            "password": "password123",
            "auth": {"type": "m.login.dummy"}
        }
        
        resp = client.session.post(client._api_url("/client/r0/register"), json=data)
        assert resp.status_code == 403  # Registration disabled
    
    def test_admin_user_registration(self, admin_client):
        """Test admin user registration and login"""
        assert admin_client.access_token is not None
        assert admin_client.user_id is not None
        assert "test_admin" in admin_client.user_id
    
    def test_room_creation(self, user_clients):
        """Test room creation"""
        alice = user_clients[0]
        
        room = alice.create_room("Test Room", "A room for testing")
        
        assert "room_id" in room
        room_id = room["room_id"]
        assert room_id.startswith("!")
        assert room_id.endswith(f":{alice.config.server_name}")
    
    def test_message_sending_receiving(self, user_clients):
        """Test message sending and receiving"""
        alice, bob = user_clients
        
        # Alice creates room
        room = alice.create_room("Message Test Room")
        room_id = room["room_id"]
        
        # Alice invites Bob
        invite_data = {"user_id": bob.user_id}
        resp = alice.session.post(
            alice._api_url(f"/client/r0/rooms/{room_id}/invite"),
            json=invite_data
        )
        assert resp.status_code == 200
        
        # Bob joins room
        resp = bob.session.post(bob._api_url(f"/client/r0/rooms/{room_id}/join"))
        assert resp.status_code == 200
        
        # Alice sends message
        test_message = "Hello from Alice!"
        msg_response = alice.send_message(room_id, test_message)
        assert "event_id" in msg_response
        
        # Wait a moment for message to propagate
        time.sleep(1)
        
        # Bob retrieves messages
        messages = bob.get_messages(room_id, limit=5)
        assert "chunk" in messages
        
        # Find the test message
        found_message = False
        for event in messages["chunk"]:
            if (event.get("type") == "m.room.message" and 
                event.get("content", {}).get("body") == test_message):
                found_message = True
                break
                
        assert found_message, "Test message not found in room history"
    
    def test_media_upload_download(self, user_clients):
        """Test media upload and download"""
        alice = user_clients[0]
        
        # Create temporary test file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write("This is a test file for media upload")
            temp_file = f.name
        
        try:
            # Upload media
            upload_result = alice.upload_media(temp_file)
            assert "content_uri" in upload_result
            
            mxc_url = upload_result["content_uri"]
            assert mxc_url.startswith("mxc://")
            
            # Download media
            downloaded_content = alice.download_media(mxc_url)
            assert b"This is a test file for media upload" in downloaded_content
            
        finally:
            # Cleanup
            os.unlink(temp_file)
    
    def test_room_media_sharing(self, user_clients):
        """Test media sharing in rooms"""
        alice, bob = user_clients
        
        # Create room and invite Bob
        room = alice.create_room("Media Test Room")
        room_id = room["room_id"]
        
        invite_data = {"user_id": bob.user_id}
        alice.session.post(alice._api_url(f"/client/r0/rooms/{room_id}/invite"), json=invite_data)
        bob.session.post(bob._api_url(f"/client/r0/rooms/{room_id}/join"))
        
        # Create temporary test file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write("Shared test file content")
            temp_file = f.name
        
        try:
            # Upload and share media
            upload_result = alice.upload_media(temp_file)
            mxc_url = upload_result["content_uri"]
            
            # Send media message
            txn_id = int(time.time() * 1000)
            media_message = {
                "msgtype": "m.file",
                "body": "test_file.txt",
                "url": mxc_url,
                "info": {
                    "mimetype": "text/plain",
                    "size": len("Shared test file content")
                }
            }
            
            resp = alice.session.put(
                alice._api_url(f"/client/r0/rooms/{room_id}/send/m.room.message/{txn_id}"),
                json=media_message
            )
            assert resp.status_code == 200
            
            # Bob can download the shared media
            downloaded_content = bob.download_media(mxc_url)
            assert b"Shared test file content" in downloaded_content
            
        finally:
            os.unlink(temp_file)
    
    def test_user_presence(self, user_clients):
        """Test user presence functionality"""
        alice = user_clients[0]
        
        # Set presence
        presence_data = {"presence": "online", "status_msg": "Testing presence"}
        resp = alice.session.put(
            alice._api_url(f"/client/r0/presence/{alice.user_id}/status"),
            json=presence_data
        )
        assert resp.status_code == 200
        
        # Get presence
        resp = alice.session.get(
            alice._api_url(f"/client/r0/presence/{alice.user_id}/status")
        )
        assert resp.status_code == 200
        
        presence = resp.json()
        assert presence["presence"] == "online"
        assert presence["status_msg"] == "Testing presence"
    
    def test_room_state_events(self, user_clients):
        """Test room state events (name, topic, avatar)"""
        alice = user_clients[0]
        
        # Create room
        room = alice.create_room("State Test Room", "Initial topic")
        room_id = room["room_id"]
        
        # Update room name
        name_data = {"name": "Updated Room Name"}
        resp = alice.session.put(
            alice._api_url(f"/client/r0/rooms/{room_id}/state/m.room.name"),
            json=name_data
        )
        assert resp.status_code == 200
        
        # Update room topic
        topic_data = {"topic": "Updated room topic"}
        resp = alice.session.put(
            alice._api_url(f"/client/r0/rooms/{room_id}/state/m.room.topic"),
            json=topic_data
        )
        assert resp.status_code == 200
        
        # Get room state
        resp = alice.session.get(alice._api_url(f"/client/r0/rooms/{room_id}/state"))
        assert resp.status_code == 200
        
        state_events = resp.json()
        
        # Check name and topic were updated
        name_event = next((e for e in state_events if e["type"] == "m.room.name"), None)
        topic_event = next((e for e in state_events if e["type"] == "m.room.topic"), None)
        
        assert name_event is not None
        assert name_event["content"]["name"] == "Updated Room Name"
        
        assert topic_event is not None
        assert topic_event["content"]["topic"] == "Updated room topic"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])