# Element Call / Video Calls Troubleshooting Guide

This guide helps resolve the `MISSING_MATRIX_RTC_FOCUS` error and other video calling issues in your Matrix voice-stack deployment.

## 🚨 Error: "MISSING_MATRIX_RTC_FOCUS"

**Full Error Message**: 
> The server is not configured to work with Element Call. Please contact your server admin (Domain: matrix.byte-box.org, Error Code: MISSING_MATRIX_RTC_FOCUS).

**Cause**: The `rtc_focus` configuration section is missing from your Synapse homeserver.yaml file.

## 🔧 Quick Fixes

### Option 1: Run the Automated Fix Script
```bash
# Linux/Mac
chmod +x fix-element-call.sh
./fix-element-call.sh

# Windows PowerShell  
.\fix-element-call.ps1
```

### Option 2: Manual Configuration Fix
1. **Connect to Synapse container**:
   ```bash
   docker exec -it voice-stack-synapse bash
   ```

2. **Add the missing RTC Focus configuration**:
   ```bash
   cat >> /data/homeserver.yaml << 'EOF'

# Element Call RTC Focus Configuration
rtc_focus:
  enabled: true
  use_as_focus: true
  participant_timeout: 30
  focus_selection_timeout: 10
EOF
   ```

3. **Exit and restart Synapse**:
   ```bash
   exit
   docker restart voice-stack-synapse
   ```

### Option 3: Stack Restart (Recommended)
The startup script has been updated to properly add this configuration:

```bash
# Stop the stack
docker-compose down

# Start with updated configuration
docker-compose up -d

# Check that Synapse started properly
docker logs voice-stack-synapse -f
```

### 2. **Verify Synapse Configuration**
Check that the RTC focus configuration was applied:

```bash
# Connect to Synapse container
docker exec -it voice-stack-synapse bash

# Check for RTC focus configuration
grep -A 10 "rtc_focus:" /data/homeserver.yaml
grep -A 10 "experimental_features:" /data/homeserver.yaml
```

You should see:
```yaml
rtc_focus:
  enabled: true
  use_as_focus: true
  participant_timeout: 30
  focus_selection_timeout: 10

experimental_features:
  msc3401_group_voice_calls: true
  msc3402_group_video_calls: true
  msc4191_element_call_matrix_rtc_focus: true
  msc4230_element_call_per_device_encryption: true
  msc4010_push_rules_account_data: true
```

## 🔍 Understanding the Fix

### **What Was Wrong**
1. **External Element Call URL**: Element was configured to use `https://call.element.io`
2. **Missing RTC Focus Config**: Synapse wasn't properly configured as an RTC focus
3. **Missing MSC Features**: Required experimental features weren't enabled

### **What Was Fixed**
1. **Removed External URL**: Set `element_call.url` to `null` (uses Matrix RTC focus)
2. **Added RTC Focus**: Synapse now acts as its own RTC focus server
3. **Enhanced MSC Features**: Added missing experimental features for Matrix RTC
4. **Updated Element Features**: Enabled native Matrix calling features

## 🧪 Testing Video Calls

### **Step 1: Verify Element Configuration**
1. Open Element Web: `http://your-server:8080`
2. Go to **Settings** → **Labs**
3. Verify these features are available:
   - ✅ **Group Calls** (should be enabled)
   - ✅ **Element Call video rooms** (should be enabled)
   - ✅ **Matrix RTC** (should be enabled)

### **Step 2: Test Group Video Call**
1. **Create or join a room** with multiple users
2. **Click the video call button** (camera icon) in the room
3. **Should see**: "Starting call..." instead of `MISSING_MATRIX_RTC_FOCUS`
4. **Expected behavior**: Direct Matrix-native video call (no external service)

### **Step 3: Test 1:1 Video Call**
1. **Start direct message** with another user
2. **Click video call button** in the conversation
3. **Should work**: Through your TURN server (Coturn)

## 🔧 Advanced Troubleshooting

### **Problem**: Still Getting MISSING_MATRIX_RTC_FOCUS

**Solution 1: Force Element Configuration Reload**
```bash
# Stop stack
docker-compose down

# Remove Element data to force reconfiguration
docker volume rm voice-stack_element_data

# Start stack (will regenerate Element config)
docker-compose up -d
```

