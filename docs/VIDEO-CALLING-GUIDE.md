# Video Calls & Video Rooms Guide

This guide explains the different video calling features available in your Matrix voice-stack deployment.

## 📋 Table of Contents
- [Feature Overview](#feature-overview)
- [Group Calls (Stable)](#group-calls-stable)
- [Video Rooms (Beta)](#video-rooms-beta)
- [Setup Instructions](#setup-instructions)
- [Usage Examples](#usage-examples)
- [Comparison Table](#comparison-table)
- [Troubleshooting](#troubleshooting)

## 🎯 Feature Overview

Your voice-stack supports **THREE** types of video calling:

### 1. **1:1 Video Calls** ✅ Stable
- Direct video calls between two people
- Works in any direct message conversation
- Uses your TURN server (Coturn)

### 2. **Group Calls** ✅ Stable  
- Ad-hoc video calls in existing rooms
- Up to 8 people (configurable)
- Click video button in any room

### 3. **Video Rooms** 🧪 Beta
- Persistent video conference rooms
- Like Zoom/Teams meeting rooms
- Scheduled or always-on video spaces

## 📞 Group Calls (Stable)

### **What Are Group Calls?**
- **Traditional video calls** in any existing room
- **Ad-hoc calling**: Start a video call instantly
- **Natural integration**: Works with your existing chat rooms

### **How to Use Group Calls**
1. **Join any room** with multiple people
2. **Click the video camera icon** in the room header
3. **Others see notification**: "Video call started"
4. **Click to join**: Anyone can join the ongoing call

### **Group Call Features**
- ✅ **Screen sharing**
- ✅ **Mute/unmute audio**
- ✅ **Enable/disable video**
- ✅ **Chat during call**
- ✅ **Up to 8 participants** (default limit)

## 🏠 Video Rooms (Beta)

### **What Are Video Rooms?**
- **Persistent video spaces**: Always available for joining
- **Dedicated rooms**: Specifically designed for video conferencing
- **Scheduled meetings**: Perfect for regular family calls

### **How to Enable Video Rooms**
1. **Open Element Web**: `http://your-server:8080`
2. **Go to Settings** → **Labs**
3. **Enable**: "Element Call video rooms"
4. **Enable**: "Matrix RTC" (if not already enabled)

### **How to Create Video Rooms**
1. **Click "+" to create room**
2. **Choose "Video room"** option
3. **Configure room**:
   - Room name: e.g., "Family Weekly Call"
   - Room visibility: Private/Public
   - Encryption: Recommended ON
4. **Invite family members**

### **How to Use Video Rooms**
1. **Enter the video room** (like joining a chat room)
2. **Click "Join call"** button (always visible)
3. **Video starts immediately** (no separate call setup)
4. **Others can join anytime** the room exists

### **Video Room Features**
- ✅ **Always available**: Room exists permanently
- ✅ **Drop-in/drop-out**: Join whenever convenient
- ✅ **Scheduled use**: Perfect for regular family meetings
- ✅ **Persistent chat**: Text chat alongside video
- ✅ **Room customization**: Name, topic, avatar

## 🛠️ Setup Instructions

### **Enable Labs Features (Required for Video Rooms)**

Your configuration now shows Labs settings. Users need to:

1. **Open Element** → **Settings** (gear icon)
2. **Click "Labs"** in the left sidebar
3. **Enable these features**:
   - ✅ **Element Call video rooms**
   - ✅ **Matrix RTC**
   - ✅ **Group calls** (should already be enabled)

### **Server Configuration (Already Done)**

Your server is configured with:
```yaml
# Group Calls Support
experimental_features:
  msc3401_group_voice_calls: true      # Voice calls
  msc3402_group_video_calls: true      # Video calls
  msc4191_element_call_matrix_rtc_focus: true  # RTC focus
  msc4230_element_call_per_device_encryption: true
  msc4010_push_rules_account_data: true

# RTC Focus (Your server handles video calls)
rtc_focus:
  enabled: true
  use_as_focus: true
  participant_timeout: 30
  focus_selection_timeout: 10
```

## 💡 Usage Examples

### **Scenario 1: Quick Family Chat Call**
**Use**: **Group Calls**
1. Family in "General Chat" room
2. Someone clicks video button
3. Everyone joins for quick catch-up
4. Call ends, room continues as chat

### **Scenario 2: Sunday Family Meeting**
**Use**: **Video Rooms**
1. Create "Sunday Family Call" video room
2. Everyone joins every Sunday 2pm
3. Drop-in style: join when convenient
4. Room always available for future calls

### **Scenario 3: Dad's Weekly Check-in**
**Use**: **Video Rooms**
1. Create "Dad's Office Hours" video room
2. Kids can drop in anytime
3. Persistent space for regular connection
4. No scheduling needed

### **Scenario 4: Two People Quick Call**
**Use**: **1:1 Video Calls**
1. Direct message conversation
2. Click video button
3. Instant private call
4. Most reliable for two people

## 📊 Comparison Table

| Feature | Group Calls | Video Rooms | 1:1 Calls |
|---------|-------------|-------------|-----------|
| **Setup** | None required | Enable in Labs | None required |
| **When to Use** | Ad-hoc calls | Scheduled/regular | Private calls |
| **Room Type** | Any existing room | Dedicated video room | Direct message |
| **Persistence** | Call ends when empty | Room always exists | Call ends |
| **Best For** | Quick group chats | Regular meetings | Private conversations |
| **Max People** | 8 (configurable) | 8 (configurable) | 2 |
| **Stability** | ✅ Stable | 🧪 Beta | ✅ Stable |

## 🚀 Configuration Options

### **Increase Participant Limits**
To allow more than 8 people in video calls, add to your `.env`:

```bash
# Allow up to 15 people in video calls
ELEMENT_CALL_PARTICIPANT_LIMIT=15
```

Then update your docker-compose configuration:
```bash
docker-compose down
docker-compose up -d
```

### **Performance Tuning**
For larger video calls, consider:

```bash
# More TURN relay ports
COTURN_MIN_PORT=49152
COTURN_MAX_PORT=49300

# Increase bandwidth limits if needed
COTURN_BANDWIDTH_LIMIT=1000000  # 1MB/s per user
```

## 🐛 Troubleshooting

### **Video Rooms Not Visible**
1. **Check Labs Settings**: Must be enabled by each user
2. **Check Element Version**: Needs v1.11.86+ (you have this)
3. **Restart Element**: Refresh browser tab

### **Group Calls Not Working**
1. **Check Room Type**: Works in regular rooms, not video rooms
2. **Check Permissions**: User must be able to send messages
3. **Check Browser**: Chrome/Firefox work best

### **Poor Video Quality in Larger Calls**
1. **Bandwidth**: Each user needs ~2Mbps upload
2. **CPU Usage**: Monitor server resources
3. **Limit Participants**: Consider smaller groups

### **Can't Join Video Rooms**
1. **Labs Feature**: Must be enabled in user settings
2. **Room Permissions**: User must be invited/have access
3. **Browser Support**: Some features need modern browsers

## 🔐 Privacy & Security

### **All Video Types Are Private**
- ✅ **Local Processing**: All video handled by your server
- ✅ **No External Services**: Nothing goes to Element.io
- ✅ **Encrypted**: End-to-end encryption available
- ✅ **TURN Server**: Your own Coturn handles connections

### **Recommended Settings**
- **Enable room encryption** for sensitive calls
- **Use private rooms** for family meetings
- **Regular password changes** for admin accounts
- **Monitor server logs** for unusual activity

## 📈 Feature Roadmap

### **Currently Available** ✅
- 1:1 video calls (stable)
- Group calls up to 8 people (stable)
- Video rooms (beta, but functional)
- Screen sharing
- Audio/video mute controls

### **Future Improvements**
- Video rooms will become stable
- Better mobile support
- Recording capabilities (community features)
- Larger participant limits

## 🎓 Best Practices

### **For Family Use**
1. **Create dedicated video rooms** for regular family meetings
2. **Use group calls** for spontaneous chats
3. **Test beforehand** with all family members
4. **Have backup plan** (regular chat) if video fails

### **For Regular Meetings**
1. **Video rooms are perfect** for scheduled calls
2. **Set clear times** when people should join
3. **Use room topics** to communicate meeting agendas
4. **Enable Labs features** on all family devices

---

## ✅ Summary

**You now have ALL video calling features enabled:**

- 🟢 **1:1 Video Calls**: Ready to use
- 🟢 **Group Calls**: Ready to use (up to 8 people)
- 🟢 **Video Rooms**: Available in Labs settings (beta but functional)

**Next Steps:**
1. Restart your stack: `docker-compose down && docker-compose up -d`
2. Enable Labs features in Element for Video Rooms
3. Test all three calling types with your family
4. Create dedicated video rooms for regular family meetings

Your voice-stack now provides a complete video calling solution that rivals commercial services while keeping everything private on your own server!
