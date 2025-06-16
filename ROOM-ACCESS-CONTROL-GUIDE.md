# Room Management & Access Control Guide

Complete guide for managing rooms, controlling access, and maintaining family-safe environments.

## 🚪 Room Access Control Basics

### Room Visibility Types
- **Public**: Anyone can find and join
- **Private**: Invitation only, not visible in public room directory
- **Knock**: Users can request to join, admins approve

### Room Join Rules
- **Anyone**: No restrictions
- **Invite Only**: Must be invited by existing member
- **Ask to Join**: Request permission from admins

## 🔐 Setting Up Room Permissions

### Basic Permission Levels
- **Admin (100)**: Full control over room
- **Moderator (50)**: Can kick users, manage content
- **Member (0)**: Can send messages, normal participation
- **Custom levels**: Set specific permissions

### How to Set Room Permissions
1. **Open room** in Element
2. **Room Settings** → **Security & Privacy**
3. **Roles & Permissions** section
4. **Adjust power levels** for different actions

## 👥 Managing Room Members

### Adding Members
```bash
# Method 1: Via Element Interface
1. Open room
2. Room Info → People
3. Click "Invite" button
4. Enter username or email

# Method 2: Via Admin Panel
1. Go to admin panel (http://your-server:8082)
2. Rooms → Select room
3. Members tab
4. Add member
```

### Removing Members
```bash
# Kick user (they can rejoin if invited)
1. Room Settings → People
2. Click user → Kick

# Ban user (prevents rejoining)
1. Room Settings → People  
2. Click user → Ban
3. Optionally set reason
```

### Member Permission Examples
```yaml
# Family Room Permissions Example
Parents:
  - Power Level: 50 (Moderator)
  - Can: Invite, kick, change room settings
  
Kids:
  - Power Level: 0 (Member)
  - Can: Send messages, participate in calls
  - Cannot: Invite strangers, change settings

Admin:
  - Power Level: 100 (Admin)
  - Can: Everything including delete room
```

## 🛡️ Family-Safe Room Configuration

### Kid-Safe Room Settings
1. **Privacy**: Set to Private/Invite Only
2. **History Visibility**: Shared from join point
3. **Guest Access**: Disabled
4. **Directory Listing**: No (keep private)
5. **Encryption**: Enabled for sensitive conversations

### Parent Control Settings
```bash
# Room Configuration for Kids
Room Type: Private
Join Rule: Invite Only
History: Members only (since joining)
Guest Access: Forbidden
Federation: Disabled (local only)
Power Levels:
  - Send messages: 0 (kids can chat)
  - Invite users: 50 (only parents can invite)
  - Change settings: 100 (only admin)
```

## 🎯 Room Templates for Families

### Template 1: General Family Room
```yaml
Name: "#family-general"
Topic: "Main family chat - everyone welcome!"
Type: Private
Join Rule: Invite Only
Encryption: Enabled
Power Levels:
  Parents: 50
  Kids: 0
  Admin: 100
Permissions:
  Send Messages: 0
  Invite Users: 50
  Change Avatar: 50
  Change Name: 100
```

### Template 2: Kids-Only Room  
```yaml
Name: "#kids-zone"
Topic: "Kids only space - have fun!"
Type: Private  
Join Rule: Invite Only
Encryption: Enabled
Power Levels:
  Kids: 0
  Parents: 50 (for monitoring)
  Admin: 100
Special Rules:
  - No external invites
  - Parent oversight
  - Appropriate content only
```

### Template 3: Parents-Only Room
```yaml
Name: "#parents-private"
Topic: "Adult discussions and planning"
Type: Private
Join Rule: Invite Only  
Encryption: Enabled
Members: Adults only
Power Levels:
  All Parents: 50
  Admin: 100
```

## 🔧 Advanced Access Control

### Room-Specific Restrictions

#### Prevent External Invitations
1. **Room Settings** → **Security & Privacy**
2. **Set "Invite Users" to 50+**
3. **Give kids power level 0**
4. **Only parents/admins can invite**

#### Content Moderation Setup
```bash
# Admin Commands for Content Control
1. Set message retention policies
2. Enable content scanning (if needed)
3. Set up automated moderation rules
4. Configure report handling
```

