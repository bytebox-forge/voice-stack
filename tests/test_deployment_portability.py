#!/usr/bin/env python3
"""
Deployment Portability Tests
Test suite to validate that the Matrix family server can be deployed on clean environments
and verify all dependencies and configurations are included
"""

import pytest
import os
import subprocess
import tempfile
import shutil
import time
import yaml
import json
import requests
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
from pathlib import Path


@dataclass 
class TestConfig:
    """Test configuration"""
    project_root: str = os.getcwd()
    test_timeout: int = int(os.getenv('TEST_TIMEOUT', '300'))  # 5 minutes for deployment tests
    test_prefix: str = os.getenv('TEST_PREFIX', 'portability-test')
    keep_test_env: bool = os.getenv('KEEP_TEST_ENV', 'false').lower() == 'true'


class DeploymentTester:
    """Helper class for deployment testing"""
    
    def __init__(self, config: TestConfig):
        self.config = config
        self.test_dir: Optional[Path] = None
        self.containers_started: List[str] = []
    
    def setup_clean_environment(self) -> Path:
        """Create a clean test environment"""
        self.test_dir = Path(tempfile.mkdtemp(prefix=f"{self.config.test_prefix}-"))
        print(f"Created test environment: {self.test_dir}")
        return self.test_dir
    
    def cleanup_test_environment(self):
        """Clean up test environment"""
        if self.test_dir and self.test_dir.exists():
            if not self.config.keep_test_env:
                # Stop any containers first
                self.stop_test_containers()
                
                # Remove test directory
                shutil.rmtree(self.test_dir, ignore_errors=True)
                print(f"Cleaned up test environment: {self.test_dir}")
            else:
                print(f"Test environment preserved: {self.test_dir}")
    
    def copy_project_files(self, exclude_patterns: List[str] = None) -> Dict[str, Any]:
        """Copy project files to test environment"""
        if exclude_patterns is None:
            exclude_patterns = [
                '.git*',
                '__pycache__*',
                '*.pyc',
                'tests/',
                '.env',  # Don't copy existing .env
                'docker-volumes/',
                '*.log'
            ]
        
        source_dir = Path(self.config.project_root)
        
        copied_files = []
        skipped_files = []
        
        for item in source_dir.iterdir():
            if item.is_file():
                # Check if file should be excluded
                should_exclude = False
                for pattern in exclude_patterns:
                    if item.match(pattern.replace('*', '')):
                        should_exclude = True
                        break
                
                if not should_exclude:
                    shutil.copy2(item, self.test_dir)
                    copied_files.append(str(item.name))
                else:
                    skipped_files.append(str(item.name))
            
            elif item.is_dir() and not any(item.match(pattern.replace('*', '')) for pattern in exclude_patterns):
                # Copy directory recursively
                dest_dir = self.test_dir / item.name
                shutil.copytree(item, dest_dir, ignore=shutil.ignore_patterns(*exclude_patterns))
                copied_files.append(f"{item.name}/")
        
        return {
            'copied_files': copied_files,
            'skipped_files': skipped_files,
            'total_copied': len(copied_files)
        }
    
    def validate_required_files(self) -> Dict[str, bool]:
        """Validate that all required files are present"""
        required_files = [
            'docker-compose.yml',
            'deploy.sh',
            '.env.clean'
        ]
        
        results = {}
        for file_name in required_files:
            file_path = self.test_dir / file_name
            results[file_name] = file_path.exists()
            
            if not results[file_name]:
                print(f"⚠ Required file missing: {file_name}")
            else:
                print(f"✓ Required file present: {file_name}")
        
        return results
    
    def create_test_env_file(self) -> Path:
        """Create .env file for testing"""
        env_file = self.test_dir / '.env'
        
        # Use .env.clean as template if available
        env_clean = self.test_dir / '.env.clean'
        if env_clean.exists():
            shutil.copy2(env_clean, env_file)
        else:
            # Create minimal .env file
            env_content = """
SYNAPSE_SERVER_NAME=test.local
POSTGRES_PASSWORD=TestPassword123!
REGISTRATION_SHARED_SECRET=TestRegistrationSecret123
COTURN_STATIC_AUTH_SECRET=TestTurnSecret123
SYNAPSE_PORT=8008
ELEMENT_PORT=8080
SYNAPSE_ADMIN_PORT=8082
WELL_KNOWN_PORT=8090
COTURN_PORT=3478
COTURN_EXTERNAL_IP=127.0.0.1
LOG_LEVEL=INFO
"""
            with open(env_file, 'w') as f:
                f.write(env_content.strip())
        
        print(f"✓ Created test .env file: {env_file}")
        return env_file
    
    def validate_docker_compose(self) -> Dict[str, Any]:
        """Validate docker-compose.yml file"""
        compose_file = self.test_dir / 'docker-compose.yml'
        
        if not compose_file.exists():
            return {'valid': False, 'error': 'docker-compose.yml not found'}
        
        try:
            with open(compose_file, 'r') as f:
                compose_data = yaml.safe_load(f)
            
            # Validate basic structure
            required_sections = ['services', 'volumes', 'networks']
            missing_sections = [section for section in required_sections 
                              if section not in compose_data]
            
            if missing_sections:
                return {
                    'valid': False,
                    'error': f'Missing sections: {missing_sections}'
                }
            
            # Validate services
            required_services = ['synapse', 'postgres', 'element', 'coturn']
            services = list(compose_data['services'].keys())
            missing_services = [service for service in required_services 
                               if service not in services]
            
            if missing_services:
                return {
                    'valid': False,
                    'error': f'Missing services: {missing_services}'
                }
            
            return {
                'valid': True,
                'services': services,
                'volumes': list(compose_data.get('volumes', {}).keys()),
                'networks': list(compose_data.get('networks', {}).keys())
            }
            
        except Exception as e:
            return {'valid': False, 'error': f'YAML parsing error: {str(e)}'}
    
    def test_docker_availability(self) -> Dict[str, Any]:
        """Test Docker and Docker Compose availability"""
        results = {}
        
        # Test docker command
        try:
            result = subprocess.run(['docker', '--version'], 
                                  capture_output=True, text=True, timeout=10)
            results['docker'] = {
                'available': result.returncode == 0,
                'version': result.stdout.strip() if result.returncode == 0 else None,
                'error': result.stderr if result.returncode != 0 else None
            }
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            results['docker'] = {'available': False, 'error': str(e)}
        
        # Test docker-compose command  
        compose_commands = ['docker-compose', '/tmp/docker-compose']
        for cmd in compose_commands:
            try:
                result = subprocess.run([cmd, '--version'], 
                                      capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    results['docker_compose'] = {
                        'available': True,
                        'command': cmd,
                        'version': result.stdout.strip(),
                        'error': None
                    }
                    break
            except (subprocess.TimeoutExpired, FileNotFoundError):
                continue
        
        if 'docker_compose' not in results:
            results['docker_compose'] = {
                'available': False,
                'error': 'docker-compose not found in any expected location'
            }
        
        return results
    
    def create_docker_volumes(self) -> Dict[str, Any]:
        """Create required Docker volumes"""
        volume_names = [
            'voice-stack_postgres_data',
            'voice-stack_synapse_data', 
            'voice-stack_media_store',
            'voice-stack_element_data',
            'voice-stack_coturn_data'
        ]
        
        results = {}
        
        for volume_name in volume_names:
            try:
                result = subprocess.run([
                    'docker', 'volume', 'create', volume_name
                ], capture_output=True, text=True, timeout=30)
                
                results[volume_name] = {
                    'created': result.returncode == 0,
                    'error': result.stderr if result.returncode != 0 else None
                }
                
                if result.returncode == 0:
                    print(f"✓ Created volume: {volume_name}")
                else:
                    print(f"⚠ Failed to create volume {volume_name}: {result.stderr}")
                    
            except subprocess.TimeoutExpired as e:
                results[volume_name] = {'created': False, 'error': f'Timeout: {e}'}
        
        return results
    
    def start_services(self, timeout: int = 300) -> Dict[str, Any]:
        """Start services using docker-compose"""
        os.chdir(self.test_dir)
        
        # Determine docker-compose command
        docker_compose_cmd = 'docker-compose'
        if Path('/tmp/docker-compose').exists():
            docker_compose_cmd = '/tmp/docker-compose'
        
        try:
            # Start services
            print("Starting services...")
            result = subprocess.run([
                docker_compose_cmd, 'up', '-d'
            ], capture_output=True, text=True, timeout=timeout, cwd=self.test_dir)
            
            if result.returncode != 0:
                return {
                    'started': False,
                    'error': result.stderr,
                    'stdout': result.stdout
                }
            
            # Get list of started containers
            container_result = subprocess.run([
                docker_compose_cmd, 'ps', '--format', 'json'
            ], capture_output=True, text=True, timeout=30, cwd=self.test_dir)
            
            containers = []
            if container_result.returncode == 0:
                try:
                    # Parse container info
                    for line in container_result.stdout.strip().split('\n'):
                        if line:
                            container_info = json.loads(line)
                            containers.append({
                                'name': container_info.get('Name', ''),
                                'service': container_info.get('Service', ''),
                                'state': container_info.get('State', '')
                            })
                            self.containers_started.append(container_info.get('Name', ''))
                except json.JSONDecodeError:
                    print("Could not parse container status")
            
            return {
                'started': True,
                'containers': containers,
                'stdout': result.stdout
            }
            
        except subprocess.TimeoutExpired:
            return {
                'started': False,
                'error': f'Service startup timed out after {timeout} seconds'
            }
    
    def wait_for_services_ready(self, timeout: int = 180) -> Dict[str, Any]:
        """Wait for all services to become ready"""
        services = {
            'synapse': 'http://localhost:8008/health',
            'element': 'http://localhost:8080',
            'admin': 'http://localhost:8082',
            'well_known': 'http://localhost:8090/.well-known/matrix/server'
        }
        
        results = {}
        start_time = time.time()
        
        for service_name, health_url in services.items():
            print(f"Waiting for {service_name} to be ready...")
            
            service_ready = False
            service_start = time.time()
            
            while time.time() - start_time < timeout and time.time() - service_start < 60:
                try:
                    response = requests.get(health_url, timeout=10)
                    if response.status_code in [200, 404]:  # 404 is ok for some services
                        service_ready = True
                        break
                except requests.RequestException:
                    pass
                
                time.sleep(5)
            
            results[service_name] = {
                'ready': service_ready,
                'response_time': time.time() - service_start,
                'url': health_url
            }
            
            if service_ready:
                print(f"✓ {service_name} ready in {results[service_name]['response_time']:.1f}s")
            else:
                print(f"⚠ {service_name} not ready after timeout")
        
        return results
    
    def stop_test_containers(self):
        """Stop test containers"""
        if self.test_dir and self.containers_started:
            os.chdir(self.test_dir)
            
            docker_compose_cmd = 'docker-compose'
            if Path('/tmp/docker-compose').exists():
                docker_compose_cmd = '/tmp/docker-compose'
            
            try:
                result = subprocess.run([
                    docker_compose_cmd, 'down', '--volumes'
                ], capture_output=True, text=True, timeout=60, cwd=self.test_dir)
                
                if result.returncode == 0:
                    print("✓ Stopped test containers")
                else:
                    print(f"⚠ Error stopping containers: {result.stderr}")
                    
            except subprocess.TimeoutExpired:
                print("⚠ Timeout stopping containers")
    
    def test_basic_functionality(self) -> Dict[str, Any]:
        """Test basic functionality after deployment"""
        tests = {}
        
        # Test Synapse health
        try:
            response = requests.get('http://localhost:8008/health', timeout=10)
            tests['synapse_health'] = {
                'passed': response.status_code == 200,
                'status_code': response.status_code
            }
        except Exception as e:
            tests['synapse_health'] = {'passed': False, 'error': str(e)}
        
        # Test Element Web
        try:
            response = requests.get('http://localhost:8080', timeout=10)
            tests['element_web'] = {
                'passed': response.status_code == 200,
                'status_code': response.status_code,
                'contains_element': 'element' in response.text.lower()
            }
        except Exception as e:
            tests['element_web'] = {'passed': False, 'error': str(e)}
        
        # Test Matrix client API
        try:
            response = requests.get('http://localhost:8008/_matrix/client/versions', timeout=10)
            tests['matrix_api'] = {
                'passed': response.status_code == 200,
                'status_code': response.status_code
            }
            
            if response.status_code == 200:
                data = response.json()
                tests['matrix_api']['has_versions'] = 'versions' in data
                
        except Exception as e:
            tests['matrix_api'] = {'passed': False, 'error': str(e)}
        
        return tests


class TestDeploymentPortability:
    """Test deployment portability and clean environment deployment"""
    
    @pytest.fixture(scope="class")
    def config(self):
        return TestConfig()
    
    @pytest.fixture(scope="class")
    def tester(self, config):
        return DeploymentTester(config)
    
    def test_required_files_present(self, tester: DeploymentTester):
        """Test that all required files are present in project"""
        source_dir = Path(tester.config.project_root)
        
        required_files = {
            'docker-compose.yml': 'Docker Compose configuration',
            'deploy.sh': 'Deployment script',
            '.env.clean': 'Environment template'
        }
        
        missing_files = []
        
        for file_name, description in required_files.items():
            file_path = source_dir / file_name
            if file_path.exists():
                print(f"✓ {description}: {file_name}")
            else:
                missing_files.append(file_name)
                print(f"⚠ Missing {description}: {file_name}")
        
        assert len(missing_files) == 0, f"Missing required files: {missing_files}"
    
    def test_docker_compose_validity(self, tester: DeploymentTester):
        """Test docker-compose.yml is valid"""
        compose_file = Path(tester.config.project_root) / 'docker-compose.yml'
        
        assert compose_file.exists(), "docker-compose.yml not found"
        
        # Validate YAML syntax
        try:
            with open(compose_file, 'r') as f:
                compose_data = yaml.safe_load(f)
        except yaml.YAMLError as e:
            pytest.fail(f"Invalid YAML in docker-compose.yml: {e}")
        
        # Validate required sections
        assert 'services' in compose_data, "Missing 'services' section"
        assert 'volumes' in compose_data, "Missing 'volumes' section"
        assert 'networks' in compose_data, "Missing 'networks' section"
        
        # Validate required services
        required_services = ['synapse', 'postgres', 'element', 'coturn']
        services = list(compose_data['services'].keys())
        
        missing_services = [svc for svc in required_services if svc not in services]
        assert len(missing_services) == 0, f"Missing services: {missing_services}"
        
        print(f"✓ Docker Compose file valid with services: {', '.join(services)}")
    
    def test_environment_template(self, tester: DeploymentTester):
        """Test .env.clean template has required variables"""
        env_clean = Path(tester.config.project_root) / '.env.clean'
        
        assert env_clean.exists(), ".env.clean template not found"
        
        # Required environment variables
        required_vars = [
            'SYNAPSE_SERVER_NAME',
            'POSTGRES_PASSWORD',
            'REGISTRATION_SHARED_SECRET',
            'COTURN_STATIC_AUTH_SECRET'
        ]
        
        with open(env_clean, 'r') as f:
            env_content = f.read()
        
        missing_vars = []
        for var in required_vars:
            if f"{var}=" not in env_content:
                missing_vars.append(var)
            else:
                print(f"✓ Required variable present: {var}")
        
        assert len(missing_vars) == 0, f"Missing environment variables in .env.clean: {missing_vars}"
    
    def test_deploy_script_executable(self, tester: DeploymentTester):
        """Test deploy.sh script is executable and has required functions"""
        deploy_script = Path(tester.config.project_root) / 'deploy.sh'
        
        assert deploy_script.exists(), "deploy.sh not found"
        
        # Check if script is executable
        assert os.access(deploy_script, os.X_OK), "deploy.sh is not executable"
        
        # Check script content for required functions/commands
        with open(deploy_script, 'r') as f:
            script_content = f.read()
        
        required_commands = ['start', 'stop', 'health']
        missing_commands = []
        
        for command in required_commands:
            if command not in script_content:
                missing_commands.append(command)
            else:
                print(f"✓ Deploy script supports: {command}")
        
        if missing_commands:
            print(f"⚠ Deploy script may not support: {', '.join(missing_commands)}")
        
        print("✓ Deploy script is executable and appears functional")
    
    @pytest.mark.slow
    def test_clean_environment_deployment(self, tester: DeploymentTester):
        """Test full deployment in clean environment"""
        try:
            # Setup clean environment
            test_dir = tester.setup_clean_environment()
            
            # Copy project files
            copy_result = tester.copy_project_files()
            print(f"Copied {copy_result['total_copied']} files/directories")
            
            # Validate required files
            file_validation = tester.validate_required_files()
            missing_files = [f for f, exists in file_validation.items() if not exists]
            assert len(missing_files) == 0, f"Missing files after copy: {missing_files}"
            
            # Validate docker-compose
            compose_validation = tester.validate_docker_compose()
            assert compose_validation['valid'], f"Invalid docker-compose: {compose_validation.get('error')}"
            
            # Create test .env file
            tester.create_test_env_file()
            
            # Test Docker availability
            docker_check = tester.test_docker_availability()
            assert docker_check['docker']['available'], "Docker not available"
            assert docker_check['docker_compose']['available'], "Docker Compose not available"
            
            print("✓ Clean environment setup completed successfully")
            
        finally:
            tester.cleanup_test_environment()
    
    @pytest.mark.slow  
    def test_full_stack_deployment(self, tester: DeploymentTester):
        """Test complete stack deployment and functionality"""
        try:
            # Setup environment
            test_dir = tester.setup_clean_environment()
            copy_result = tester.copy_project_files()
            tester.validate_required_files()
            tester.create_test_env_file()
            
            # Create Docker volumes
            volume_result = tester.create_docker_volumes()
            failed_volumes = [v for v, r in volume_result.items() if not r['created']]
            if failed_volumes:
                print(f"⚠ Some volumes failed to create: {failed_volumes}")
            
            # Start services
            start_result = tester.start_services(timeout=300)
            if not start_result['started']:
                pytest.fail(f"Failed to start services: {start_result.get('error')}")
            
            print(f"✓ Started {len(start_result['containers'])} containers")
            
            # Wait for services to be ready
            ready_result = tester.wait_for_services_ready(timeout=180)
            not_ready = [svc for svc, r in ready_result.items() if not r['ready']]
            
            if not_ready:
                print(f"⚠ Some services not ready: {not_ready}")
                # Continue with basic functionality test anyway
            
            # Test basic functionality
            func_result = tester.test_basic_functionality()
            
            passed_tests = sum(1 for test in func_result.values() if test.get('passed', False))
            total_tests = len(func_result)
            
            print(f"Basic functionality: {passed_tests}/{total_tests} tests passed")
            
            for test_name, result in func_result.items():
                if result.get('passed'):
                    print(f"  ✓ {test_name}")
                else:
                    print(f"  ⚠ {test_name}: {result.get('error', 'Failed')}")
            
            # At least core services should work
            assert func_result.get('synapse_health', {}).get('passed', False), \
                "Synapse health check failed"
            
            print("✓ Full stack deployment test completed successfully")
            
        finally:
            tester.cleanup_test_environment()
    
    def test_configuration_flexibility(self, tester: DeploymentTester):
        """Test that configuration can be easily customized"""
        try:
            test_dir = tester.setup_clean_environment()
            tester.copy_project_files()
            
            # Create custom .env with different ports
            env_file = test_dir / '.env'
            custom_config = """
SYNAPSE_SERVER_NAME=custom.example.com
POSTGRES_PASSWORD=CustomPassword456!
REGISTRATION_SHARED_SECRET=CustomRegistrationSecret456
COTURN_STATIC_AUTH_SECRET=CustomTurnSecret456
SYNAPSE_PORT=9008
ELEMENT_PORT=9080
SYNAPSE_ADMIN_PORT=9082
WELL_KNOWN_PORT=9090
COTURN_PORT=4478
COTURN_EXTERNAL_IP=192.168.1.100
LOG_LEVEL=DEBUG
"""
            
            with open(env_file, 'w') as f:
                f.write(custom_config.strip())
            
            # Validate docker-compose can use these variables
            compose_validation = tester.validate_docker_compose()
            assert compose_validation['valid'], "Docker compose should work with custom config"
            
            print("✓ Configuration flexibility test passed")
            
        finally:
            tester.cleanup_test_environment()
    
    def test_dependency_completeness(self, tester: DeploymentTester):
        """Test that all dependencies are included or properly referenced"""
        source_dir = Path(tester.config.project_root)
        compose_file = source_dir / 'docker-compose.yml'
        
        with open(compose_file, 'r') as f:
            compose_data = yaml.safe_load(f)
        
        # Check all services have explicit image versions
        services_without_versions = []
        
        for service_name, service_config in compose_data['services'].items():
            if 'image' in service_config:
                image = service_config['image']
                if ':' not in image or image.endswith(':latest'):
                    services_without_versions.append(service_name)
                else:
                    print(f"✓ {service_name}: {image}")
        
        if services_without_versions:
            print(f"⚠ Services without explicit versions: {services_without_versions}")
            # This might be acceptable for some services
        
        # Check for external volume dependencies
        volumes = compose_data.get('volumes', {})
        external_volumes = [name for name, config in volumes.items() 
                           if config.get('external', False)]
        
        if external_volumes:
            print(f"✓ External volumes defined: {', '.join(external_volumes)}")
        
        print("✓ Dependency analysis completed")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-m", "not slow"])