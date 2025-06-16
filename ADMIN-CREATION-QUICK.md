# Quick Admin User Creation Guide

If the standard scripts aren't working, here are alternative methods to create your first admin user:

## Method 1: Direct Database Update (Most Reliable)

### Step 1: Create a regular user first
1. Go to Element Web (`http://your-server:8080`)
2. Click "Create Account"
3. Use your shared secret: `bytebox2025`
4. Create account with username like `admin`

### Step 2: Make the user admin via database
```bash
# Connect to PostgreSQL container
docker exec -it voice-stack-postgres psql -U synapse -d synapse

# Make your user admin (replace 'admin' with your actual username)
UPDATE users SET admin = 1 WHERE name = '@admin:matrix.byte-box.org';

# Verify the change
SELECT name, admin FROM users WHERE admin = 1;

# Exit
\q
```

## Method 2: Using Synapse Admin API

### Step 1: Get an access token
1. Login to Element with your user
2. Go to Settings → Help & About → Advanced
3. Copy your "Access Token"

### Step 2: Make user admin via API
```bash
# Replace YOUR_ACCESS_TOKEN and adjust the username/domain
curl -X PUT "http://your-server:8008/_synapse/admin/v1/users/@admin:matrix.byte-box.org/admin" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"admin": true}'
```

## Method 3: Using register_new_matrix_user (Container-specific)

### Find the correct container name and command:
```bash
# List all containers
docker ps

# Try different container names:
docker exec -it voice-stack-synapse-1 register_new_matrix_user --help
# OR
docker exec -it synapse register_new_matrix_user --help
# OR
docker exec -it voice-stack_synapse_1 register_new_matrix_user --help

# Once you find the right container, create admin:
docker exec -it CONTAINER_NAME register_new_matrix_user -u admin -p YourPassword -a -c /data/homeserver.yaml http://localhost:8008
```

## Method 4: Manual homeserver.yaml Edit (Advanced)

```bash
# Connect to Synapse container
docker exec -it voice-stack-synapse-1 bash

# Edit homeserver.yaml to temporarily allow open registration
echo "enable_registration: true" >> /data/homeserver.yaml
echo "enable_registration_without_verification: true" >> /data/homeserver.yaml

# Restart container
exit
docker restart voice-stack-synapse-1

# Now register normally via Element, then remove those lines and restart again
```

## Troubleshooting

### Container Name Issues
If containers have different names, find them:
```bash
docker ps | grep synapse
docker ps | grep postgres
```

### Database Connection Issues
Try these variations:
```bash
# Different database names
docker exec -it voice-stack-postgres psql -U synapse -d synapse_main
docker exec -it voice-stack-postgres psql -U postgres -d synapse

# Try with password prompt
docker exec -it voice-stack-postgres psql -U synapse -W -d synapse

# Check if database exists
docker exec -it voice-stack-postgres psql -U postgres -c "\l"

# Alternative: Use environment variables from .env
docker exec -it voice-stack-postgres psql -U synapse -d synapse -c "UPDATE users SET admin = 1 WHERE name = '@admin:matrix.byte-box.org';"
```

### Session Timeout Fix
If you get "session ended" errors, run the SQL command directly:
```bash
# Single command approach (avoids session timeout)
docker exec voice-stack-postgres psql -U synapse -d synapse -c "UPDATE users SET admin = 1 WHERE name = '@admin:matrix.byte-box.org';"

# Verify it worked
docker exec voice-stack-postgres psql -U synapse -d synapse -c "SELECT name, admin FROM users WHERE admin = 1;"
```

### Permission Issues
Make sure you're using the correct domain name in the user ID:
- Format: `@username:your-domain.com`
- Your domain from .env: `matrix.byte-box.org`
- So admin user would be: `@admin:matrix.byte-box.org`

### Database/Table Not Found Fix
If you get "relation 'users' does not exist", find the correct database and table:

```bash
# Step 1: List all databases
docker exec voice-stack-postgres psql -U postgres -c "\l"

# Step 2: Try different common database names
docker exec voice-stack-postgres psql -U postgres -d synapse -c "\dt"
docker exec voice-stack-postgres psql -U postgres -d homeserver -c "\dt" 
docker exec voice-stack-postgres psql -U postgres -d matrix -c "\dt"

# Step 3: Look for user-related tables (might be named differently)
docker exec voice-stack-postgres psql -U postgres -d synapse -c "\dt *user*"

# Step 4: If you find the right database, check table structure
docker exec voice-stack-postgres psql -U postgres -d CORRECT_DB_NAME -c "\d users"
```

