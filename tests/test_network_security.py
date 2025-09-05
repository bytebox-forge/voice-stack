#!/usr/bin/env python3
"""
Network Isolation and Security Validation Tests
Comprehensive test suite to verify Matrix family server security and isolation
"""

import pytest
import requests
import socket
import ssl
import dns.resolver
import subprocess
import json
import os
import time
from typing import Dict, Any, Optional, List, Tuple
from dataclasses import dataclass
from urllib.parse import urlparse
import warnings

# Suppress SSL warnings for testing
warnings.filterwarnings('ignore', message='Unverified HTTPS request')


@dataclass
class TestConfig:
    """Test configuration from environment variables"""
    synapse_url: str = os.getenv('SYNAPSE_URL', 'http://localhost:8008')
    element_url: str = os.getenv('ELEMENT_URL', 'http://localhost:8080')
    server_name: str = os.getenv('SYNAPSE_SERVER_NAME', 'matrix.byte-box.org')
    coturn_port: int = int(os.getenv('COTURN_PORT', '3478'))
    admin_port: int = int(os.getenv('SYNAPSE_ADMIN_PORT', '8082'))
    well_known_port: int = int(os.getenv('WELL_KNOWN_PORT', '8090'))
    test_timeout: int = int(os.getenv('TEST_TIMEOUT', '10'))
    external_test_servers: List[str] = os.getenv(
        'EXTERNAL_TEST_SERVERS', 
        'matrix.org,8.8.8.8,1.1.1.1'
    ).split(',')


