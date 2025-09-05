#!/bin/bash
# Simple admin user creation script

USERNAME="admin"
PASSWORD="AdminPassword123!"
REG_SECRET="ByteBox_Matrix_2025_SuperSecretKey_Family"

echo "Creating admin user..."

nonce=$(openssl rand -hex 32)
echo "Generated nonce: $nonce"

message="${nonce}${USERNAME}${PASSWORD}admin"
mac=$(echo -n "$message" | openssl dgst -sha1 -hmac "$REG_SECRET" | cut -d' ' -f2)
echo "Generated MAC: $mac"

curl -X POST \
  -H "Content-Type: application/json" \
  -d "{\"nonce\":\"$nonce\",\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"admin\":true,\"mac\":\"$mac\"}" \
  http://localhost:8008/_synapse/admin/v1/register

echo -e "\n\nAdmin user creation attempted."
echo "Username: $USERNAME"
echo "Password: $PASSWORD"
echo "Server: matrix.byte-box.org"