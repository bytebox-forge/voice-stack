#!/usr/bin/env python3
"""
Element Web Client End-to-End Tests
Comprehensive test suite for Element Web client functionality using Playwright
"""

import pytest
import asyncio
import os
import tempfile
from pathlib import Path
from typing import Dict, Any, Optional
from dataclasses import dataclass
import json

try:
    from playwright.async_api import async_playwright, Page, Browser, BrowserContext
except ImportError:
    pytest.skip("Playwright not installed", allow_module_level=True)


@dataclass
class TestConfig:
    """Test configuration from environment variables"""
    element_url: str = os.getenv('ELEMENT_URL', 'http://localhost:8080')
    synapse_url: str = os.getenv('SYNAPSE_URL', 'http://localhost:8008')
    server_name: str = os.getenv('SYNAPSE_SERVER_NAME', 'matrix.byte-box.org')
    test_user_password: str = os.getenv('TEST_USER_PASSWORD', 'TestPassword123!')
    headless: bool = os.getenv('HEADLESS', 'true').lower() == 'true'
    slow_mo: int = int(os.getenv('SLOW_MO', '100'))  # Slow down for debugging


class ElementWebTester:
    """Helper class for Element Web testing"""
    
    def __init__(self, page: Page, config: TestConfig):
        self.page = page
        self.config = config
    
    async def wait_for_element(self, selector: str, timeout: int = 10000):
        """Wait for element with timeout"""
        return await self.page.wait_for_selector(selector, timeout=timeout)
    
    async def login_user(self, username: str, password: str):
        """Login user to Element Web"""
        # Navigate to Element
        await self.page.goto(self.config.element_url)
        
        # Wait for login form
        await self.wait_for_element('[data-testid="login"]', timeout=20000)
        
        # Configure custom homeserver
        custom_server_btn = self.page.locator('text="Edit"').or_(self.page.locator('text="Change"'))
        if await custom_server_btn.count() > 0:
            await custom_server_btn.click()
            await self.page.fill('[placeholder*="homeserver"]', self.config.synapse_url)
            await self.page.click('text="Continue"')
        
        # Fill login form
        await self.page.fill('[data-testid="username"]', username)
        await self.page.fill('[data-testid="password"]', password)
        
        # Submit login
        await self.page.click('[data-testid="login"]')
        
        # Wait for successful login (room list or welcome screen)
        await self.page.wait_for_selector('.mx_RoomList', timeout=30000)
    
    async def create_room(self, room_name: str, room_topic: str = None) -> str:
        """Create a new room and return room ID"""
        # Click create room button
        await self.page.click('[aria-label="Create room"]')
        
        # Wait for create room dialog
        await self.wait_for_element('.mx_CreateRoomDialog')
        
        # Fill room details
        await self.page.fill('input[placeholder*="name"]', room_name)
        
        if room_topic:
            await self.page.fill('input[placeholder*="topic"]', room_topic)
        
        # Create room
        await self.page.click('text="Create Room"')
        
        # Wait for room to be created and selected
        await self.page.wait_for_selector('.mx_RoomHeader_nametext', timeout=10000)
        
        # Get room ID from URL
        room_id = await self.page.evaluate("""
            () => {
                const url = window.location.hash;
                const match = url.match(/#\/room\/([^\/\?]+)/);
                return match ? decodeURIComponent(match[1]) : null;
            }
        """)
        
        return room_id
    
    async def send_message(self, message: str):
        """Send a message in the current room"""
        # Wait for message composer
        composer = await self.wait_for_element('.mx_MessageComposer_input')
        
        # Type and send message
        await composer.fill(message)
        await self.page.keyboard.press('Enter')
        
        # Wait for message to appear
        await self.page.wait_for_selector(f'text="{message}"', timeout=5000)
    
    async def wait_for_message(self, message: str, timeout: int = 10000):
        """Wait for a specific message to appear"""
        await self.page.wait_for_selector(f'text="{message}"', timeout=timeout)
    
    async def upload_file(self, file_path: str):
        """Upload a file to the current room"""
        # Click upload button
        await self.page.click('[aria-label="Upload"]')
        
        # Upload file
        await self.page.set_input_files('input[type="file"]', file_path)
        
        # Wait for upload to complete and message to appear
        filename = Path(file_path).name
        await self.page.wait_for_selector(f'text="{filename}"', timeout=15000)
    
    async def join_room_by_id(self, room_id: str):
        """Join a room by its ID"""
        # Open room directory
        await self.page.click('[aria-label="Explore rooms"]')
        
        # Search for room ID
        await self.page.fill('input[placeholder*="Search"]', room_id)
        await self.page.keyboard.press('Enter')
        
        # Join room
        await self.page.click('text="Join"')
        
        # Wait for room to load
        await self.page.wait_for_selector('.mx_RoomHeader_nametext', timeout=10000)
    
    async def invite_user(self, user_id: str):
        """Invite a user to the current room"""
        # Click room info
        await self.page.click('[aria-label="Room info"]')
        
        # Click invite users
        await self.page.click('text="Invite users"')
        
        # Type user ID
        await self.page.fill('input[placeholder*="User ID"]', user_id)
        
        # Send invitation
        await self.page.click('text="Invite"')
        
        # Close dialog
        await self.page.keyboard.press('Escape')