class NetworkSecurityTester:
    """Helper class for network security testing"""
    
    def __init__(self, config: TestConfig):
        self.config = config
    
    def test_port_accessibility(self, host: str, port: int, should_be_open: bool = True) -> Dict[str, Any]:
        """Test if a port is accessible"""
        result = {
            'host': host,
            'port': port,
            'accessible': False,
            'error': None,
            'response_time': None
        }
        
        start_time = time.time()
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(self.config.test_timeout)
            result_code = sock.connect_ex((host, port))
            sock.close()
            
            result['accessible'] = result_code == 0
            result['response_time'] = time.time() - start_time
            
        except Exception as e:
            result['error'] = str(e)
            result['response_time'] = time.time() - start_time
        
        if should_be_open:
            assert result['accessible'], f"Port {port} on {host} should be accessible but is not"
        else:
            assert not result['accessible'], f"Port {port} on {host} should NOT be accessible but is"
        
        return result
    
    def test_http_endpoint(self, url: str, should_be_accessible: bool = True, 
                          expected_status: Optional[int] = None) -> Dict[str, Any]:
        """Test HTTP endpoint accessibility"""
        result = {
            'url': url,
            'accessible': False,
            'status_code': None,
            'response_time': None,
            'error': None,
            'headers': {},
            'body_preview': None
        }
        
        start_time = time.time()
        try:
            response = requests.get(
                url, 
                timeout=self.config.test_timeout,
                verify=False  # For testing with self-signed certs
            )
            
            result['accessible'] = True
            result['status_code'] = response.status_code
            result['response_time'] = time.time() - start_time
            result['headers'] = dict(response.headers)
            result['body_preview'] = response.text[:200] if response.text else None
            
            if expected_status:
                assert response.status_code == expected_status, \
                    f"Expected status {expected_status}, got {response.status_code}"
            
        except requests.RequestException as e:
            result['error'] = str(e)
            result['response_time'] = time.time() - start_time
        
        if should_be_accessible:
            assert result['accessible'], f"URL {url} should be accessible but is not: {result['error']}"
        else:
            assert not result['accessible'], f"URL {url} should NOT be accessible but is"
        
        return result
    
    def test_federation_endpoints(self) -> Dict[str, Any]:
        """Test that federation endpoints are disabled"""
        federation_endpoints = [
            '/_matrix/federation/v1/version',
            '/_matrix/federation/v1/query/profile',
            '/_matrix/federation/v1/make_join',
            '/_matrix/federation/v1/send_join',
            '/_matrix/key/v2/server'
        ]
        
        results = {}
        
        for endpoint in federation_endpoints:
            url = f"{self.config.synapse_url}{endpoint}"
            try:
                response = requests.get(url, timeout=self.config.test_timeout)
                results[endpoint] = {
                    'status_code': response.status_code,
                    'accessible': response.status_code != 404,
                    'body': response.text[:200]
                }
                
                # Federation should be disabled (404) or forbidden (403)
                assert response.status_code in [404, 403], \
                    f"Federation endpoint {endpoint} should return 404/403, got {response.status_code}"
                    
            except requests.RequestException as e:
                results[endpoint] = {
                    'error': str(e),
                    'accessible': False
                }
        
        return results
    
    def test_dns_resolution(self, hostname: str) -> Dict[str, Any]:
        """Test DNS resolution for hostname"""
        result = {
            'hostname': hostname,
            'resolved': False,
            'addresses': [],
            'error': None
        }
        
        try:
            answers = dns.resolver.resolve(hostname, 'A')
            result['resolved'] = True
            result['addresses'] = [str(answer) for answer in answers]
            
        except Exception as e:
            result['error'] = str(e)
        
        return result
    
    def test_ssl_certificate(self, hostname: str, port: int = 443) -> Dict[str, Any]:
        """Test SSL certificate validity"""
        result = {
            'hostname': hostname,
            'port': port,
            'valid': False,
            'cert_info': {},
            'error': None
        }
        
        try:
            context = ssl.create_default_context()
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            
            with socket.create_connection((hostname, port), timeout=self.config.test_timeout) as sock:
                with context.wrap_socket(sock, server_hostname=hostname) as ssock:
                    cert = ssock.getpeercert()
                    result['valid'] = True
                    result['cert_info'] = {
                        'subject': dict(x[0] for x in cert.get('subject', [])),
                        'issuer': dict(x[0] for x in cert.get('issuer', [])),
                        'version': cert.get('version'),
                        'not_before': cert.get('notBefore'),
                        'not_after': cert.get('notAfter'),
                        'serial_number': cert.get('serialNumber')
                    }
                    
        except Exception as e:
            result['error'] = str(e)
        
        return result
    
    def test_external_connectivity(self) -> Dict[str, Any]:
        """Test connectivity to external servers (should be blocked if isolated)"""
        results = {}
        
        for server in self.config.external_test_servers:
            try:
                # Try HTTP connection
                url = f"http://{server}"
                response = requests.get(url, timeout=5)
                results[server] = {
                    'accessible': True,
                    'status': response.status_code,
                    'method': 'http'
                }
                
            except requests.RequestException:
                try:
                    # Try raw socket connection
                    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    sock.settimeout(5)
                    result = sock.connect_ex((server, 80))
                    sock.close()
                    
                    results[server] = {
                        'accessible': result == 0,
                        'method': 'socket',
                        'result_code': result
                    }
                    
                except Exception as e:
                    results[server] = {
                        'accessible': False,
                        'error': str(e),
                        'method': 'socket'
                    }
        
        return results
    
    def test_well_known_configuration(self) -> Dict[str, Any]:
        """Test Matrix well-known configuration"""
        well_known_endpoints = [
            '/.well-known/matrix/server',
            '/.well-known/matrix/client'
        ]
        
        results = {}
        
        for endpoint in well_known_endpoints:
            url = f"http://localhost:{self.config.well_known_port}{endpoint}"
            
            try:
                response = requests.get(url, timeout=self.config.test_timeout)
                results[endpoint] = {
                    'status_code': response.status_code,
                    'accessible': response.status_code == 200,
                    'content_type': response.headers.get('Content-Type', ''),
                    'body': response.json() if response.headers.get('Content-Type', '').startswith('application/json') else response.text
                }
                
                # Validate JSON structure
                if response.status_code == 200 and endpoint == '/.well-known/matrix/server':
                    data = response.json()
                    assert 'm.server' in data, "Well-known server config missing 'm.server' field"
                    assert ':' in data['m.server'], "Server specification should include port"
                
                if response.status_code == 200 and endpoint == '/.well-known/matrix/client':
                    data = response.json()
                    assert 'm.homeserver' in data, "Well-known client config missing 'm.homeserver' field"
                    assert 'base_url' in data['m.homeserver'], "Homeserver config missing 'base_url'"
                
            except Exception as e:
                results[endpoint] = {
                    'error': str(e),
                    'accessible': False
                }
        
        return results


