# Voice and Video Testing Guide

This guide helps you test voice and video calling functionality in your voice-stack deployment.

## 🎤 Voice Testing Checklist

### Pre-Test Setup
1. **Ensure TURN server is running**:
   ```bash
   docker ps | grep coturn
   docker logs voice-stack-coturn-1 --tail 20
   ```

2. **Check ports are accessible**:
   - TURN/STUN: 3478, 5349
   - TURN relay range: 49152-49172
   - Synapse: 8008
   - Element: 8080

3. **Verify Element can reach Synapse**:
   - Go to `http://your-server:8080`
   - Login successfully
   - Check no connection errors

## 📞 Testing Voice Calls

### Step 1: Create Test Room
1. **In Element Web**: Click "+" next to Rooms
2. **Name**: "Voice Test Room"
3. **Settings**: Enable encryption if desired
4. **Invite**: Another user or create second account for testing

### Step 2: Test Direct Voice Call
1. **Open a DM** with another user
2. **Click phone icon** in the top bar
3. **Allow microphone access** when prompted
4. **Wait for connection** (should show "Connecting...")
5. **Test audio** both directions

### Step 3: Test Room Voice Call
1. **Join test room** with multiple users
2. **Click voice call button** in room
3. **Wait for all participants** to join
4. **Test group audio**

### Step 4: Test Video Call
1. **Click video camera icon** instead of phone
2. **Allow camera access** when prompted
3. **Test video and audio** quality
4. **Try screen sharing** if available

## 🔧 Voice Troubleshooting

### Common Issues and Fixes

#### "Call Failed" or "Connection Failed"
```bash
# Check TURN server logs
docker logs voice-stack-coturn-1 --tail 50

# Verify TURN configuration in Synapse
docker exec voice-stack-synapse cat /data/homeserver.yaml | grep -A10 turn
```

#### No Audio in Calls
- **Check browser permissions**: Allow microphone access
- **Test in different browsers**: Chrome, Firefox, Edge
- **Check firewall**: Ensure TURN ports are open
- **Verify TURN secret**: Must match between Synapse and Coturn

#### Poor Call Quality
- **Check network bandwidth**: Voice needs ~64kbps minimum
- **Test local network**: Try calls on same network first
- **Monitor TURN usage**: Check if relay is working properly

#### "Ice Connection Failed"
This usually indicates TURN server issues:
```bash
# Restart TURN server
docker restart voice-stack-coturn-1

# Check TURN server status
docker exec voice-stack-coturn-1 netstat -tulpn | grep 3478
```

## 🌐 External Access Testing

### For Internet-facing servers:
1. **DNS Configuration**: Ensure proper A records
2. **Firewall Rules**: Open required ports
3. **SSL/TLS**: Consider HTTPS for production
4. **TURN External IP**: Set in .env if behind NAT

### Network Configuration Check:
```bash
# Test STUN server externally
stun-client your-server.com 3478

# Verify ports are open externally
nmap -p 3478,5349,49152-49172 your-server.com
```

## 📋 Test Scenarios

### Basic Voice Test
- [ ] Create test room
- [ ] Invite second user
- [ ] Start voice call
- [ ] Verify audio both ways
- [ ] End call properly

### Advanced Voice Test
- [ ] Multi-user room call (3+ people)
- [ ] Call with screen sharing
- [ ] Call with video enabled
- [ ] Test call quality over time
- [ ] Test reconnection after network interruption

### Cross-Platform Test
- [ ] Web browser to web browser
- [ ] Web to mobile app (if using Matrix mobile clients)
- [ ] Different browser combinations
- [ ] Desktop app to web (if using Element Desktop)

## 🎯 Performance Optimization

### For Better Call Quality:
1. **Increase TURN relay range** if needed:
   ```bash
   # In .env file
   COTURN_MIN_PORT=49152
   COTURN_MAX_PORT=49200
   ```

2. **Monitor resource usage**:
   ```bash
   docker stats voice-stack-coturn-1
   docker stats voice-stack-synapse-1
   ```

3. **Configure bandwidth limits** in Coturn if needed

## 🔍 Debugging Commands

### Check TURN Server Status:
```bash
# TURN server logs
docker logs voice-stack-coturn-1 --tail 100

# TURN server process
docker exec voice-stack-coturn-1 ps aux | grep turnserver

# TURN server network
docker exec voice-stack-coturn-1 netstat -tulpn
```

### Check Synapse TURN Configuration:
```bash
# View Synapse TURN config
docker exec voice-stack-synapse cat /data/homeserver.yaml | grep -A15 turn

# Synapse logs for TURN-related messages
docker logs voice-stack-synapse-1 | grep -i turn
```

### Test TURN Server Manually:
```bash
# Install STUN client tools
sudo apt install stun-client

# Test STUN server
stun-client your-server-ip 3478
```

## 📱 Mobile Testing

If you want to test with mobile devices:
1. **Install Element mobile app**
2. **Connect to your server**: Use your server URL
3. **Login with test account**
4. **Test voice calls**: Between mobile and web

## 🚀 Production Readiness

Before deploying for family use:
- [ ] Test calls work reliably
- [ ] Verify call quality is acceptable
- [ ] Test with expected number of concurrent users
- [ ] Document any configuration changes needed
- [ ] Set up monitoring for call success rates

## 📞 Quick Test Commands

```bash
# Quick health check of voice stack
echo "=== Voice Stack Health Check ==="
docker ps | grep -E "(synapse|coturn|element)"
echo "TURN server status:"
docker logs voice-stack-coturn-1 --tail 5
echo "Synapse status:"
docker logs voice-stack-synapse-1 --tail 5
```

Remember: Voice calling requires good network connectivity and proper firewall configuration. Test locally first, then expand to external access!
