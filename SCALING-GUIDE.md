# Matrix Server Scaling Guide - When to Use PostgreSQL and Redis

## Current Setup: SQLite-Only (Optimal for Families)

Your voice-stack currently uses **SQLite only** - no PostgreSQL or Redis. This is the **optimal configuration** for family and small group deployments.

### ✅ SQLite is Perfect When:
- **User Count**: < 100 family/friends
- **Usage Pattern**: Light to moderate messaging, occasional voice/video calls
- **Administration**: Want zero database maintenance
- **Backup**: Simple file copy (`homeserver.db`)
- **Resources**: Want minimal RAM/CPU usage
- **Setup**: Want one-click deployment

### 📊 Performance Expectations:
- **Handles**: 20-50 active daily users easily
- **Message History**: Gigabytes of chat history without issues
- **Voice/Video**: Perfect for family group calls
- **Federation**: Works fine with moderate external server connections

---

## When to Upgrade to PostgreSQL

### 🐘 PostgreSQL Use Cases

**Upgrade to PostgreSQL when you experience:**

1. **High User Count** (500+ active users)
   - SQLite performance degrades with many concurrent connections
   - PostgreSQL handles concurrent reads/writes much better
   - Better query optimization for complex operations

2. **Large Message History** (10GB+ database)
   - SQLite files become unwieldy at large sizes
   - PostgreSQL handles large datasets more efficiently
   - Better performance with complex history queries

3. **Production/Enterprise Deployment**
   - Advanced backup/restore capabilities (pg_dump, point-in-time recovery)
   - Professional monitoring tools (pgAdmin, Grafana integration)
   - ACID compliance for critical business data
   - Connection pooling and advanced configuration options

4. **Heavy Federation Traffic**
   - Large federated servers (matrix.org, etc.) create complex queries
   - PostgreSQL handles joins across federated data better
   - Better performance with room directory searches

### 📈 PostgreSQL Performance Benefits:
- **Concurrent Users**: 1000+ simultaneous connections
- **Database Size**: 100GB+ message history
- **Query Speed**: Complex searches across large datasets
- **Reliability**: Enterprise-grade data integrity

### 💾 PostgreSQL Resource Requirements:
- **RAM**: 2GB+ dedicated to database
- **Storage**: Fast SSD recommended for large deployments
- **CPU**: Benefits from multi-core systems
- **Maintenance**: Requires regular vacuuming, monitoring

---

## When to Add Redis + Workers

### 🔴 Redis Use Cases

**Add Redis when you need horizontal scaling:**

1. **Multiple Synapse Workers** (Required for any worker setup)
   ```yaml
   # Example: Scaled deployment
   synapse-main:         # Main process (handles writes)
   synapse-generic:      # Generic worker (API requests)
   synapse-federation:   # Federation worker (server-to-server)
   synapse-media:        # Media worker (file uploads/downloads)
   synapse-client-sync:  # Client sync worker (message delivery)
   ```
   - Redis coordinates communication between workers
   - Essential for any multi-process setup

2. **High Traffic Server** (1000+ concurrent users)
   - Single Synapse process becomes CPU bottleneck
   - Workers distribute load across multiple CPU cores
   - Redis handles inter-worker communication and caching

3. **Performance Optimization**
   - Caching frequently accessed data (user profiles, room states)
   - Reducing database load on busy servers
   - Session storage for load-balanced setups

### 🚀 Redis Performance Benefits:
- **Concurrent Users**: 5000+ simultaneous connections
- **CPU Usage**: Distributes load across multiple cores
- **Response Time**: Faster API responses through caching
- **Scalability**: Horizontal scaling across multiple servers

### 🛠️ Redis Resource Requirements:
- **RAM**: 1GB+ for caching (depends on active users)
- **CPU**: Benefits from multi-core systems for workers
- **Complexity**: Requires worker configuration and monitoring
- **Maintenance**: Redis cluster management, worker health monitoring