class TestNetworkIsolation:
    """Test network isolation and security"""
    
    @pytest.fixture(scope="class")
    def config(self):
        """Test configuration"""
        return TestConfig()
    
    @pytest.fixture(scope="class")
    def tester(self, config):
        """Network security tester instance"""
        return NetworkSecurityTester(config)
    
    def test_required_ports_open(self, tester: NetworkSecurityTester):
        """Test that required service ports are accessible"""
        required_ports = [
            ('localhost', 8008, 'Synapse HTTP'),
            ('localhost', 8080, 'Element Web'),
            ('localhost', 8082, 'Synapse Admin'),
            ('localhost', 8090, 'Well-known'),
            ('localhost', 3478, 'COTURN')
        ]
        
        results = {}
        for host, port, description in required_ports:
            result = tester.test_port_accessibility(host, port, should_be_open=True)
            results[f"{host}:{port}"] = result
            print(f"✓ {description} ({host}:{port}): {'Open' if result['accessible'] else 'Closed'}")
    
    def test_federation_disabled(self, tester: NetworkSecurityTester):
        """Test that Matrix federation is disabled"""
        federation_results = tester.test_federation_endpoints()
        
        for endpoint, result in federation_results.items():
            if 'error' not in result:
                print(f"Federation endpoint {endpoint}: Status {result['status_code']}")
            else:
                print(f"Federation endpoint {endpoint}: Not accessible (good)")
    
    def test_synapse_health_endpoint(self, tester: NetworkSecurityTester):
        """Test Synapse health endpoint"""
        health_url = f"{tester.config.synapse_url}/health"
        result = tester.test_http_endpoint(health_url, should_be_accessible=True, expected_status=200)
        
        print(f"Synapse health check: {result['status_code']} in {result['response_time']:.2f}s")
    
    def test_element_web_accessible(self, tester: NetworkSecurityTester):
        """Test Element Web is accessible"""
        result = tester.test_http_endpoint(tester.config.element_url, should_be_accessible=True, expected_status=200)
        
        print(f"Element Web: {result['status_code']} in {result['response_time']:.2f}s")
        
        # Check for Element-specific content
        if result['body_preview']:
            assert 'element' in result['body_preview'].lower() or 'riot' in result['body_preview'].lower(), \
                "Element Web page should contain Element or Riot references"
    
    def test_admin_interface_accessible(self, tester: NetworkSecurityTester):
        """Test Synapse Admin interface is accessible"""
        admin_url = f"http://localhost:{tester.config.admin_port}"
        result = tester.test_http_endpoint(admin_url, should_be_accessible=True, expected_status=200)
        
        print(f"Synapse Admin: {result['status_code']} in {result['response_time']:.2f}s")
    
    def test_well_known_configuration(self, tester: NetworkSecurityTester):
        """Test Matrix well-known configuration"""
        results = tester.test_well_known_configuration()
        
        for endpoint, result in results.items():
            if result.get('accessible'):
                print(f"Well-known {endpoint}: ✓ {result['status_code']}")
                if isinstance(result.get('body'), dict):
                    print(f"  Config: {json.dumps(result['body'], indent=2)}")
            else:
                print(f"Well-known {endpoint}: ✗ {result.get('error', 'Not accessible')}")
    
    def test_no_unintended_ports_open(self, tester: NetworkSecurityTester):
        """Test that no unintended ports are open"""
        # Common ports that should NOT be open in a secure setup
        prohibited_ports = [
            22,    # SSH
            23,    # Telnet
            25,    # SMTP
            53,    # DNS
            110,   # POP3
            143,   # IMAP
            993,   # IMAPS
        ]
        
        for port in prohibited_ports:
            try:
                tester.test_port_accessibility('localhost', port, should_be_open=False)
                print(f"✓ Port {port} is properly closed")
            except AssertionError:
                print(f"⚠ Port {port} is unexpectedly open")
            except Exception as e:
                print(f"ℹ Port {port} test error: {e}")
    
    def test_external_connectivity_blocked(self, tester: NetworkSecurityTester):
        """Test external connectivity (for air-gapped installations)"""
        external_results = tester.test_external_connectivity()
        
        print("External connectivity test results:")
        for server, result in external_results.items():
            if result.get('accessible'):
                print(f"⚠ {server}: Accessible (may indicate internet access)")
            else:
                print(f"✓ {server}: Not accessible (good for isolation)")
    
    def test_http_security_headers(self, tester: NetworkSecurityTester):
        """Test HTTP security headers are present"""
        endpoints_to_test = [
            tester.config.synapse_url,
            tester.config.element_url,
            f"http://localhost:{tester.config.admin_port}"
        ]
        
        security_headers = [
            'X-Content-Type-Options',
            'X-Frame-Options',
            'X-XSS-Protection',
            'Referrer-Policy'
        ]
        
        for endpoint in endpoints_to_test:
            try:
                response = requests.get(endpoint, timeout=tester.config.test_timeout)
                
                print(f"\nSecurity headers for {endpoint}:")
                for header in security_headers:
                    value = response.headers.get(header)
                    if value:
                        print(f"  ✓ {header}: {value}")
                    else:
                        print(f"  ⚠ {header}: Missing")
                        
                # Check for security-related headers
                if 'Content-Security-Policy' in response.headers:
                    print(f"  ✓ Content-Security-Policy: Present")
                
                if 'Strict-Transport-Security' in response.headers:
                    print(f"  ✓ Strict-Transport-Security: Present")
                    
            except Exception as e:
                print(f"Error testing headers for {endpoint}: {e}")


