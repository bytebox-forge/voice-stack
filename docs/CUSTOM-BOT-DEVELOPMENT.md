# 🛠️ Custom Bot Development Guide

## 🚀 Creating Custom Maubot Plugins

### **Option 1: Python Plugin Development**

#### **1. Set Up Development Environment**
```bash
# Install Maubot CLI tools
pip install maubot

# Create new bot plugin
maubot init mybot
cd mybot
```

#### **2. Basic Custom Bot Template**
```python
# mybot/__init__.py
from mautrix.util.config import BaseProxyConfig, ConfigUpdateHelper
from maubot import Plugin, MessageEvent
from maubot.handlers import command, event
from typing import Type
import re

class Config(BaseProxyConfig):
    def do_update(self, helper: ConfigUpdateHelper) -> None:
        helper.copy("greeting_message")

class MyCustomBot(Plugin):
    
    @classmethod
    def get_config_class(cls) -> Type[BaseProxyConfig]:
        return Config

    async def start(self) -> None:
        await super().start()
        self.config.load_and_update()

    @command.new("hello")
    async def hello_handler(self, evt: MessageEvent, name: str = "") -> None:
        """Simple hello command"""
        if name:
            await evt.respond(f"Hello, {name}! 👋")
        else:
            await evt.respond("Hello! 👋")

    @command.new("weather")
    @command.argument("location", pass_raw=True, required=True)
    async def weather_handler(self, evt: MessageEvent, location: str) -> None:
        """Get weather for a location"""
        # Add your weather API integration here
        await evt.respond(f"Weather for {location}: ☀️ Sunny, 75°F")

    @event.on(MessageEvent)
    async def message_handler(self, evt: MessageEvent) -> None:
        """Handle all messages for custom logic"""
        message = evt.content.body.lower()
        
        # Custom auto-responses
        if "good morning" in message:
            await evt.respond("Good morning! ☀️ Have a great day!")
        
        elif "help" in message and evt.sender != self.client.mxid:
            await evt.respond(
                "Available commands:\n"
                "• `!hello [name]` - Say hello\n"
                "• `!weather <location>` - Get weather\n"
                "• Say 'good morning' for a greeting!"
            )
```

#### **3. Plugin Configuration**
```yaml
# base-config.yaml
greeting_message: "Welcome to our Matrix server!"
weather_api_key: "your-api-key-here"
```

#### **4. Plugin Metadata**
```yaml
# maubot.yaml
maubot: 0.1.0
id: com.yourname.mybot
version: 1.0.0
license: MIT
modules:
- mybot
main_class: MyCustomBot

config: true
database: false

extra_files:
- base-config.yaml
```

#### **5. Build and Deploy**
```bash
# Build the plugin
maubot build

# Upload to Maubot (via web interface or CLI)
maubot upload mybot.mbp
```

## 🎨 Custom Bot Ideas

### **Voice/Video Call Bots**
```python
@command.new("startcall")
async def start_call(self, evt: MessageEvent, room: str = None) -> None:
    """Start a voice call in a room"""
    target_room = room or evt.room_id
    
    # Element Call integration
    call_url = f"https://call.element.io/{target_room.replace('!', '').replace(':', '-')}"
    
    await evt.respond(
        f"🎤 Starting voice call!\n"
        f"Join here: [Element Call]({call_url})\n"
        f"Or use your Matrix client's built-in calling feature."
    )
```

### **Room Management Bot**
```python
@command.new("createroom")
@command.argument("name", pass_raw=True, required=True)
async def create_room(self, evt: MessageEvent, name: str) -> None:
    """Create a new room"""
    room_alias = f"#{name.lower().replace(' ', '-')}:{self.client.domain}"
    
    room_id = await self.client.create_room(
        alias_localpart=name.lower().replace(' ', '-'),
        name=name,
        topic=f"Room created by {evt.sender}",
        preset="public_chat"
    )
    
    await evt.respond(f"✅ Created room: {name}\nAlias: {room_alias}")
```

### **Moderation Bot**
```python
@command.new("kick")
@command.argument("user", pass_raw=True, required=True)
async def kick_user(self, evt: MessageEvent, user: str) -> None:
    """Kick a user from the room"""
    # Check if sender has permission
    power_levels = await self.client.get_state_event(evt.room_id, "m.room.power_levels")
    sender_power = power_levels.get("users", {}).get(evt.sender, 0)
    
    if sender_power >= 50:  # Moderator level
        await self.client.kick_user(evt.room_id, user, "Kicked by moderator")
        await evt.respond(f"✅ Kicked {user} from the room")
    else:
        await evt.respond("❌ You don't have permission to kick users")
```

## 🔗 Integration Examples

### **External API Integration**
```python
import aiohttp

@command.new("crypto")
@command.argument("coin", pass_raw=True, required=True)
async def crypto_price(self, evt: MessageEvent, coin: str) -> None:
    """Get cryptocurrency prices"""
    async with aiohttp.ClientSession() as session:
        url = f"https://api.coingecko.com/api/v3/simple/price?ids={coin}&vs_currencies=usd"
        async with session.get(url) as resp:
            data = await resp.json()
            
            if coin in data:
                price = data[coin]['usd']
                await evt.respond(f"💰 {coin.upper()}: ${price:,}")
            else:
                await evt.respond(f"❌ Cryptocurrency '{coin}' not found")
```

### **Schedule Management**
```python
from datetime import datetime, timedelta
import asyncio

@command.new("remind")
@command.argument("time", required=True)
@command.argument("message", pass_raw=True, required=True)
async def set_reminder(self, evt: MessageEvent, time: str, message: str) -> None:
    """Set a reminder"""
    try:
        # Parse time (simple example for minutes)
        minutes = int(time.rstrip('m'))
        reminder_time = datetime.now() + timedelta(minutes=minutes)
        
        await evt.respond(f"⏰ Reminder set for {minutes} minutes from now")
        
        # Schedule the reminder
        await asyncio.sleep(minutes * 60)
        await self.client.send_text(
            evt.room_id, 
            f"⏰ Reminder for {evt.sender}: {message}"
        )
        
    except ValueError:
        await evt.respond("❌ Invalid time format. Use format like '30m'")
```

## 📦 Plugin Distribution

### **1. Package Your Bot**
```bash
# Create distribution package
maubot build --upload --server your-maubot-url --username admin --password password
```

### **2. Share with Community**
- Upload to GitHub
- Share `.mbp` files
- Contribute to [Maubot Hub](https://maubot.xyz/plugins)

## 🛠️ Development Tools

### **Testing Your Bot**
```bash
# Test locally before deploying
maubot dev --config config.yaml
```

### **Debugging**
```python
# Add logging to your bot
import logging
logger = logging.getLogger(__name__)

@command.new("debug")
async def debug_command(self, evt: MessageEvent) -> None:
    logger.info(f"Debug command called by {evt.sender}")
    await evt.respond("Debug info logged!")
```

## 🚀 Quick Start Template

Want to get started immediately? Here's a minimal custom bot:

```python
from maubot import Plugin, MessageEvent
from maubot.handlers import command

class QuickBot(Plugin):
    
    @command.new("ping")
    async def ping(self, evt: MessageEvent) -> None:
        await evt.respond("Pong! 🏓")
    
    @command.new("serverinfo")
    async def server_info(self, evt: MessageEvent) -> None:
        await evt.respond(
            f"📊 Server Information\n"
            f"• Server: {self.client.domain}\n"
            f"• Bot User: {self.client.mxid}\n"
            f"• Room: {evt.room_id}"
        )
```

This gives you complete control over your bots while leveraging the powerful Maubot framework that's already integrated into your voice-stack!
