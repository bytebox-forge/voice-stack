#!/bin/bash
# Working admin user creation script

USERNAME="admin"
PASSWORD="AdminPassword123!"
REG_SECRET="ByteBox_Matrix_2025_SuperSecretKey_Family"

echo "Getting registration nonce..."
nonce_response=$(curl -s http://localhost:8008/_synapse/admin/v1/register)
nonce=$(echo "$nonce_response" | grep -o '"nonce":"[^"]*"' | cut -d'"' -f4)

echo "Using nonce: $nonce"

if [[ -z "$nonce" ]]; then
    echo "Failed to get nonce"
    exit 1
fi

# Create HMAC
message="${nonce}${USERNAME}${PASSWORD}admin"
mac=$(echo -n "$message" | openssl dgst -sha1 -hmac "$REG_SECRET" | cut -d' ' -f2)

echo "Creating user with MAC: $mac"

response=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "{\"nonce\":\"$nonce\",\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"admin\":true,\"mac\":\"$mac\"}" \
  http://localhost:8008/_synapse/admin/v1/register)

echo "Response: $response"

if echo "$response" | grep -q "access_token"; then
    echo -e "\n✅ Admin user created successfully!"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
    echo "Server: matrix.byte-box.org"
    echo "Login URL: http://localhost:8080"
else
    echo -e "\n❌ Admin user creation failed"
    echo "Response: $response"
fi