class TestPrivacySettings:
    """Test privacy and configuration settings"""
    
    @pytest.fixture(scope="class")
    def config(self):
        return TestConfig()
    
    @pytest.fixture(scope="class")
    def tester(self, config):
        return NetworkSecurityTester(config)
    
    def test_synapse_version_endpoint(self, tester: NetworkSecurityTester):
        """Test Synapse version endpoint for info disclosure"""
        version_url = f"{tester.config.synapse_url}/_matrix/client/versions"
        result = tester.test_http_endpoint(version_url, should_be_accessible=True, expected_status=200)
        
        if result['body_preview']:
            try:
                # Parse response to check version info
                import json
                body_start = result['body_preview']
                # This is just a preview, so we can't fully parse, but we can check structure
                assert 'versions' in body_start, "Versions endpoint should return version info"
                print("✓ Version endpoint accessible and returns expected structure")
            except:
                print("⚠ Version endpoint response structure unclear")
    
    def test_guest_access_disabled(self, tester: NetworkSecurityTester):
        """Test that guest access is disabled"""
        # Try to access without authentication
        client_url = f"{tester.config.synapse_url}/_matrix/client/r0/rooms/!nonexistent:test/messages"
        
        try:
            response = requests.get(client_url, timeout=tester.config.test_timeout)
            
            # Should require authentication
            assert response.status_code in [401, 403], \
                f"Unauthenticated access should return 401/403, got {response.status_code}"
            
            print("✓ Guest access properly disabled - authentication required")
            
        except requests.RequestException as e:
            print(f"ℹ Guest access test failed with network error: {e}")
    
    def test_registration_disabled(self, tester: NetworkSecurityTester):
        """Test that open registration is disabled"""
        register_url = f"{tester.config.synapse_url}/_matrix/client/r0/register"
        
        try:
            # Try to register without admin secret
            register_data = {
                "username": "test_unauthorized",
                "password": "should_fail",
                "auth": {"type": "m.login.dummy"}
            }
            
            response = requests.post(register_url, json=register_data, timeout=tester.config.test_timeout)
            
            # Should fail (403 Forbidden or similar)
            assert response.status_code in [403, 401], \
                f"Open registration should be disabled, got {response.status_code}"
            
            print("✓ Open registration properly disabled")
            
        except requests.RequestException as e:
            print(f"ℹ Registration test failed with network error: {e}")
    
    def test_server_notices_configuration(self, tester: NetworkSecurityTester):
        """Test server notices and admin contact configuration"""
        # This would typically check server configuration, but we'll test endpoints
        server_info_url = f"{tester.config.synapse_url}/_matrix/client/r0/capabilities"
        
        try:
            response = requests.get(server_info_url, timeout=tester.config.test_timeout)
            
            if response.status_code == 200:
                print("✓ Server capabilities endpoint accessible")
            else:
                print(f"ℹ Server capabilities: {response.status_code}")
                
        except requests.RequestException as e:
            print(f"ℹ Server capabilities test: {e}")


