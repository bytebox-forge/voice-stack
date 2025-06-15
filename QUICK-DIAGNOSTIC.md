# Quick Connection Diagnostic

Since your Element Web container is running successfully (nginx logs show 200 responses), let's diagnose the connection issue:

## Step 1: Check What's Actually Running

Run this command to see the current status:

```bash
# Check all voice-stack containers
docker ps --filter "name=voice-stack" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

## Step 2: Test Synapse Specifically

The most likely issue is Synapse not responding. Test this:

```bash
# Test if Synapse is responding
curl -I http://localhost:8008

# Or test the API endpoint
curl http://localhost:8008/_matrix/client/versions
```

If these fail, check Synapse logs:

```bash
docker logs voice-stack-synapse | tail -50
```

## Step 3: Test Element Web Access

Since nginx is working, test if you can reach Element Web:

```bash
# Test Element Web directly
curl -I http://localhost:8080

# Should return HTTP/1.1 200 OK
```

## Step 4: Check Internal Container Communication

Test if Element Web can reach Synapse internally:

```bash
# Test from Element Web container to Synapse
docker exec voice-stack-element wget -q --spider http://synapse:8008/_matrix/client/versions
echo $?
# Should return 0 if successful
```

## Most Likely Issues:

1. **Synapse failed to start** - Check `docker logs voice-stack-synapse`
2. **Database not ready** - Synapse waiting for PostgreSQL
3. **Port not accessible** - Firewall or network issue
4. **Synapse configuration error** - homeserver.yaml has issues

## Quick Fix Commands:

```bash
# Restart just the Synapse container
docker restart voice-stack-synapse

# Or restart the entire stack
docker-compose -f docker-compose.portainer-standalone.yml restart
```

Please run the diagnostic commands above and share the results!
