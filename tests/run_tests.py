#!/usr/bin/env python3
"""
Matrix Family Server Test Runner
Comprehensive test runner with reporting for all test suites
"""

import sys
import os
import argparse
import subprocess
import json
import time
import requests
from pathlib import Path
from typing import Dict, Any, List, Optional
from dataclasses import dataclass, asdict
from datetime import datetime
import tempfile
import shutil


@dataclass
class TestResult:
    """Test result data structure"""
    suite: str
    name: str
    status: str  # passed, failed, skipped, error
    duration: float
    message: Optional[str] = None
    details: Optional[str] = None


@dataclass
class TestSuiteResult:
    """Test suite result data structure"""
    name: str
    total: int
    passed: int
    failed: int
    skipped: int
    errors: int
    duration: float
    tests: List[TestResult]


@dataclass
class TestRunReport:
    """Complete test run report"""
    timestamp: str
    environment: Dict[str, Any]
    suites: List[TestSuiteResult]
    total_duration: float
    summary: Dict[str, int]


class TestRunner:
    """Main test runner class"""
    
    def __init__(self, config_file: Optional[str] = None):
        self.test_dir = Path(__file__).parent
        self.project_root = self.test_dir.parent
        self.config = self._load_config(config_file)
        self.results: List[TestSuiteResult] = []
        self.start_time = time.time()
    
    def _load_config(self, config_file: Optional[str]) -> Dict[str, Any]:
        """Load test configuration"""
        default_config = {
            'synapse_url': 'http://localhost:8008',
            'element_url': 'http://localhost:8080',
            'server_name': 'matrix.byte-box.org',
            'test_timeout': 300,
            'test_user_password': 'TestPassword123!',
            'headless': True,
            'parallel_workers': 2,
            'report_format': 'html',
            'output_dir': 'test-reports'
        }
        
        if config_file and Path(config_file).exists():
            import yaml
            with open(config_file, 'r') as f:
                user_config = yaml.safe_load(f)
            default_config.update(user_config)
        
        # Override with environment variables
        env_overrides = {
            'SYNAPSE_URL': 'synapse_url',
            'ELEMENT_URL': 'element_url',
            'SYNAPSE_SERVER_NAME': 'server_name',
            'TEST_TIMEOUT': 'test_timeout',
            'TEST_USER_PASSWORD': 'test_user_password',
            'HEADLESS': 'headless',
            'PARALLEL_WORKERS': 'parallel_workers'
        }
        
        for env_var, config_key in env_overrides.items():
            if os.getenv(env_var):
                value = os.getenv(env_var)
                if config_key in ['test_timeout', 'parallel_workers']:
                    value = int(value)
                elif config_key == 'headless':
                    value = value.lower() == 'true'
                default_config[config_key] = value
        
        return default_config
    
    def check_services_available(self) -> Dict[str, bool]:
        """Check if required services are available"""
        services = {
            'synapse': f"{self.config['synapse_url']}/health",
            'element': self.config['element_url'],
            'admin': 'http://localhost:8082',
            'well_known': 'http://localhost:8090/.well-known/matrix/server'
        }
        
        results = {}
        
        for service_name, url in services.items():
            try:
                response = requests.get(url, timeout=10)
                results[service_name] = response.status_code in [200, 404]  # 404 ok for some
            except requests.RequestException:
                results[service_name] = False
        
        return results
    
    def setup_test_environment(self) -> Dict[str, Any]:
        """Setup test environment and return environment info"""
        env_info = {
            'python_version': sys.version,
            'platform': sys.platform,
            'working_directory': str(self.project_root),
            'test_directory': str(self.test_dir),
            'timestamp': datetime.now().isoformat(),
            'config': self.config.copy()
        }
        
        # Set environment variables for tests
        test_env = {
            'SYNAPSE_URL': self.config['synapse_url'],
            'ELEMENT_URL': self.config['element_url'],
            'SYNAPSE_SERVER_NAME': self.config['server_name'],
            'TEST_USER_PASSWORD': self.config['test_user_password'],
            'HEADLESS': str(self.config['headless']).lower(),
            'TEST_TIMEOUT': str(self.config['test_timeout']),
            'PYTHONPATH': str(self.test_dir)
        }
        
        os.environ.update(test_env)
        env_info['environment_variables'] = test_env
        
        return env_info
    
    def run_pytest_suite(self, test_file: str, markers: List[str] = None, 
                        extra_args: List[str] = None) -> TestSuiteResult:
        """Run a pytest test suite and parse results"""
        suite_name = Path(test_file).stem
        
        cmd = [
            sys.executable, '-m', 'pytest',
            str(self.test_dir / test_file),
            '--json-report', '--json-report-file=/tmp/pytest-report.json',
            '--tb=short',
            '-v'
        ]
        
        if markers:
            for marker in markers:
                cmd.extend(['-m', marker])
        
        if extra_args:
            cmd.extend(extra_args)
        
        # Add parallel execution if configured
        if self.config['parallel_workers'] > 1:
            cmd.extend(['-n', str(self.config['parallel_workers'])])
        
        print(f"Running {suite_name} tests...")
        start_time = time.time()
        
        try:
            result = subprocess.run(
                cmd, 
                capture_output=True, 
                text=True, 
                timeout=self.config['test_timeout'],
                cwd=self.test_dir
            )
            
            duration = time.time() - start_time
            
            # Parse JSON report if available
            json_report_file = Path('/tmp/pytest-report.json')
            if json_report_file.exists():
                with open(json_report_file, 'r') as f:
                    report_data = json.load(f)
                
                return self._parse_pytest_json_report(suite_name, report_data, duration)
            else:
                # Fallback to parsing stdout
                return self._parse_pytest_output(suite_name, result, duration)
                
        except subprocess.TimeoutExpired:
            duration = time.time() - start_time
            return TestSuiteResult(
                name=suite_name,
                total=1,
                passed=0,
                failed=1,
                skipped=0,
                errors=0,
                duration=duration,
                tests=[TestResult(
                    suite=suite_name,
                    name="timeout",
                    status="error",
                    duration=duration,
                    message="Test suite timed out"
                )]
            )
        except Exception as e:
            duration = time.time() - start_time
            return TestSuiteResult(
                name=suite_name,
                total=1,
                passed=0,
                failed=0,
                skipped=0,
                errors=1,
                duration=duration,
                tests=[TestResult(
                    suite=suite_name,
                    name="error",
                    status="error", 
                    duration=duration,
                    message=str(e)
                )]
            )
    
    def _parse_pytest_json_report(self, suite_name: str, report_data: Dict[str, Any], 
                                 duration: float) -> TestSuiteResult:
        """Parse pytest JSON report"""
        summary = report_data.get('summary', {})
        tests = []
        
        for test_data in report_data.get('tests', []):
            test_result = TestResult(
                suite=suite_name,
                name=test_data.get('nodeid', '').split('::')[-1],
                status=test_data.get('outcome', 'unknown'),
                duration=test_data.get('duration', 0),
                message=test_data.get('call', {}).get('longrepr', None)
            )
            tests.append(test_result)
        
        return TestSuiteResult(
            name=suite_name,
            total=summary.get('total', 0),
            passed=summary.get('passed', 0),
            failed=summary.get('failed', 0),
            skipped=summary.get('skipped', 0),
            errors=summary.get('error', 0),
            duration=duration,
            tests=tests
        )
    
    def _parse_pytest_output(self, suite_name: str, result: subprocess.CompletedProcess,
                           duration: float) -> TestSuiteResult:
        """Parse pytest stdout output as fallback"""
        output_lines = result.stdout.split('\n')
        
        # Find summary line
        summary_line = ""
        for line in reversed(output_lines):
            if 'failed' in line or 'passed' in line or 'error' in line:
                summary_line = line
                break
        
        # Parse counts from summary
        passed = failed = skipped = errors = 0
        
        if 'passed' in summary_line:
            passed = self._extract_count(summary_line, 'passed')
        if 'failed' in summary_line:
            failed = self._extract_count(summary_line, 'failed')
        if 'skipped' in summary_line:
            skipped = self._extract_count(summary_line, 'skipped')
        if 'error' in summary_line:
            errors = self._extract_count(summary_line, 'error')
        
        total = passed + failed + skipped + errors
        
        # Create basic test results
        tests = []
        if result.returncode == 0:
            if passed > 0:
                tests.append(TestResult(
                    suite=suite_name,
                    name="tests",
                    status="passed",
                    duration=duration,
                    message=f"{passed} tests passed"
                ))
        else:
            tests.append(TestResult(
                suite=suite_name,
                name="tests",
                status="failed",
                duration=duration,
                message=result.stderr if result.stderr else "Tests failed"
            ))
        
        return TestSuiteResult(
            name=suite_name,
            total=total,
            passed=passed,
            failed=failed,
            skipped=skipped,
            errors=errors,
            duration=duration,
            tests=tests
        )
    
    def _extract_count(self, text: str, keyword: str) -> int:
        """Extract count from pytest summary line"""
        try:
            parts = text.split()
            for i, part in enumerate(parts):
                if keyword in part and i > 0:
                    return int(parts[i-1])
        except (ValueError, IndexError):
            pass
        return 0
    
    def run_all_tests(self, test_suites: List[str] = None) -> TestRunReport:
        """Run all test suites and generate report"""
        if test_suites is None:
            test_suites = [
                'test_synapse_api.py',
                'test_element_web.py', 
                'test_element_call.py',
                'test_network_security.py',
                'test_deployment_portability.py'
            ]
        
        print("Matrix Family Server Test Runner")
        print("=" * 50)
        
        # Setup environment
        env_info = self.setup_test_environment()
        print(f"Test environment: {env_info['timestamp']}")
        
        # Check service availability
        print("\nChecking service availability...")
        service_status = self.check_services_available()
        for service, available in service_status.items():
            status = "✓" if available else "✗"
            print(f"  {status} {service}")
        
        unavailable_services = [s for s, available in service_status.items() if not available]
        if unavailable_services:
            print(f"\n⚠ Warning: Some services unavailable: {', '.join(unavailable_services)}")
            print("Some tests may fail or be skipped.")
        
        # Run test suites
        print(f"\nRunning {len(test_suites)} test suites...")
        print("-" * 30)
        
        for test_suite in test_suites:
            if not (self.test_dir / test_suite).exists():
                print(f"⚠ Test suite not found: {test_suite}")
                continue
            
            # Special handling for different test types
            extra_args = []
            markers = []
            
            if 'deployment' in test_suite:
                markers.append('not slow')  # Skip slow tests by default
            
            result = self.run_pytest_suite(test_suite, markers, extra_args)
            self.results.append(result)
            
            # Print immediate results
            status_emoji = "✓" if result.failed == 0 and result.errors == 0 else "✗"
            print(f"{status_emoji} {result.name}: {result.passed}/{result.total} passed "
                  f"({result.duration:.1f}s)")
        
        # Generate final report
        total_duration = time.time() - self.start_time
        summary = self._calculate_summary()
        
        report = TestRunReport(
            timestamp=datetime.now().isoformat(),
            environment=env_info,
            suites=self.results,
            total_duration=total_duration,
            summary=summary
        )
        
        return report
    
    def _calculate_summary(self) -> Dict[str, int]:
        """Calculate overall test summary"""
        summary = {
            'total_suites': len(self.results),
            'total_tests': sum(r.total for r in self.results),
            'total_passed': sum(r.passed for r in self.results),
            'total_failed': sum(r.failed for r in self.results),
            'total_skipped': sum(r.skipped for r in self.results),
            'total_errors': sum(r.errors for r in self.results)
        }
        return summary
    
    def generate_html_report(self, report: TestRunReport, output_file: str):
        """Generate HTML test report"""
        html_template = """
<!DOCTYPE html>
<html>
<head>
    <title>Matrix Family Server Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background: #f5f5f5; padding: 20px; border-radius: 5px; }
        .summary { display: flex; gap: 20px; margin: 20px 0; }
        .metric { background: #e9ecef; padding: 15px; border-radius: 5px; text-align: center; }
        .metric.passed { background: #d4edda; color: #155724; }
        .metric.failed { background: #f8d7da; color: #721c24; }
        .suite { margin: 20px 0; border: 1px solid #dee2e6; border-radius: 5px; }
        .suite-header { background: #f8f9fa; padding: 15px; font-weight: bold; }
        .test-list { padding: 0; margin: 0; list-style: none; }
        .test-item { padding: 10px 15px; border-bottom: 1px solid #dee2e6; }
        .test-item:last-child { border-bottom: none; }
        .status-passed { color: #28a745; }
        .status-failed { color: #dc3545; }
        .status-skipped { color: #6c757d; }
        .status-error { color: #fd7e14; }
        .details { font-family: monospace; font-size: 12px; background: #f8f9fa; padding: 10px; margin-top: 10px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Matrix Family Server Test Report</h1>
        <p><strong>Generated:</strong> {timestamp}</p>
        <p><strong>Duration:</strong> {duration:.1f} seconds</p>
        <p><strong>Environment:</strong> {platform}</p>
    </div>
    
    <div class="summary">
        <div class="metric">
            <div style="font-size: 24px; font-weight: bold;">{total_suites}</div>
            <div>Test Suites</div>
        </div>
        <div class="metric">
            <div style="font-size: 24px; font-weight: bold;">{total_tests}</div>
            <div>Total Tests</div>
        </div>
        <div class="metric passed">
            <div style="font-size: 24px; font-weight: bold;">{total_passed}</div>
            <div>Passed</div>
        </div>
        <div class="metric failed">
            <div style="font-size: 24px; font-weight: bold;">{total_failed}</div>
            <div>Failed</div>
        </div>
        <div class="metric">
            <div style="font-size: 24px; font-weight: bold;">{total_skipped}</div>
            <div>Skipped</div>
        </div>
        <div class="metric failed">
            <div style="font-size: 24px; font-weight: bold;">{total_errors}</div>
            <div>Errors</div>
        </div>
    </div>
    
    {suites_html}
    
    <div style="margin-top: 40px; font-size: 12px; color: #6c757d;">
        Generated by Matrix Family Server Test Runner
    </div>
</body>
</html>
        """
        
        # Generate suites HTML
        suites_html = ""
        for suite in report.suites:
            suite_status = "passed" if suite.failed == 0 and suite.errors == 0 else "failed"
            
            tests_html = ""
            for test in suite.tests:
                status_class = f"status-{test.status}"
                details_html = ""
                if test.message:
                    details_html = f'<div class="details">{test.message}</div>'
                
                tests_html += f"""
                <li class="test-item">
                    <span class="{status_class}">●</span> {test.name} 
                    <span style="float: right;">{test.duration:.2f}s</span>
                    {details_html}
                </li>
                """
            
            suites_html += f"""
            <div class="suite">
                <div class="suite-header {suite_status}">
                    {suite.name} - {suite.passed}/{suite.total} passed ({suite.duration:.1f}s)
                </div>
                <ul class="test-list">
                    {tests_html}
                </ul>
            </div>
            """
        
        # Fill template
        html_content = html_template.format(
            timestamp=report.timestamp,
            duration=report.total_duration,
            platform=report.environment.get('platform', 'unknown'),
            total_suites=report.summary['total_suites'],
            total_tests=report.summary['total_tests'],
            total_passed=report.summary['total_passed'],
            total_failed=report.summary['total_failed'],
            total_skipped=report.summary['total_skipped'],
            total_errors=report.summary['total_errors'],
            suites_html=suites_html
        )
        
        # Write report
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_path, 'w') as f:
            f.write(html_content)
        
        print(f"HTML report generated: {output_path.absolute()}")
    
    def generate_json_report(self, report: TestRunReport, output_file: str):
        """Generate JSON test report"""
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Convert dataclasses to dicts
        report_dict = asdict(report)
        
        with open(output_path, 'w') as f:
            json.dump(report_dict, f, indent=2)
        
        print(f"JSON report generated: {output_path.absolute()}")
    
    def print_summary(self, report: TestRunReport):
        """Print test summary to console"""
        print("\n" + "=" * 50)
        print("TEST SUMMARY")
        print("=" * 50)
        
        summary = report.summary
        
        print(f"Test Suites: {summary['total_suites']}")
        print(f"Total Tests: {summary['total_tests']}")
        print(f"Passed: {summary['total_passed']}")
        print(f"Failed: {summary['total_failed']}")
        print(f"Skipped: {summary['total_skipped']}")
        print(f"Errors: {summary['total_errors']}")
        print(f"Duration: {report.total_duration:.1f}s")
        
        # Calculate success rate
        if summary['total_tests'] > 0:
            success_rate = (summary['total_passed'] / summary['total_tests']) * 100
            print(f"Success Rate: {success_rate:.1f}%")
        
        print("\nPer Suite Results:")
        for suite in report.suites:
            status = "✓" if suite.failed == 0 and suite.errors == 0 else "✗"
            print(f"  {status} {suite.name}: {suite.passed}/{suite.total} "
                  f"({suite.duration:.1f}s)")
        
        # Overall result
        overall_success = summary['total_failed'] == 0 and summary['total_errors'] == 0
        print(f"\nOverall Result: {'PASS' if overall_success else 'FAIL'}")
        
        if not overall_success:
            print("\n⚠ Some tests failed. Check the detailed report for more information.")
            print("Consider running './deploy.sh health' to check service status.")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='Matrix Family Server Test Runner')
    parser.add_argument('--config', '-c', help='Test configuration file')
    parser.add_argument('--suites', '-s', nargs='+', help='Specific test suites to run')
    parser.add_argument('--output-dir', '-o', default='test-reports', help='Output directory for reports')
    parser.add_argument('--format', '-f', choices=['html', 'json', 'both'], default='both', 
                       help='Report format')
    parser.add_argument('--no-services-check', action='store_true', 
                       help='Skip service availability check')
    parser.add_argument('--parallel', '-p', type=int, help='Number of parallel workers')
    parser.add_argument('--timeout', '-t', type=int, help='Test timeout in seconds')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    # Create test runner
    runner = TestRunner(args.config)
    
    # Override config with command line args
    if args.parallel:
        runner.config['parallel_workers'] = args.parallel
    if args.timeout:
        runner.config['test_timeout'] = args.timeout
    
    try:
        # Run tests
        report = runner.run_all_tests(args.suites)
        
        # Generate reports
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_dir = Path(args.output_dir)
        
        if args.format in ['html', 'both']:
            html_file = output_dir / f'test_report_{timestamp}.html'
            runner.generate_html_report(report, html_file)
        
        if args.format in ['json', 'both']:
            json_file = output_dir / f'test_report_{timestamp}.json'
            runner.generate_json_report(report, json_file)
        
        # Print summary
        runner.print_summary(report)
        
        # Exit with appropriate code
        success = report.summary['total_failed'] == 0 and report.summary['total_errors'] == 0
        sys.exit(0 if success else 1)
        
    except KeyboardInterrupt:
        print("\n⚠ Test run interrupted by user")
        sys.exit(130)
    except Exception as e:
        print(f"\n✗ Error running tests: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()