#### Time-Based Restrictions
- **Quiet Hours**: Use client-side settings
- **Activity Monitoring**: Via admin panel
- **Usage Reports**: Check admin statistics

### Federation Control
```yaml
# Disable federation for family rooms
federation: false
# Keeps conversations local only
# Prevents external server access
```

## 🎮 Creating Different Room Types

### Study/Homework Room
```bash
Name: "#homework-help"
Purpose: School work assistance
Permissions:
  - Kids can ask questions
  - Parents can help
  - File sharing enabled
  - Voice calls for tutoring
Rules:
  - Educational content only
  - Respectful communication
  - Share resources freely
```

### Entertainment Room
```bash
Name: "#family-entertainment"  
Purpose: Movies, games, fun activities
Permissions:
  - Everyone can suggest activities
  - Parents approve final decisions
  - Media sharing enabled
  - Group voice/video calls
```

### Emergency Room
```bash
Name: "#family-emergency"
Purpose: Urgent family communications
Permissions:
  - High priority notifications
  - All family members
  - Location sharing enabled
  - Always accessible
```

## 📱 Mobile App Access Control

### Element Mobile Settings
1. **Download Element** from app store
2. **Server Settings**: Point to your server
3. **Login** with family member credentials
4. **Sync rooms** automatically

### Mobile-Specific Restrictions
- **App-level restrictions** (parental controls)
- **Screen time limits** (device settings)
- **Notification management** (quiet hours)

## 🔍 Monitoring & Safety

### Admin Monitoring Tools
```bash
# Via Synapse Admin Panel
1. User activity tracking
2. Room message counts
3. Login/logout logs
4. Device management
5. Content reports
```

### Safety Checklist
- [ ] All family rooms set to private
- [ ] Kids cannot invite external users
- [ ] Parents have moderator permissions
- [ ] Encryption enabled for sensitive rooms
- [ ] External federation disabled
- [ ] Regular permission audits
- [ ] Clear family usage rules

### Content Safety Rules
1. **No sharing personal information** publicly
2. **Report inappropriate content** immediately
3. **Ask permission** before sharing photos
4. **Respect family privacy** boundaries
5. **Use appropriate language** always

## 🛠️ Room Management Commands

### Via Element Interface
```bash
# Create Room
+ button → Create Room → Configure settings

# Manage Members  
Room Info → People → Invite/Remove

# Change Settings
Room Settings → Security & Privacy

# Moderate Content
Right-click message → Report/Remove
```

### Via Admin Panel
```bash
# Room Statistics
Admin Panel → Rooms → Select room

# User Management
Admin Panel → Users → Select user

# Content Management
Admin Panel → Reports → Handle reports
```

## 📋 Family Room Setup Checklist

### Initial Setup
- [ ] Create admin accounts
- [ ] Create family member accounts
- [ ] Set up basic family rooms
- [ ] Configure room permissions
- [ ] Test access controls
- [ ] Enable encryption

### Security Setup
- [ ] Set rooms to private
- [ ] Disable external invites for kids
- [ ] Set up parent oversight
- [ ] Configure content policies
- [ ] Test emergency procedures
- [ ] Document family rules

### Ongoing Management
- [ ] Regular permission audits
- [ ] Monitor usage patterns
- [ ] Update access as kids grow
- [ ] Handle content reports
- [ ] Maintain family guidelines
- [ ] Backup important conversations

## 🎯 Best Practices

### For Parents
1. **Start restrictive**, relax permissions over time
2. **Monitor regularly** but respect privacy appropriately
3. **Educate kids** about digital citizenship
4. **Set clear expectations** for usage
5. **Review permissions** quarterly

### For Kids
1. **Ask permission** before inviting friends
2. **Report problems** to parents immediately
3. **Respect others** in all communications
4. **Keep personal info private**
5. **Follow family rules** consistently

### For the Family
1. **Regular family meetings** about digital usage
2. **Clear consequences** for rule violations
3. **Celebrate positive** digital citizenship
4. **Stay updated** on platform features
5. **Maintain open communication** about online experiences

---

**Remember**: The goal is creating a safe, fun environment for family communication while teaching responsible digital citizenship!