### Alternative: Find the Database from Environment
Check what database Synapse is actually using:
```bash
# Check Synapse container logs for database info
docker logs voice-stack-synapse-1 2>&1 | grep -i database

# Check environment variables
docker exec voice-stack-synapse-1 env | grep -i postgres
```

### Once You Find the Correct Database and Table:
```bash
# Use the correct database name (replace DB_NAME with actual name)
docker exec voice-stack-postgres psql -U postgres -d DB_NAME -c "UPDATE users SET admin = 1 WHERE name = '@admin:matrix.byte-box.org';"

# Or if table has different name (like 'user' instead of 'users'):
docker exec voice-stack-postgres psql -U postgres -d DB_NAME -c "UPDATE user SET admin = 1 WHERE name = '@admin:matrix.byte-box.org';"
```

### PostgreSQL User Issues Fix
If you get "role 'postgres' does not exist", the container uses different default users:

```bash
# Try with the synapse user (most likely to work)
docker exec voice-stack-postgres psql -U synapse -d synapse -c "\l"

# If synapse user doesn't work, try finding what users exist
docker exec voice-stack-postgres psql -c "\du"

# Try connecting as root/admin user (container might use different defaults)
docker exec voice-stack-postgres psql -U root -c "\l"

# Alternative: Use environment variable authentication
docker exec -e PGPASSWORD=secure_postgres_password_2025 voice-stack-postgres psql -U synapse -d synapse -c "\l"
```

### Working Database Commands
Once you find the right user (likely 'synapse'), use these:

```bash
# List databases with synapse user
docker exec voice-stack-postgres psql -U synapse -d synapse -c "\l"

# List tables in synapse database
docker exec voice-stack-postgres psql -U synapse -d synapse -c "\dt"

# Look for user tables specifically  
docker exec voice-stack-postgres psql -U synapse -d synapse -c "\dt *user*"

# Make user admin (once you confirm table exists)
docker exec voice-stack-postgres psql -U synapse -d synapse -c "UPDATE users SET admin = 1 WHERE name = '@admin:matrix.byte-box.org';"
```

### Database Not Initialized Fix
If `\dt` shows "Did not find any relations" it means Synapse hasn't created its tables yet.