@pytest.fixture(scope="session")
def config():
    """Test configuration"""
    return TestConfig()


@pytest.fixture(scope="session")
async def browser():
    """Playwright browser instance"""
    playwright = await async_playwright().start()
    browser = await playwright.chromium.launch(
        headless=TestConfig().headless,
        slow_mo=TestConfig().slow_mo
    )
    yield browser
    await browser.close()
    await playwright.stop()


@pytest.fixture
async def context(browser: Browser):
    """Browser context with permissions"""
    context = await browser.new_context(
        permissions=['microphone', 'camera'],
        viewport={'width': 1280, 'height': 720}
    )
    yield context
    await context.close()


@pytest.fixture
async def page(context: BrowserContext):
    """Page instance"""
    page = await context.new_page()
    yield page
    await page.close()


class TestElementWeb:
    """Test suite for Element Web client functionality"""
    
    async def test_element_web_loads(self, page: Page, config: TestConfig):
        """Test Element Web loads successfully"""
        await page.goto(config.element_url)
        
        # Wait for Element to load
        await page.wait_for_selector('.mx_MatrixChat', timeout=30000)
        
        # Check for login form or main interface
        login_form = page.locator('[data-testid="login"]')
        main_interface = page.locator('.mx_RoomList')
        
        assert await login_form.count() > 0 or await main_interface.count() > 0
    
    async def test_custom_homeserver_configuration(self, page: Page, config: TestConfig):
        """Test configuring custom homeserver"""
        tester = ElementWebTester(page, config)
        
        await page.goto(config.element_url)
        await tester.wait_for_element('[data-testid="login"]', timeout=20000)
        
        # Configure custom homeserver
        edit_btn = page.locator('text="Edit"').or_(page.locator('text="Change"'))
        if await edit_btn.count() > 0:
            await edit_btn.click()
            
            homeserver_input = await tester.wait_for_element('[placeholder*="homeserver"]')
            await homeserver_input.fill(config.synapse_url)
            
            await page.click('text="Continue"')
            
            # Verify homeserver was set
            current_url = await homeserver_input.input_value()
            assert config.synapse_url in current_url
    
    async def test_user_login(self, page: Page, config: TestConfig):
        """Test user login functionality"""
        tester = ElementWebTester(page, config)
        
        # Login with test user
        await tester.login_user("test_alice", config.test_user_password)
        
        # Verify successful login
        await tester.wait_for_element('.mx_RoomList')
        
        # Check user is logged in (user menu should be visible)
        user_menu = page.locator('[aria-label="User menu"]')
        assert await user_menu.count() > 0
    
    async def test_room_creation(self, page: Page, config: TestConfig):
        """Test room creation"""
        tester = ElementWebTester(page, config)
        
        await tester.login_user("test_alice", config.test_user_password)
        
        # Create room
        room_name = "Test Room E2E"
        room_topic = "Room created by E2E test"
        room_id = await tester.create_room(room_name, room_topic)
        
        assert room_id is not None
        assert room_id.startswith("!")
        assert room_id.endswith(f":{config.server_name}")
        
        # Verify room name appears in header
        room_header = await tester.wait_for_element('.mx_RoomHeader_nametext')
        header_text = await room_header.text_content()
        assert room_name in header_text
    
    async def test_message_sending(self, page: Page, config: TestConfig):
        """Test sending messages"""
        tester = ElementWebTester(page, config)
        
        await tester.login_user("test_alice", config.test_user_password)
        await tester.create_room("Message Test Room")
        
        # Send test message
        test_message = "Hello from Element Web E2E test!"
        await tester.send_message(test_message)
        
        # Verify message appears in timeline
        message_element = page.locator(f'text="{test_message}"')
        assert await message_element.count() > 0
    
    async def test_file_upload(self, page: Page, config: TestConfig):
        """Test file upload functionality"""
        tester = ElementWebTester(page, config)
        
        await tester.login_user("test_alice", config.test_user_password)
        await tester.create_room("File Upload Test")
        
        # Create temporary test file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write("Test file content for Element Web E2E test")
            temp_file = f.name
        
        try:
            # Upload file
            await tester.upload_file(temp_file)
            
            # Verify file appears in timeline
            filename = Path(temp_file).name
            file_element = page.locator(f'text="{filename}"')
            assert await file_element.count() > 0
            
        finally:
            os.unlink(temp_file)
    
    async def test_room_settings(self, page: Page, config: TestConfig):
        """Test room settings modification"""
        tester = ElementWebTester(page, config)
        
        await tester.login_user("test_alice", config.test_user_password)
        await tester.create_room("Settings Test Room")
        
        # Open room settings
        await page.click('[aria-label="Room info"]')
        await tester.wait_for_element('.mx_RoomSummaryCard')
        
        # Check room info is displayed
        room_info = page.locator('.mx_RoomSummaryCard')
        assert await room_info.count() > 0
        
        # Test room name editing
        await page.click('text="Settings"')
        await tester.wait_for_element('.mx_RoomSettingsDialog')
        
        # Verify settings dialog opened
        settings_dialog = page.locator('.mx_RoomSettingsDialog')
        assert await settings_dialog.count() > 0
    
    async def test_user_profile(self, page: Page, config: TestConfig):
        """Test user profile functionality"""
        tester = ElementWebTester(page, config)
        
        await tester.login_user("test_alice", config.test_user_password)
        
        # Open user menu
        await page.click('[aria-label="User menu"]')
        
        # Open user settings
        await page.click('text="All settings"')
        
        # Wait for settings dialog
        await tester.wait_for_element('.mx_UserSettingsDialog')
        
        # Verify profile section exists
        profile_section = page.locator('text="Profile"')
        assert await profile_section.count() > 0
    
    async def test_room_member_list(self, page: Page, config: TestConfig):
        """Test room member list functionality"""
        tester = ElementWebTester(page, config)
        
        await tester.login_user("test_alice", config.test_user_password)
        await tester.create_room("Member List Test")
        
        # Open room info
        await page.click('[aria-label="Room info"]')
        
        # Check member list
        await page.click('text="People"')
        
        # Verify user appears in member list
        member_list = await tester.wait_for_element('.mx_MemberList')
        member_text = await member_list.text_content()
        assert "test_alice" in member_text
    
    async def test_logout(self, page: Page, config: TestConfig):
        """Test user logout"""
        tester = ElementWebTester(page, config)
        
        await tester.login_user("test_alice", config.test_user_password)
        
        # Open user menu
        await page.click('[aria-label="User menu"]')
        
        # Click sign out
        await page.click('text="Sign out"')
        
        # Wait for login screen
        await tester.wait_for_element('[data-testid="login"]')
        
        # Verify back at login screen
        login_form = page.locator('[data-testid="login"]')
        assert await login_form.count() > 0
    
    @pytest.mark.asyncio
    async def test_two_user_conversation(self, browser: Browser, config: TestConfig):
        """Test conversation between two users"""
        # Create two browser contexts for two users
        context1 = await browser.new_context(viewport={'width': 1280, 'height': 720})
        context2 = await browser.new_context(viewport={'width': 1280, 'height': 720})
        
        page1 = await context1.new_page()
        page2 = await context2.new_page()
        
        tester1 = ElementWebTester(page1, config)
        tester2 = ElementWebTester(page2, config)
        
        try:
            # Both users login
            await tester1.login_user("test_alice", config.test_user_password)
            await tester2.login_user("test_bob", config.test_user_password)
            
            # Alice creates room and invites Bob
            room_id = await tester1.create_room("Two User Test Room")
            await tester1.invite_user(f"@test_bob:{config.server_name}")
            
            # Bob accepts invitation (should appear in room list)
            await page2.wait_for_selector(f'text="Two User Test Room"', timeout=10000)
            await page2.click('text="Two User Test Room"')
            
            # Alice sends message
            alice_message = "Hello Bob from Alice!"
            await tester1.send_message(alice_message)
            
            # Bob should see Alice's message
            await tester2.wait_for_message(alice_message)
            
            # Bob replies
            bob_message = "Hello Alice from Bob!"
            await tester2.send_message(bob_message)
            
            # Alice should see Bob's reply
            await tester1.wait_for_message(bob_message)
            
        finally:
            await page1.close()
            await page2.close()
            await context1.close()
            await context2.close()


