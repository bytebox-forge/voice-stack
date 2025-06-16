# Element Web Interface Guide

Step-by-step guide for using Element Web to manage your family Matrix server.

## 🌐 Accessing Element Web

**URL**: `http://your-server:8080`

### First Login
1. **Open browser** → Go to Element URL
2. **Sign In** (if you have account) or **Create Account**
3. **Homeserver**: Should auto-detect your server
4. **Username/Password**: Enter your credentials

## 🏠 Creating Rooms in Element

### Step-by-Step Room Creation
1. **Click "+" button** next to "Rooms" in left sidebar
2. **Select "Create Room"**
3. **Configure room settings**:

#### Basic Settings
- **Room Name**: e.g., "Family General"
- **Room Topic**: Brief description
- **Room Avatar**: Optional family photo

#### Privacy Settings
- **Room Visibility**: 
  - ✅ **Private** (recommended for family)
  - ❌ Public (anyone can find)
- **Who can join**: 
  - ✅ **Invite only** (safest for kids)
  - ❌ Anyone with link

#### Advanced Settings
- **Enable end-to-end encryption**: ✅ Yes (recommended)
- **Block anyone not part of [server]**: ✅ Yes
- **Room address**: `#family-general:your-domain.com`

### Quick Family Room Setup
```bash
Create these rooms in order:

1. #family-general
   - Topic: "Main family chat - everyone welcome!"
   - Private, invite only, encrypted

2. #family-announcements  
   - Topic: "Important family updates"
   - Private, invite only, parents can post

3. #kids-zone
   - Topic: "Kids only space - have fun!"
   - Private, invite only, kid-friendly

4. #homework-help
   - Topic: "School work assistance"
   - Private, invite only, educational

5. #voice-test
   - Topic: "Test voice and video calls here"
   - Private, invite only, for testing
```

## 👥 Managing Room Members

### Inviting People to Rooms
1. **Open the room**
2. **Click room name** at top
3. **People tab** → **Invite** button
4. **Enter username**: `@username:your-domain.com`
5. **Send invitation**

### Setting Member Permissions
1. **Room Settings** → **Security & Privacy**
2. **Roles & Permissions** section
3. **Change power levels**:

```yaml
Permission Examples:
- Send messages: 0 (everyone can chat)
- Invite users: 50 (only parents/mods)
- Change room name: 100 (only admin)
- Kick users: 50 (parents can moderate)
```

### Managing Problem Users
1. **Right-click username** in member list
2. **Options**:
   - **Kick**: Remove but can rejoin if invited
   - **Ban**: Remove and prevent rejoining
   - **Change power level**: Adjust permissions

## 🎯 Room Settings Deep Dive

### Security & Privacy Tab
- **Room Visibility**: Public vs Private
- **Join Rule**: How people can join
- **History Visibility**: Who can see old messages
- **Guest Access**: Allow/prevent guests

### General Tab  
- **Room Name & Topic**: Basic info
- **Room Avatar**: Upload family photo
- **Room Addresses**: Aliases for easy finding

### Notifications Tab
- **Push notifications**: When to notify
- **Sound alerts**: Audio notifications
- **Keyword alerts**: Specific word notifications

## 🔐 Family-Safe Configuration

### Recommended Room Settings for Kids
```yaml
Privacy Settings:
  Visibility: Private
  Join Rule: Invite only
  History: Members only (since joining)
  Guest Access: Forbidden

Security Settings:
  End-to-end encryption: Enabled
  Block federation: Yes (local server only)
  
Permissions:
  Kids (Power Level 0):
    - Can send messages
    - Can participate in calls
    - Cannot invite external users
    - Cannot change room settings
    
  Parents (Power Level 50):
    - All kid permissions +
    - Can invite family members
    - Can moderate content
    - Can change basic settings
    
  Admin (Power Level 100):
    - Full control over room
```

## 📞 Voice & Video Calling

### Starting a Voice Call
1. **In any room**: Click **phone icon** in top toolbar
2. **Choose participants** if group call
3. **Wait for others** to accept
4. **Use controls** during call (mute, hang up, etc.)

### Starting Video Call
1. **Click video camera icon** instead of phone
2. **Allow camera/microphone** permissions
3. **Same process** as voice call

### Call Troubleshooting
- **No audio**: Check browser microphone permissions
- **No video**: Check browser camera permissions
- **Call fails**: Check TURN server is running
- **Poor quality**: Check network bandwidth

## 🎮 Fun Family Features

### Custom Emojis & Reactions
1. **Room Settings** → **General**
2. **Upload custom emojis** for family
3. **React to messages** with emojis
4. **Create family emoji collection**

### File & Photo Sharing
1. **Drag & drop files** into chat
2. **Click attachment icon** for file browser
3. **Paste images** directly from clipboard
4. **Set file size limits** in room settings

### Message Formatting
```markdown
**Bold text**
*Italic text*
`Code text`
> Quote text
- List items
1. Numbered lists
[Link text](https://url.com)
```

## 📱 Mobile Integration

### Element Mobile Apps
- **Download Element** from app store
- **Point to your server**: Enter server URL
- **Login** with same credentials
- **Sync automatically** with web version

### Mobile-Specific Features
- **Push notifications** when away from computer
- **Voice/video calls** on mobile
- **Photo sharing** from camera
- **Location sharing** (if enabled)

## 🛠️ Troubleshooting Common Issues

### Can't See Rooms
1. **Check invitations**: Look for pending invites
2. **Verify server connection**: Check network
3. **Refresh page**: Clear browser cache
4. **Check permissions**: Ensure proper access

### Can't Send Messages
1. **Check room permissions**: Verify send message level
2. **Network issues**: Test connection
3. **Browser problems**: Try different browser
4. **Account issues**: Check with admin

### Encryption Problems
1. **Verify all devices**: Cross-sign devices
2. **Reset encryption**: Last resort option
3. **Check room settings**: Ensure encryption enabled
4. **Key backup**: Set up key backup

## 📋 Family Setup Checklist

### Initial Setup (Parents)
- [ ] Login to Element Web
- [ ] Create family rooms
- [ ] Set appropriate permissions
- [ ] Test voice/video calling
- [ ] Create kid accounts (via admin tools)

### Kid Account Setup
- [ ] Help kids login first time
- [ ] Show them room navigation
- [ ] Explain family rules
- [ ] Test sending messages
- [ ] Practice voice calls

### Ongoing Management
- [ ] Monitor room activity
- [ ] Adjust permissions as needed
- [ ] Handle content issues
- [ ] Update family rules
- [ ] Regular family meetings about usage

## 🎯 Pro Tips

### Organization Tips
1. **Use clear room names** - `#family-general` not `#fg`
2. **Set helpful topics** - explain what each room is for
3. **Pin important messages** - right-click → Pin
4. **Use room tags** - organize rooms by category

### Communication Tips
1. **@mention people** - `@username` for notifications
2. **Reply to specific messages** - click reply arrow
3. **Edit messages** - right-click → Edit (within time limit)
4. **Use threads** - keep conversations organized

### Safety Tips
1. **Regular permission audits** - check who has access
2. **Monitor new joiners** - verify all new members
3. **Report problems** - use admin tools for issues
4. **Backup important chats** - export if needed

---

**Remember**: Element Web is your main interface for daily family communication. Take time to explore features and customize for your family's needs!