**Solution 2: Manually Check Element Config**
```bash
# Check Element configuration
docker exec -it voice-stack-element cat /usr/share/nginx/html/config.json | grep -A 5 element_call
```

Should show:
```json
"element_call": {
    "url": null,
    "participant_limit": 8,
    "brand": "Element Call"
}
```

### **Problem**: Video Calls Start But No Video/Audio

**Check TURN Server**
```bash
# Verify Coturn is running
docker logs voice-stack-coturn

# Should see logs about client connections
# If no logs, check firewall/ports
```

**Verify TURN Configuration in Synapse**
```bash
docker exec -it voice-stack-synapse grep -A 5 "turn_uris:" /data/homeserver.yaml
```

Should show:
```yaml
turn_uris:
  - "turn:your-domain:3478?transport=udp"
  - "turn:your-domain:3478?transport=tcp"
turn_shared_secret: "your-turn-secret"
```

### **Problem**: Calls Work Locally But Not Externally

**Check Firewall/Port Configuration**
```bash
# Required ports must be open:
# 3478 (TURN server)
# 49152-49172 (TURN relay ports)
# 8008 (Synapse)
# 8080 (Element)

# Test TURN server externally
# Replace YOUR_DOMAIN with your actual domain
telnet YOUR_DOMAIN 3478
```

### **Problem**: Multiple People Can't Join Video Calls

**Check Participant Limits**
```bash
# Verify Element configuration allows enough participants
docker exec -it voice-stack-element grep -A 3 element_call /usr/share/nginx/html/config.json
```

Should show:
```json
"element_call": {
    "url": null,
    "participant_limit": 8,
    "brand": "Element Call"
}
```

## 🚀 Performance Optimization

### **For 4+ People Video Calls**
Add to your `.env` file:
```bash
# Increase TURN relay port range for more users
COTURN_MIN_PORT=49152
COTURN_MAX_PORT=49200

# Increase Synapse worker processes (if needed)
SYNAPSE_WORKERS=2
```

### **Monitor Resource Usage**
```bash
# Check container resource usage during calls
docker stats voice-stack-synapse voice-stack-coturn

# Monitor logs during calls
docker logs voice-stack-synapse -f --tail=50
```

## 🔐 Security Notes

### **Matrix RTC vs External Element Call**
- ✅ **Matrix RTC (Your Setup)**: All video/audio stays on your server
- ❌ **External Element Call**: Video/audio goes through Element's servers

### **TURN Server Security**
Your TURN server uses shared secret authentication:
- ✅ **Automatic Credentials**: Generated by Synapse for each call
- ✅ **Time-Limited Access**: Credentials expire automatically
- ✅ **Local Network Only**: No external TURN dependencies

## 📊 Call Quality Troubleshooting

### **Poor Video Quality**
1. **Check bandwidth**: Video calls need ~2Mbps per participant
2. **Monitor CPU**: High CPU usage can degrade quality
3. **Check TURN logs**: Look for connection issues

### **Audio/Video Sync Issues**
1. **Restart containers**: Sometimes helps with codec issues
2. **Check browser**: Try different browsers (Chrome works best)
3. **Update Element**: Use latest version (v1.11.86 configured)

## 📚 Technical References

- **MSC3401**: Group Voice Calls
- **MSC3402**: Group Video Calls  
- **MSC4191**: Element Call Matrix RTC Focus
- **MSC4230**: Per-Device Encryption
- **MSC4010**: Push Rules Account Data

## ✅ Success Indicators

After applying the fixes, you should see:

1. **No More Errors**: `MISSING_MATRIX_RTC_FOCUS` error disappears
2. **Native Calling**: Calls start directly without external redirects
3. **Local Processing**: All video/audio processing happens on your server
4. **Better Privacy**: No data sent to Element's servers
5. **Lower Latency**: Direct peer-to-peer connections through your TURN server

---

**🆘 Still Having Issues?**

1. **Check Logs**: `docker logs voice-stack-synapse -f`
2. **Restart Stack**: `docker-compose down && docker-compose up -d`
3. **Verify Ports**: Ensure 3478 and 49152-49172 are open
4. **Test Browsers**: Try Chrome/Firefox for better compatibility