class TestElementWebRealTime:
    """Real-time functionality tests"""
    
    @pytest.mark.asyncio
    async def test_real_time_messaging(self, browser: Browser, config: TestConfig):
        """Test real-time message synchronization"""
        context1 = await browser.new_context()
        context2 = await browser.new_context()
        
        page1 = await context1.new_page()
        page2 = await context2.new_page()
        
        tester1 = ElementWebTester(page1, config)
        tester2 = ElementWebTester(page2, config)
        
        try:
            await tester1.login_user("test_alice", config.test_user_password)
            await tester2.login_user("test_bob", config.test_user_password)
            
            # Create shared room
            room_id = await tester1.create_room("Real-time Test Room")
            await tester1.invite_user(f"@test_bob:{config.server_name}")
            
            # Bob joins
            await page2.wait_for_selector('text="Real-time Test Room"', timeout=10000)
            await page2.click('text="Real-time Test Room"')
            
            # Send multiple messages quickly
            messages = [
                "Message 1 - Real-time test",
                "Message 2 - Real-time test", 
                "Message 3 - Real-time test"
            ]
            
            for i, message in enumerate(messages):
                if i % 2 == 0:
                    await tester1.send_message(message)
                    # Bob should see it immediately
                    await tester2.wait_for_message(message, timeout=5000)
                else:
                    await tester2.send_message(message)
                    # Alice should see it immediately
                    await tester1.wait_for_message(message, timeout=5000)
                    
        finally:
            await page1.close()
            await page2.close()
            await context1.close()
            await context2.close()


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])