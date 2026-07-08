#!/usr/bin/env python3
"""
Validation script to test Nginx setup
Run this after setup to ensure everything is configured correctly
"""

import subprocess
import sys
import json
import time
from urllib.request import urlopen
from urllib.error import URLError, HTTPError
import ssl

class ValidationTest:
    """Test suite for Nginx configuration"""
    
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.ssl_context = ssl.create_default_context()
        self.ssl_context.check_hostname = False
        self.ssl_context.verify_mode = ssl.CERT_NONE
    
    def test(self, name, condition, error_msg=""):
        """Helper to track test results"""
        status = "✓ PASS" if condition else "✗ FAIL"
        print(f"{status}: {name}")
        if not condition and error_msg:
            print(f"       {error_msg}")
        
        if condition:
            self.passed += 1
        else:
            self.failed += 1
    
    def run_command(self, cmd, sudo=False):
        """Run shell command"""
        if sudo:
            cmd = f"sudo {cmd}"
        try:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=5)
            return result.returncode == 0, result.stdout
        except Exception as e:
            return False, str(e)
    
    def test_nginx_syntax(self):
        """Test: Nginx configuration syntax is valid"""
        print("\n[1] Testing Nginx Configuration Syntax")
        success, output = self.run_command("nginx -t", sudo=True)
        self.test("Nginx config syntax valid", success, output.strip())
    
    def test_nginx_running(self):
        """Test: Nginx service is running"""
        print("\n[2] Testing Nginx Service Status")
        success, _ = self.run_command("systemctl is-active nginx", sudo=True)
        self.test("Nginx service running", success)
    
    def test_ssl_files_exist(self):
        """Test: SSL certificate files exist"""
        print("\n[3] Testing SSL Certificate Files")
        
        crt_exists, _ = self.run_command("test -f /etc/nginx/ssl/secure-app.crt", sudo=True)
        self.test("Certificate file exists", crt_exists, "/etc/nginx/ssl/secure-app.crt not found")
        
        key_exists, _ = self.run_command("test -f /etc/nginx/ssl/secure-app.key", sudo=True)
        self.test("Private key file exists", key_exists, "/etc/nginx/ssl/secure-app.key not found")
    
    def test_html_file_exists(self):
        """Test: Static HTML file exists"""
        print("\n[4] Testing Static Website Files")
        
        html_exists, _ = self.run_command("test -f /var/www/secure-app/index.html", sudo=True)
        self.test("index.html exists", html_exists, "/var/www/secure-app/index.html not found")
    
    def test_nginx_config_exists(self):
        """Test: Nginx configuration is in place"""
        print("\n[5] Testing Nginx Configuration")
        
        config_exists, _ = self.run_command("test -f /etc/nginx/sites-available/secure-app.conf", sudo=True)
        self.test("Config file exists", config_exists)
        
        symlink_exists, _ = self.run_command("test -L /etc/nginx/sites-enabled/secure-app.conf", sudo=True)
        self.test("Config symlink enabled", symlink_exists)
    
    def test_https_connection(self):
        """Test: HTTPS connection works"""
        print("\n[6] Testing HTTPS Connection")
        
        try:
            response = urlopen('https://localhost', context=self.ssl_context, timeout=5)
            success = response.status == 200
            self.test("HTTPS connection successful", success, f"HTTP {response.status}")
        except Exception as e:
            self.test("HTTPS connection successful", False, str(e))
    
    def test_http_redirect(self):
        """Test: HTTP redirects to HTTPS"""
        print("\n[7] Testing HTTP to HTTPS Redirect")
        
        try:
            # This will follow redirects
            response = urlopen('http://localhost', timeout=5)
            # After redirect, we should be on HTTPS
            success = 'https' in response.url
            self.test("HTTP redirects to HTTPS", success)
        except HTTPError as e:
            # 301/302 redirect
            self.test("HTTP redirects to HTTPS", 
                     e.code in [301, 302], 
                     f"HTTP {e.code}")
        except Exception as e:
            self.test("HTTP redirects to HTTPS", False, str(e))
    
    def test_static_content(self):
        """Test: Static website content loads"""
        print("\n[8] Testing Static Website Content")
        
        try:
            response = urlopen('https://localhost', context=self.ssl_context, timeout=5)
            content = response.read().decode('utf-8')
            success = "Secure Server Running via Nginx" in content
            self.test("Static content loads correctly", success, "Title not found in response")
        except Exception as e:
            self.test("Static content loads correctly", False, str(e))
    
    def test_health_endpoint(self):
        """Test: Health check endpoint works"""
        print("\n[9] Testing Health Check Endpoint")
        
        try:
            response = urlopen('https://localhost/health', context=self.ssl_context, timeout=5)
            content = response.read().decode('utf-8')
            success = "healthy" in content
            self.test("Health check endpoint works", success)
        except Exception as e:
            self.test("Health check endpoint works", False, str(e))
    
    def test_reverse_proxy(self):
        """Test: Reverse proxy endpoint (optional - requires backend)"""
        print("\n[10] Testing Reverse Proxy to Backend")
        
        try:
            response = urlopen('https://localhost/api/', context=self.ssl_context, timeout=5)
            content = response.read().decode('utf-8')
            try:
                data = json.loads(content)
                success = "Backend service running" in data.get('status', '')
                self.test("Reverse proxy working", success)
            except json.JSONDecodeError:
                self.test("Reverse proxy endpoint accessible", True)
        except URLError as e:
            if "Connection refused" in str(e):
                print("⊘ SKIP: Backend service not running (optional)")
            else:
                self.test("Reverse proxy working", False, str(e))
        except Exception as e:
            print(f"⊘ SKIP: {str(e)}")
    
    def print_summary(self):
        """Print test results summary"""
        print("\n" + "="*50)
        print("TEST SUMMARY")
        print("="*50)
        total = self.passed + self.failed
        print(f"Total Tests: {total}")
        print(f"Passed: {self.passed}")
        print(f"Failed: {self.failed}")
        
        if self.failed == 0:
            print("\n✓ All tests passed! Setup is complete. 🎉")
            return 0
        else:
            print(f"\n✗ {self.failed} test(s) failed. See above for details.")
            return 1
    
    def run_all_tests(self):
        """Run all tests"""
        print("\n" + "="*50)
        print("NGINX SETUP VALIDATION")
        print("="*50)
        
        self.test_nginx_syntax()
        self.test_nginx_running()
        self.test_ssl_files_exist()
        self.test_html_file_exists()
        self.test_nginx_config_exists()
        
        # Network tests (may require systemctl to set up localhost)
        print("\n[*] Testing network connectivity...")
        self.test_https_connection()
        self.test_http_redirect()
        self.test_static_content()
        self.test_health_endpoint()
        self.test_reverse_proxy()
        
        return self.print_summary()

def main():
    """Main entry point"""
    validator = ValidationTest()
    exit_code = validator.run_all_tests()
    sys.exit(exit_code)

if __name__ == '__main__':
    main()