---

## Migration Scenarios

### 🔄 Family to Community Server

**Scenario**: Your family server becomes popular with friends/neighbors
- **Threshold**: 100+ active users, slow message loading
- **Migration**: Add PostgreSQL, keep single Synapse process
- **Timeline**: Weekend maintenance window

### 🏢 Community to Enterprise

**Scenario**: Growing to company/organization scale
- **Threshold**: 500+ users, high CPU usage, federation load
- **Migration**: Add Redis + Workers + PostgreSQL
- **Timeline**: Planned maintenance with data migration

### 🌐 Enterprise to Public Server

**Scenario**: Running a public Matrix server
- **Threshold**: 1000+ users, 24/7 availability requirements
- **Migration**: Full horizontal scaling, monitoring, redundancy
- **Timeline**: Complete architecture redesign

---

## Migration Steps (When Needed)

### SQLite → PostgreSQL Migration

```bash
# 1. Backup current data
docker exec voice-stack-synapse cp /data/homeserver.db /data/backup.db

# 2. Export SQLite data
docker exec voice-stack-synapse python -m synapse.app.admin_cmd \
  export-data --output-directory /data/export

# 3. Add PostgreSQL service to docker-compose.yml
# 4. Update homeserver.yaml database configuration
# 5. Import data to PostgreSQL
# 6. Test and verify data integrity
```

### Single Process → Workers + Redis

```bash
# 1. Add Redis service to docker-compose.yml
# 2. Create worker configuration files
# 3. Add worker services to docker-compose.yml
# 4. Update homeserver.yaml for worker mode
# 5. Test worker communication
# 6. Monitor worker performance
```

---

## Resource Usage Comparison

### Current SQLite Setup:
- **RAM**: 512MB - 1GB total
- **CPU**: 1-2 cores sufficient
- **Storage**: 10-50GB for extensive history
- **Maintenance**: Virtually zero

### PostgreSQL Setup:
- **RAM**: 2-4GB total
- **CPU**: 2-4 cores recommended
- **Storage**: 50-500GB depending on scale
- **Maintenance**: Weekly monitoring, periodic optimization

### Redis + Workers Setup:
- **RAM**: 4-8GB total
- **CPU**: 4-8 cores utilized
- **Storage**: 100GB+ for large deployments
- **Maintenance**: Daily monitoring, worker health checks

---

## Decision Matrix

| Users | Message Volume | Federation | Database | Workers | Best For |
|-------|---------------|------------|----------|---------|----------|
| 1-50 | Light | Minimal | SQLite | Single | **Families** |
| 50-200 | Moderate | Some | SQLite/PostgreSQL | Single | Friend Groups |
| 200-1000 | Heavy | Moderate | PostgreSQL | Single | Communities |
| 1000+ | Very Heavy | Heavy | PostgreSQL | Multiple + Redis | **Enterprises** |

---

## Current Status: Perfect for Families! ✅

Your **SQLite-only** voice-stack is ideally configured for:
- ✅ Family deployments (5-50 users)
- ✅ Friend groups and small communities
- ✅ Minimal maintenance requirements
- ✅ Easy backup and migration
- ✅ Low resource usage
- ✅ Simple troubleshooting

**Bottom Line**: Don't add PostgreSQL or Redis unless you actually need them. Your current setup will handle family-scale usage for years without issues!

---

## Getting Help

If you're experiencing performance issues:
1. **Check user count**: `docker exec voice-stack-synapse sqlite3 /data/homeserver.db "SELECT COUNT(*) FROM users;"`
2. **Check database size**: `docker exec voice-stack-synapse ls -lh /data/homeserver.db`
3. **Monitor CPU/RAM**: `docker stats voice-stack-synapse`
4. **Consider upgrade**: Only if consistently hitting resource limits

**Remember**: Premature optimization is the root of all evil. Scale when you need to, not before!
