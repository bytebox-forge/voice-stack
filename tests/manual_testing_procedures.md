# Manual Testing Procedures for Matrix Family Server

This document provides comprehensive manual testing procedures to validate your Matrix family communications server. These procedures complement the automated tests and cover scenarios that require human interaction or visual verification.

## Table of Contents

1. [Pre-Testing Setup](#pre-testing-setup)
2. [Matrix Synapse Server Testing](#matrix-synapse-server-testing)
3. [Element Web Client Testing](#element-web-client-testing)
4. [Element Call Voice/Video Testing](#element-call-voicevideo-testing)
5. [Network Isolation Testing](#network-isolation-testing)
6. [Deployment Validation](#deployment-validation)
7. [Family Usage Scenarios](#family-usage-scenarios)
8. [Troubleshooting Guide](#troubleshooting-guide)

## Pre-Testing Setup

### Requirements Checklist

Before starting manual testing, ensure:

- [ ] All services are running (`./deploy.sh start`)
- [ ] Service health checks pass (`./deploy.sh health`)
- [ ] Test user accounts are created
- [ ] Network connectivity is available
- [ ] Test devices/browsers are prepared

### Test Environment Preparation

1. **Create Test Users:**
   ```bash
   # Access Synapse Admin panel at http://localhost:8082
   # Or use registration shared secret to create users
   ```

2. **Prepare Test Devices:**
   - Primary testing browser (Chrome/Firefox)
   - Secondary browser/device for multi-user tests
   - Mobile device for mobile testing (optional)

3. **Test User Accounts:**
   - `alice_test` - Admin user
   - `bob_test` - Regular user
   - `charlie_test` - Additional user for group tests

## Matrix Synapse Server Testing

### 1. Server Health and Accessibility

#### Test: Server Startup Verification
**Objective:** Verify Matrix Synapse server starts and is accessible

**Steps:**
1. Navigate to `http://localhost:8008/health`
2. Verify response is `200 OK`
3. Navigate to `http://localhost:8008/_matrix/client/versions`
4. Verify JSON response with version information

**Expected Results:**
- Health endpoint returns HTTP 200
- Versions endpoint returns Matrix client-server API versions
- No error messages in server logs

#### Test: Federation Disabled Verification
**Objective:** Confirm federation is disabled for private family server

**Steps:**
1. Navigate to `http://localhost:8008/_matrix/federation/v1/version`
2. Try to access other federation endpoints
3. Check server logs for federation attempts

**Expected Results:**
- Federation endpoints return 404 Not Found
- No outbound federation connections in logs

### 2. User Registration and Authentication

#### Test: Admin-Only Registration
**Objective:** Verify only admins can create new accounts

**Steps:**
1. Navigate to Element Web (`http://localhost:8080`)
2. Try to register a new account without admin credentials
3. Access Synapse Admin panel (`http://localhost:8082`)
4. Create new user account as admin

**Expected Results:**
- Public registration fails with appropriate error
- Admin can successfully create accounts
- New users can log in with created credentials

#### Test: User Login Process
**Objective:** Verify user authentication works correctly

**Steps:**
1. Open Element Web in browser
2. Configure homeserver URL if needed
3. Enter test user credentials
4. Complete login process

**Expected Results:**
- Homeserver configuration accepts local server
- Login succeeds with valid credentials
- Login fails with invalid credentials
- User session persists across page refreshes

## Element Web Client Testing

### 1. Basic Client Functionality

#### Test: Client Interface Loading
**Objective:** Verify Element Web interface loads completely

**Steps:**
1. Navigate to `http://localhost:8080`
2. Wait for interface to fully load
3. Check for any JavaScript errors in console
4. Verify all UI components are visible

**Expected Results:**
- Interface loads without errors
- Login form or main interface appears
- No JavaScript console errors
- Responsive design works on different screen sizes

#### Test: Room Creation and Management
**Objective:** Test creating and managing rooms

**Steps:**
1. Log in as test user
2. Click "Create Room" or similar button
3. Fill in room name: "Family Chat"
4. Set room topic: "Main family communication room"
5. Create room and verify it appears in room list
6. Enter the room and verify room details

**Expected Results:**
- Room creation dialog opens correctly
- Room is created successfully
- Room appears in room list
- Room header shows correct name and topic
- User is automatically joined to new room

### 2. Messaging Functionality

#### Test: Basic Message Sending
**Objective:** Verify message sending and receiving

**Steps:**
1. Enter a created room
2. Type message in message composer
3. Press Enter to send message
4. Send various message types:
   - Plain text
   - Text with emojis
   - Long messages
   - Multiple consecutive messages

**Expected Results:**
- Messages appear immediately in timeline
- Timestamps are correct
- Message formatting is preserved
- Emoji rendering works correctly

#### Test: Message History and Scrolling
**Objective:** Test message persistence and history loading

**Steps:**
1. Send multiple messages in a room
2. Refresh the browser page
3. Scroll up to load message history
4. Leave room and rejoin

**Expected Results:**
- Message history persists after refresh
- Scrolling loads older messages
- Message order is maintained
- Rejoining room shows recent messages

### 3. Multi-User Interaction

#### Test: Room Invitations
**Objective:** Test inviting users to rooms

**Steps:**
1. As alice_test, create a room
2. Open room settings/info
3. Click "Invite users"
4. Enter bob_test's user ID: `@bob_test:your-server-name`
5. Send invitation

**Expected Results:**
- Invitation dialog opens correctly
- User search/input works
- Invitation is sent successfully
- Invited user sees invitation notification

#### Test: Cross-User Messaging
**Objective:** Test real-time messaging between users

**Steps:**
1. Open two browser windows/tabs
2. Log in as different users in each
3. Have bob_test accept alice_test's room invitation
4. Send messages from both users
5. Verify messages appear in real-time

**Expected Results:**
- Invitations are received and can be accepted
- Messages from both users appear correctly
- Real-time synchronization works
- Message ordering is correct

## Element Call Voice/Video Testing

### 1. Audio Call Testing

#### Test: 1-on-1 Voice Call
**Objective:** Test basic voice call functionality

**Prerequisites:**
- Two test users in the same room
- Microphone permissions granted
- Audio devices available

**Steps:**
1. As alice_test, start voice call in room
2. As bob_test (in second browser), accept call
3. Verify audio connection is established
4. Test microphone mute/unmute
5. End call from either side

**Expected Results:**
- Call starts successfully
- Both users can hear each other
- Mute controls work correctly
- Call ends cleanly for both users

#### Test: Group Voice Call
**Objective:** Test voice calls with multiple participants

**Prerequisites:**
- Three or more test users in same room
- Microphone permissions for all

**Steps:**
1. Start voice call with multiple users
2. Have each user join the call
3. Verify audio quality with multiple participants
4. Test speaking indicators
5. Test participant leaving/rejoining

**Expected Results:**
- Multiple users can join call
- Audio mixing works correctly
- Speaking indicators show active speakers
- Users can leave/rejoin without issues

### 2. Video Call Testing

#### Test: 1-on-1 Video Call
**Objective:** Test video call functionality

**Prerequisites:**
- Camera permissions granted
- Video devices available

**Steps:**
1. Start video call between two users
2. Verify video streams are working
3. Test camera on/off toggle
4. Test video quality and synchronization
5. Test screen sharing (if available)

**Expected Results:**
- Video streams display correctly
- Camera controls work properly
- Video and audio stay synchronized
- Screen sharing works if implemented

#### Test: Group Video Call
**Objective:** Test video calls with multiple participants

**Steps:**
1. Start group video call
2. Have multiple users enable video
3. Verify video grid layout
4. Test video performance with multiple streams

**Expected Results:**
- Multiple video streams display correctly
- UI adapts to number of participants
- Performance remains acceptable
- Video controls work for all participants

### 3. Call Quality and Reliability

#### Test: Network Interruption Recovery
**Objective:** Test call recovery after network issues

**Steps:**
1. Start voice/video call
2. Temporarily disable network connection
3. Re-enable network connection
4. Verify call recovery

**Expected Results:**
- Call attempts to reconnect automatically
- Audio/video resumes after reconnection
- Call quality indicators show connection status

## Network Isolation Testing

### 1. External Access Verification

#### Test: Internet Connectivity Check
**Objective:** Verify server behavior with external internet

**Steps:**
1. Try to access external Matrix servers
2. Attempt federation with matrix.org
3. Check for external DNS resolution
4. Monitor outbound network connections

**Expected Results:**
- Federation attempts should fail (if disabled)
- External Matrix servers cannot connect to your server
- Only necessary outbound connections are made

#### Test: Port Accessibility
**Objective:** Verify only required ports are accessible

**Steps:**
1. Scan open ports from external network
2. Test accessibility of each service port
3. Verify no unexpected ports are open

**Expected Results:**
- Only configured ports (8008, 8080, 8082, 8090, 3478) are accessible
- No additional services are exposed
- Firewall rules are working correctly

### 2. Privacy and Security Verification

#### Test: Guest Access Disabled
**Objective:** Verify guest access is properly disabled

**Steps:**
1. Try to access rooms without authentication
2. Attempt to register without admin privileges
3. Test Matrix client API without credentials

**Expected Results:**
- Unauthenticated access is denied
- Guest registration is blocked
- API returns appropriate authentication errors

## Deployment Validation

### 1. Clean Environment Deployment

#### Test: Fresh Installation
**Objective:** Verify deployment works on clean system

**Steps:**
1. Prepare clean test environment (VM or container)
2. Copy only essential project files
3. Follow deployment documentation
4. Verify all services start correctly

**Expected Results:**
- Deployment completes without manual intervention
- All services start and pass health checks
- Configuration is properly applied
- No missing dependencies

### 2. Configuration Flexibility

#### Test: Custom Configuration
**Objective:** Verify configuration can be customized

**Steps:**
1. Modify `.env` file with custom values:
   - Different server name
   - Custom ports
   - Modified settings
2. Redeploy with new configuration
3. Verify changes are applied

**Expected Results:**
- Configuration changes are properly applied
- Services restart with new settings
- No configuration conflicts occur
- Documentation matches actual behavior

## Family Usage Scenarios

### 1. Daily Family Communication

#### Scenario: Family Chat Setup
**Objective:** Test typical family communication setup

**Steps:**
1. Admin creates family members as users
2. Create "Family General" room
3. Invite all family members
4. Test various message types:
   - Text messages
   - Photo sharing
   - File sharing
   - Emoji reactions

**Expected Results:**
- Easy user and room management
- Reliable message delivery
- Media sharing works smoothly
- User experience is intuitive

#### Scenario: Group Planning
**Objective:** Test family event planning usage

**Steps:**
1. Create "Vacation Planning" room
2. Share documents and images
3. Have threaded discussions
4. Use voice calls for quick discussions

**Expected Results:**
- Document sharing is seamless
- Conversations stay organized
- Voice calls provide quick communication
- Message history preserves planning details

### 2. Emergency Communication

#### Test: Service Reliability
**Objective:** Test system reliability for emergency use

**Steps:**
1. Simulate high message volume
2. Test with poor network conditions
3. Verify message delivery during peak usage
4. Test voice calls under stress

**Expected Results:**
- Messages are delivered reliably
- System handles increased load
- Voice calls remain functional
- No message loss occurs

## Troubleshooting Guide

### Common Issues and Solutions

#### Connection Issues
- **Problem:** Cannot connect to Element Web
- **Check:** Service status, network connectivity, firewall
- **Solution:** Restart services, check logs

#### Call Issues
- **Problem:** Voice/video calls not working
- **Check:** Browser permissions, TURN server, network
- **Solution:** Grant permissions, check COTURN configuration

#### Performance Issues
- **Problem:** Slow message delivery or interface
- **Check:** Server resources, database performance
- **Solution:** Check logs, monitor resource usage

### Validation Checklist

Use this checklist to verify your Matrix family server is working correctly:

#### Core Functionality
- [ ] Matrix Synapse server starts and responds
- [ ] Element Web interface loads completely
- [ ] User registration (admin-only) works
- [ ] User login/logout functions correctly
- [ ] Room creation and management works
- [ ] Message sending/receiving is reliable
- [ ] File uploads and downloads work

#### Communication Features
- [ ] Real-time messaging between users
- [ ] Message history is preserved
- [ ] Room invitations work correctly
- [ ] Voice calls connect successfully
- [ ] Video calls display properly
- [ ] Group calls support multiple users
- [ ] Screen sharing functions (if enabled)

#### Security and Privacy
- [ ] Federation is disabled
- [ ] Guest access is blocked
- [ ] Only authorized users can register
- [ ] External connectivity is limited
- [ ] No unintended ports are exposed

#### Administration
- [ ] Admin interface is accessible
- [ ] User management functions work
- [ ] Server settings can be modified
- [ ] Logs are accessible and informative
- [ ] Backup procedures are documented

#### Deployment
- [ ] Clean installation is possible
- [ ] Configuration is flexible
- [ ] All dependencies are included
- [ ] Documentation is accurate and complete

### Final Validation

After completing all tests, your Matrix family server should provide:

1. **Reliable Communication:** Messages and calls work consistently
2. **Privacy Protection:** No external access, federation disabled
3. **Easy Management:** Simple user and room administration
4. **Family-Friendly:** Intuitive interface suitable for all ages
5. **Robust Performance:** Handles family-sized usage loads

If all tests pass, your Matrix family server is ready for production use!

---

**Note:** Keep this document updated as you add new features or modify configurations. Regular testing ensures your family communication server remains secure and functional.