**Diagnosis Results:**
- ✅ Database `synapse` exists 
- ❌ No tables created (Synapse didn't initialize)
- 🔍 This means Synapse container failed to start properly

**Solution Steps:**
```bash
# Step 1: Check if Synapse container is running and healthy
docker ps | grep synapse
docker logs voice-stack-synapse-1 --tail 50

# Step 2: If Synapse has errors, restart it to trigger database initialization
docker restart voice-stack-synapse-1

# Step 3: Wait for initialization, then check logs
sleep 30
docker logs voice-stack-synapse-1 --tail 20

# Step 4: Verify tables were created
docker exec voice-stack-postgres psql -U synapse -d synapse -c "\dt"

# Step 5: Once tables exist, make user admin
docker exec voice-stack-postgres psql -U synapse -d synapse -c "UPDATE users SET admin = 1 WHERE name = '@admin:matrix.byte-box.org';"
```

### If Synapse Won't Start
Check the Synapse logs for configuration errors:
```bash
# Look for specific errors
docker logs voice-stack-synapse-1 2>&1 | grep -i error
docker logs voice-stack-synapse-1 2>&1 | grep -i "config"
docker logs voice-stack-synapse-1 2>&1 | grep -i "database"
```

### Working Synapse with Empty Tables Diagnosis

**If you can register users and login to Element, but `\dt` shows no tables:**

This means tables exist but in a different location. Try these:

```bash
# Check if tables are in a different schema
docker exec voice-stack-postgres psql -U synapse -d synapse -c "\dt *.*"

# Look in all schemas
docker exec voice-stack-postgres psql -U synapse -d synapse -c "SELECT schemaname, tablename FROM pg_tables WHERE tablename LIKE '%user%';"

# Check if using a different database entirely
docker exec voice-stack-postgres psql -U synapse -d postgres -c "\dt"

# Look for the users table across all databases
docker exec voice-stack-postgres psql -U synapse -c "SELECT current_database();"
```

### Alternative: Check Synapse's Database URL

```bash
# Check what database URL Synapse is actually using
docker exec voice-stack-synapse-1 grep -r "database" /data/homeserver.yaml
docker exec voice-stack-synapse-1 cat /data/homeserver.yaml | grep -A5 -B5 database
```

### Try Different Database Connection

```bash
# Maybe Synapse is using the 'postgres' database instead
docker exec voice-stack-postgres psql -U synapse -d postgres -c "\dt *user*"

# Or check if there's a schema prefix needed
docker exec voice-stack-postgres psql -U synapse -d synapse -c "SELECT table_name FROM information_schema.tables WHERE table_name LIKE '%user%';"
```

## Recommended Approach

**I recommend Method 1 (Database Update)** because:
1. It's the most reliable
2. Works regardless of container configuration
3. Direct database access is always available
4. Easy to verify the change

After creating your admin user, you can access the Synapse Admin panel at `http://your-server:8082` and manage everything through the web interface.

### SOLUTION FOUND: Synapse Using SQLite, Not PostgreSQL!

**The issue:** Your Synapse is configured to use SQLite (`/data/homeserver.db`) instead of PostgreSQL.

**SQLite Admin User Creation:**

```bash
# Connect to the SQLite database inside Synapse container
docker exec -it voice-stack-synapse sqlite3 /data/homeserver.db

# Inside SQLite prompt, run these commands:
.tables
SELECT name FROM users;
UPDATE users SET admin = 1 WHERE name = '@admin:matrix.byte-box.org';
SELECT name, admin FROM users WHERE admin = 1;
.quit
```

### Single Command Approach (No Interactive Session):
```bash
# Make user admin in one command
docker exec voice-stack-synapse sqlite3 /data/homeserver.db "UPDATE users SET admin = 1 WHERE name = '@admin:matrix.byte-box.org';"

# Verify it worked
docker exec voice-stack-synapse sqlite3 /data/homeserver.db "SELECT name, admin FROM users WHERE admin = 1;"
```

### Alternative: Switch to PostgreSQL (Optional)
If you want to use PostgreSQL instead of SQLite, you'd need to:
1. Update homeserver.yaml database configuration
2. Migrate existing data
3. Restart Synapse

But for now, the SQLite commands above will make your user admin!

### SQLite Command Not Found Fix

If `sqlite3` command is not available in the Synapse container, try these alternatives:

#### Method 1: Use Python to Access SQLite
```bash
# Use Python (which Synapse container definitely has) to access SQLite
docker exec voice-stack-synapse python3 -c "
import sqlite3
conn = sqlite3.connect('/data/homeserver.db')
cursor = conn.cursor()
cursor.execute('UPDATE users SET admin = 1 WHERE name = \"@admin:matrix.byte-box.org\"')
conn.commit()
cursor.execute('SELECT name, admin FROM users WHERE admin = 1')
print('Admin users:', cursor.fetchall())
conn.close()
"
```

#### Method 2: Install sqlite3 in Container
```bash
# Connect to container and install sqlite3
docker exec -it voice-stack-synapse bash
apt update && apt install sqlite3 -y
sqlite3 /data/homeserver.db "UPDATE users SET admin = 1 WHERE name = '@admin:matrix.byte-box.org';"
exit
```

#### Method 3: Use Synapse's Built-in Admin Commands
```bash
# Check if Synapse has admin commands available
docker exec voice-stack-synapse python -m synapse.app.admin_cmd --help

# Try using register_new_matrix_user with admin flag
docker exec voice-stack-synapse register_new_matrix_user -u newadmin -p password123 -a -c /data/homeserver.yaml http://localhost:8008
```

#### Method 4: Copy Database Out, Modify, Copy Back
```bash
# Copy database to host
docker cp voice-stack-synapse:/data/homeserver.db ./homeserver.db

# Use local sqlite3 (if available) or install it
sudo apt install sqlite3  # On Ubuntu/Debian
sqlite3 homeserver.db "UPDATE users SET admin = 1 WHERE name = '@admin:matrix.byte-box.org';"

# Copy back
docker cp ./homeserver.db voice-stack-synapse:/data/homeserver.db
docker restart voice-stack-synapse
```