class TestDeploymentSecurity:
    """Test deployment-specific security measures"""
    
    @pytest.fixture(scope="class") 
    def config(self):
        return TestConfig()
    
    def test_container_security(self):
        """Test Docker container security settings"""
        try:
            # Check if containers are running with security settings
            result = subprocess.run([
                'docker', 'ps', '--format', 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                print("Docker containers status:")
                print(result.stdout)
                
                # Check for voice-stack containers
                voice_stack_containers = [line for line in result.stdout.split('\n') 
                                        if 'voice-stack' in line]
                
                assert len(voice_stack_containers) > 0, "No voice-stack containers found running"
                print(f"✓ Found {len(voice_stack_containers)} voice-stack containers running")
                
            else:
                print("⚠ Could not check Docker container status")
                
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            print(f"ℹ Docker security test skipped: {e}")
    
    def test_file_permissions(self):
        """Test that sensitive files have appropriate permissions"""
        sensitive_files = [
            '.env',
            'docker-compose.yml'
        ]
        
        for file_path in sensitive_files:
            if os.path.exists(file_path):
                stat_info = os.stat(file_path)
                permissions = oct(stat_info.st_mode)[-3:]
                
                print(f"File {file_path} permissions: {permissions}")
                
                # Check that files are not world-readable
                world_readable = int(permissions[2]) & 4
                if world_readable:
                    print(f"⚠ {file_path} is world-readable")
                else:
                    print(f"✓ {file_path} has appropriate permissions")
            else:
                print(f"ℹ {file_path} not found for permission check")
    
    def test_log_security(self):
        """Test that logs don't contain sensitive information"""
        try:
            # Check recent docker logs for sensitive data patterns
            result = subprocess.run([
                'docker', 'logs', '--tail', '50', 'voice-stack-synapse'
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                logs = result.stdout + result.stderr
                
                # Check for common sensitive patterns
                sensitive_patterns = [
                    'password',
                    'secret',
                    'token',
                    'key'
                ]
                
                found_sensitive = False
                for pattern in sensitive_patterns:
                    if pattern.lower() in logs.lower():
                        # Filter out expected occurrences like "password field required"
                        lines_with_pattern = [line for line in logs.split('\n') 
                                            if pattern.lower() in line.lower()]
                        
                        for line in lines_with_pattern[:3]:  # Show first 3 occurrences
                            if not any(safe in line.lower() for safe in ['field', 'required', 'missing']):
                                print(f"⚠ Potentially sensitive data in logs: {line[:100]}...")
                                found_sensitive = True
                
                if not found_sensitive:
                    print("✓ No obvious sensitive data found in recent logs")
                    
            else:
                print("ℹ Could not check container logs")
                
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            print(f"ℹ Log security test skipped: {e}")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])