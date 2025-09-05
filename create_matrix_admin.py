#!/usr/bin/env python3
"""
Matrix Synapse Admin User Registration Script

This script creates an admin user using the shared secret registration method.
It calculates the proper HMAC-SHA1 hash and sends the registration request.
"""

import hmac
import hashlib
import urllib.request
import urllib.parse
import urllib.error
import json
from typing import Dict, Any


def calculate_hmac(secret: str, nonce: str, username: str, password: str, is_admin: bool = True) -> str:
    """
    Calculate HMAC-SHA1 for Matrix Synapse registration.
    
    Args:
        secret: Registration shared secret from homeserver.yaml
        nonce: Nonce obtained from the registration API
        username: Desired username
        password: User password
        is_admin: Whether the user should be an admin
    
    Returns:
        HMAC-SHA1 hash as hexadecimal string
    """
    admin_flag = "admin" if is_admin else "notadmin"
    
    # Construct the message as per Synapse specification
    message = f"{nonce}\x00{username}\x00{password}\x00{admin_flag}"
    
    # Calculate HMAC-SHA1
    mac = hmac.new(
        secret.encode('utf-8'),
        message.encode('utf-8'),
        hashlib.sha1
    )
    
    return mac.hexdigest()


def get_nonce(synapse_url: str) -> str:
    """
    Get a fresh nonce from the Synapse registration API.
    
    Args:
        synapse_url: Base URL of the Synapse server
    
    Returns:
        Fresh nonce string
    """
    nonce_url = f"{synapse_url}/_synapse/admin/v1/register"
    
    print(f"Fetching fresh nonce from: {nonce_url}")
    
    try:
        with urllib.request.urlopen(nonce_url, timeout=30) as response:
            status_code = response.getcode()
            response_text = response.read().decode('utf-8')
            
            if status_code == 200:
                data = json.loads(response_text)
                nonce = data.get('nonce')
                print(f"✓ Fresh nonce obtained: {nonce}")
                return nonce
            else:
                raise Exception(f"Failed to get nonce: HTTP {status_code}")
                
    except Exception as e:
        print(f"✗ Failed to get nonce: {e}")
        raise


def register_admin_user(
    synapse_url: str,
    secret: str,
    username: str,
    password: str,
    server_name: str,
    nonce: str = None
) -> Dict[str, Any]:
    """
    Register an admin user with Matrix Synapse.
    
    Args:
        synapse_url: Base URL of the Synapse server
        secret: Registration shared secret
        username: Desired username
        password: User password
        server_name: Server name for the Matrix homeserver
        nonce: Optional nonce (if not provided, a fresh one will be obtained)
    
    Returns:
        API response as dictionary
    """
    # Get fresh nonce if not provided
    if nonce is None:
        nonce = get_nonce(synapse_url)
    
    # Calculate HMAC
    mac = calculate_hmac(secret, nonce, username, password, is_admin=True)
    
    # Prepare registration data
    registration_data = {
        "nonce": nonce,
        "username": username,
        "password": password,
        "admin": True,
        "mac": mac
    }
    
    # API endpoint
    register_url = f"{synapse_url}/_synapse/admin/v1/register"
    
    print(f"Registering admin user: {username}")
    print(f"Server: {synapse_url}")
    print(f"Registration URL: {register_url}")
    print(f"HMAC calculated: {mac}")
    print("\nSending registration request...")
    
    # Send POST request
    try:
        # Prepare request data
        json_data = json.dumps(registration_data).encode('utf-8')
        
        # Create request
        req = urllib.request.Request(
            register_url,
            data=json_data,
            headers={'Content-Type': 'application/json'}
        )
        
        # Send request
        with urllib.request.urlopen(req, timeout=30) as response:
            status_code = response.getcode()
            response_text = response.read().decode('utf-8')
            
            print(f"Response status: {status_code}")
            
            if status_code == 200:
                result = json.loads(response_text)
                print("✓ Admin user created successfully!")
                print(f"User ID: {result.get('user_id', 'N/A')}")
                print(f"Home server: {result.get('home_server', 'N/A')}")
                return result
            else:
                print(f"✗ Registration failed with status {status_code}")
                try:
                    error_data = json.loads(response_text)
                    print(f"Error: {error_data}")
                except:
                    print(f"Error response: {response_text}")
                return {"error": response_text, "status_code": status_code}
                
    except urllib.error.HTTPError as e:
        print(f"✗ HTTP Error {e.code}: {e.reason}")
        try:
            error_response = e.read().decode('utf-8')
            error_data = json.loads(error_response)
            print(f"Error details: {error_data}")
        except:
            print(f"Error response: {error_response if 'error_response' in locals() else 'Unable to read error response'}")
        return {"error": f"HTTP {e.code}: {e.reason}", "status_code": e.code}
    except Exception as e:
        print(f"✗ Request failed: {e}")
        return {"error": str(e)}


def main():
    """Main function to execute the admin user registration."""
    # Configuration
    config = {
        "synapse_url": "http://localhost:8008",
        "secret": "455f386d43e96981b60932461d5b807e4d8cf1ace6d34c8c2ff1a65254c78417",
        "username": "admin",
        "password": "FamilyAdmin2025!",
        "server_name": "matrix.byte-box.org"
    }
    
    print("Matrix Synapse Admin User Registration")
    print("=" * 40)
    
    # Register the admin user (will fetch fresh nonce automatically)
    result = register_admin_user(**config)
    
    if "error" not in result:
        print("\n✓ Registration completed successfully!")
        print(f"You can now login with:")
        print(f"  Username: @{config['username']}:{config['server_name']}")
        print(f"  Password: {config['password']}")
    else:
        print(f"\n✗ Registration failed: {result.get('error')}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())