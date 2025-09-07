#!/usr/bin/env python3
"""
Voice Stack Portability Validation Script
Checks environment setup and configuration for common portability issues
"""

import os
import sys
import subprocess
import json
from pathlib import Path
from typing import Dict, List, Any

class PortabilityValidator:
    def __init__(self):
        self.issues = []
        self.warnings = []
        self.info = []
        
    def add_issue(self, message: str):
        self.issues.append(f"❌ {message}")
        
    def add_warning(self, message: str):
        self.warnings.append(f"⚠️  {message}")
        
    def add_info(self, message: str):
        self.info.append(f"ℹ️  {message}")
        
    def check_docker_setup(self) -> bool:
        """Check Docker and Docker Compose availability"""
        print("🔍 Checking Docker setup...")
        
        # Check Docker
        try:
            result = subprocess.run(['docker', '--version'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                self.add_info(f"Docker found: {result.stdout.strip()}")
            else:
                self.add_issue("Docker command failed")
                return False
        except (subprocess.TimeoutExpired, FileNotFoundError):
            self.add_issue("Docker not found or not accessible")
            return False
        
        # Check Docker permissions
        try:
            result = subprocess.run(['docker', 'ps'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                self.add_info("Docker permissions OK")
            else:
                self.add_issue("Cannot access Docker (permission denied?)")
                return False
        except (subprocess.TimeoutExpired, FileNotFoundError):
            self.add_issue("Cannot test Docker permissions")
            return False
        
        # Check Docker Compose
        compose_found = False
        
        # Try docker compose (v2)
        try:
            result = subprocess.run(['docker', 'compose', 'version'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                self.add_info(f"Docker Compose v2 found: {result.stdout.strip()}")
                compose_found = True
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
        
        # Try docker-compose (v1)
        if not compose_found:
            try:
                result = subprocess.run(['docker-compose', '--version'], 
                                      capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    self.add_info(f"Docker Compose v1 found: {result.stdout.strip()}")
                    compose_found = True
            except (subprocess.TimeoutExpired, FileNotFoundError):
                pass
        
        if not compose_found:
            self.add_issue("Neither 'docker compose' nor 'docker-compose' found")
            return False
            
        return True
    
    def check_files(self) -> bool:
        """Check required files exist"""
        print("📁 Checking required files...")
        
        required_files = [
            'docker-compose.yml',
            '.env.example',
            'Dockerfile.element'
        ]
        
        all_exist = True
        for file_path in required_files:
            if Path(file_path).exists():
                self.add_info(f"Found: {file_path}")
            else:
                self.add_issue(f"Missing required file: {file_path}")
                all_exist = False
        
        # Check .env file
        if Path('.env').exists():
            self.add_info("Found: .env")
        else:
            self.add_warning("No .env file found. Copy .env.example to .env and configure it.")
        
        return all_exist
    
    def check_compose_syntax(self) -> bool:
        """Validate docker-compose.yml syntax"""
        print("🔧 Validating Docker Compose syntax...")
        
        try:
            # Try to parse the compose file
            result = subprocess.run(['docker', 'compose', 'config'], 
                                  capture_output=True, text=True, timeout=30)
            if result.returncode == 0:
                self.add_info("Docker Compose syntax is valid")
                return True
            else:
                self.add_issue(f"Docker Compose syntax error: {result.stderr}")
                return False
        except (subprocess.TimeoutExpired, FileNotFoundError):
            # Try with docker-compose
            try:
                result = subprocess.run(['docker-compose', 'config'], 
                                      capture_output=True, text=True, timeout=30)
                if result.returncode == 0:
                    self.add_info("Docker Compose syntax is valid")
                    return True
                else:
                    self.add_issue(f"Docker Compose syntax error: {result.stderr}")
                    return False
            except (subprocess.TimeoutExpired, FileNotFoundError):
                self.add_warning("Could not validate Docker Compose syntax")
                return True
    
    def check_environment_variables(self) -> bool:
        """Check environment variable configuration"""
        print("🔐 Checking environment variables...")
        
        if not Path('.env').exists():
            self.add_warning("No .env file found - using defaults and command line environment")
            return True
        
        # Load .env file
        env_vars = {}
        try:
            with open('.env', 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        env_vars[key.strip()] = value.strip()
        except Exception as e:
            self.add_issue(f"Could not read .env file: {e}")
            return False
        
        # Check required variables
        required_vars = [
            'SYNAPSE_SERVER_NAME',
            'POSTGRES_PASSWORD',
            'REGISTRATION_SHARED_SECRET',
            'COTURN_STATIC_AUTH_SECRET'
        ]
        
        all_set = True
        for var in required_vars:
            value = env_vars.get(var, os.getenv(var))
            if not value:
                self.add_issue(f"Required environment variable not set: {var}")
                all_set = False
            elif value in ['your_strong_password_here', 'CHANGE_ME_GENERATE_STRONG_PASSWORD', 
                          'CHANGE_ME_GENERATE_STRONG_SECRET']:
                self.add_issue(f"Environment variable {var} uses placeholder value")
                all_set = False
            else:
                self.add_info(f"Environment variable {var} is set")
        
        # Check for common domain issues
        server_name = env_vars.get('SYNAPSE_SERVER_NAME', os.getenv('SYNAPSE_SERVER_NAME'))
        if server_name:
            if server_name == 'matrix.byte-box.org':
                self.add_warning("SYNAPSE_SERVER_NAME uses example domain - update for production")
            elif server_name == 'localhost' or '127.0.0.1' in server_name:
                self.add_warning("SYNAPSE_SERVER_NAME uses localhost - may cause issues with clients")
        
        return all_set
    
    def check_volumes(self) -> bool:
        """Check if external volumes exist"""
        print("💾 Checking Docker volumes...")
        
        required_volumes = [
            'voice-stack_postgres_data',
            'voice-stack_synapse_data',
            'voice-stack_media_store',
            'voice-stack_coturn_data'
        ]
        
        try:
            result = subprocess.run(['docker', 'volume', 'ls', '--format', 'json'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode != 0:
                self.add_warning("Could not list Docker volumes")
                return True
            
            existing_volumes = set()
            for line in result.stdout.strip().split('\n'):
                if line:
                    try:
                        volume_info = json.loads(line)
                        existing_volumes.add(volume_info.get('Name', ''))
                    except json.JSONDecodeError:
                        pass
            
            all_exist = True
            for volume in required_volumes:
                if volume in existing_volumes:
                    self.add_info(f"Volume exists: {volume}")
                else:
                    self.add_issue(f"Missing external volume: {volume}")
                    all_exist = False
            
            if not all_exist:
                self.add_info("Create missing volumes with: docker volume create <volume_name>")
                
            return all_exist
            
        except (subprocess.TimeoutExpired, FileNotFoundError):
            self.add_warning("Could not check Docker volumes")
            return True
    
    def check_ports(self) -> bool:
        """Check if required ports are available"""
        print("🔌 Checking port availability...")
        
        import socket
        
        ports = [8008, 8080, 8082, 8090, 3478]
        all_available = True
        
        for port in ports:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1)
            try:
                result = sock.connect_ex(('127.0.0.1', port))
                if result == 0:
                    self.add_warning(f"Port {port} is already in use")
                    all_available = False
                else:
                    self.add_info(f"Port {port} is available")
            except Exception:
                self.add_info(f"Port {port} appears available")
            finally:
                sock.close()
        
        return all_available
    
    def generate_report(self) -> bool:
        """Generate final validation report"""
        print("\n" + "="*60)
        print("🎯 VOICE STACK PORTABILITY VALIDATION REPORT")
        print("="*60)
        
        if self.info:
            print("\n✅ PASSED CHECKS:")
            for item in self.info:
                print(f"  {item}")
        
        if self.warnings:
            print("\n⚠️  WARNINGS:")
            for item in self.warnings:
                print(f"  {item}")
        
        if self.issues:
            print("\n❌ ISSUES FOUND:")
            for item in self.issues:
                print(f"  {item}")
        
        print(f"\n📊 SUMMARY:")
        print(f"  ✅ Passed: {len(self.info)}")
        print(f"  ⚠️  Warnings: {len(self.warnings)}")
        print(f"  ❌ Issues: {len(self.issues)}")
        
        if self.issues:
            print("\n🚨 DEPLOYMENT NOT RECOMMENDED")
            print("   Please fix the issues above before deploying.")
            return False
        else:
            print("\n🎉 DEPLOYMENT READY")
            if self.warnings:
                print("   Some warnings found - review before production use.")
            else:
                print("   All checks passed!")
            return True

def main():
    """Main validation function"""
    print("🚀 Voice Stack Portability Validator")
    print("Checking environment for common deployment issues...\n")
    
    validator = PortabilityValidator()
    
    # Run all checks
    checks = [
        validator.check_docker_setup(),
        validator.check_files(),
        validator.check_compose_syntax(),
        validator.check_environment_variables(),
        validator.check_volumes(),
        validator.check_ports()
    ]
    
    # Generate report
    success = validator.generate_report()
    
    if success:
        print("\n🎯 NEXT STEPS:")
        print("  1. Deploy using: docker compose up -d")
        print("  2. Or deploy via Portainer using the stack configuration")
        print("  3. Create admin user once containers are running")
        print("  4. Configure your reverse proxy")
        print("  5. Test Element Web access")
    else:
        print("\n🔧 RECOMMENDED ACTIONS:")
        if not Path('.env').exists():
            print("  1. Copy .env.example to .env")
            print("  2. Edit .env with your domain and generated secrets")
        print("  3. Create missing Docker volumes")
        print("  4. Fix any Docker setup issues")
        print("  5. Re-run this validator")
    
    return 0 if success else 1

if __name__ == '__main__':
    sys.exit(main())
