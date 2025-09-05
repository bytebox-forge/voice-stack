#!/usr/bin/env python3
"""
Matrix Synapse Admin User Verification Script

This script verifies that the admin user can authenticate and has admin privileges.
"""

import urllib.request
import urllib.parse
import urllib.error
import json
import base64
from typing import Dict, Any, Optional


def create_auth_header(username: str, password: str) -> str:
    """
    Create HTTP Basic Auth header.
    
    Args:
        username: Matrix username (without @server.com)
        password: User password
    
    Returns:
        Authorization header value
    """
    credentials = f"{username}:{password}"
    encoded_credentials = base64.b64encode(credentials.encode('utf-8')).decode('ascii')
    return f"Basic {encoded_credentials}"


def verify_admin_login(synapse_url: str, username: str, password: str) -> Dict[str, Any]:
    """
    Verify admin user can authenticate and check admin status.
    
    Args:
        synapse_url: Base URL of the Synapse server
        username: Admin username (without @server.com part)
        password: Admin password
    
    Returns:
        Dict containing verification results
    """
    # Test admin API endpoint - get user info
    user_id = f"@{username}:matrix.byte-box.org"
    admin_url = f"{synapse_url}/_synapse/admin/v2/users/{urllib.parse.quote(user_id, safe='')}"
    
    auth_header = create_auth_header(username, password)
    
    print(f"Verifying admin access for: {user_id}")
    print(f"Admin API URL: {admin_url}")
    
    try:
        req = urllib.request.Request(
            admin_url,
            headers={'Authorization': auth_header}
        )
        
        with urllib.request.urlopen(req, timeout=30) as response:
            status_code = response.getcode()
            response_text = response.read().decode('utf-8')
            
            if status_code == 200:
                user_data = json.loads(response_text)
                print("✓ Admin authentication successful!")
                print(f"User ID: {user_data.get('name', 'N/A')}")
                print(f"Display Name: {user_data.get('displayname', 'Not set')}")
                print(f"Is Admin: {user_data.get('admin', False)}")
                print(f"Is Deactivated: {user_data.get('deactivated', False)}")
                print(f"Creation Time: {user_data.get('creation_ts', 'N/A')}")
                
                return {
                    "success": True,
                    "user_data": user_data,
                    "is_admin": user_data.get('admin', False)
                }
            else:
                return {
                    "success": False,
                    "error": f"HTTP {status_code}",
                    "response": response_text
                }
                
    except urllib.error.HTTPError as e:
        error_response = ""
        try:
            error_response = e.read().decode('utf-8')
            error_data = json.loads(error_response)
            print(f"✗ HTTP Error {e.code}: {error_data}")
        except:
            print(f"✗ HTTP Error {e.code}: {e.reason}")
        
        return {
            "success": False,
            "error": f"HTTP {e.code}: {e.reason}",
            "response": error_response
        }
    except Exception as e:
        print(f"✗ Verification failed: {e}")
        return {"success": False, "error": str(e)}


def main():
    """Main function to verify admin user."""
    print("Matrix Synapse Admin User Verification")
    print("=" * 42)
    
    # Configuration
    synapse_url = "http://localhost:8008"
    username = "admin"
    password = "FamilyAdmin2025!"
    
    # Verify admin access
    result = verify_admin_login(synapse_url, username, password)
    
    if result.get("success"):
        if result.get("is_admin"):
            print("\n✓ Admin verification successful!")
            print("The user has admin privileges and can access admin APIs.")
        else:
            print("\n⚠ User authenticated but does not have admin privileges!")
    else:
        print(f"\n✗ Admin verification failed: {result.get('error')}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())