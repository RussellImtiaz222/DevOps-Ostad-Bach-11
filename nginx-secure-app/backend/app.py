#!/usr/bin/env python3
"""
Simple backend application for testing Nginx reverse proxy
Runs on port 3000 and logs reverse proxy headers
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
from datetime import datetime
import sys

class BackendHandler(BaseHTTPRequestHandler):
    """Handle HTTP requests from Nginx reverse proxy"""
    
    def do_GET(self):
        """Handle GET requests"""
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Request: {self.path}")
        
        # Log important headers
        print(f"  Host: {self.headers.get('Host', 'N/A')}")
        print(f"  X-Real-IP: {self.headers.get('X-Real-IP', 'N/A')}")
        print(f"  X-Forwarded-For: {self.headers.get('X-Forwarded-For', 'N/A')}")
        print(f"  X-Forwarded-Proto: {self.headers.get('X-Forwarded-Proto', 'N/A')}")
        print(f"  X-Forwarded-Host: {self.headers.get('X-Forwarded-Host', 'N/A')}")
        
        if self.path == '/' or self.path == '':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            response = {
                'status': 'Backend service running',
                'message': 'Connected via Nginx reverse proxy',
                'timestamp': datetime.now().isoformat(),
                'headers': {
                    'Host': self.headers.get('Host'),
                    'X-Real-IP': self.headers.get('X-Real-IP'),
                    'X-Forwarded-For': self.headers.get('X-Forwarded-For'),
                    'X-Forwarded-Proto': self.headers.get('X-Forwarded-Proto'),
                }
            }
            
            self.wfile.write(json.dumps(response, indent=2).encode())
            
        elif self.path == '/status':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            response = {
                'status': 'running',
                'port': 3000,
                'time': datetime.now().isoformat()
            }
            
            self.wfile.write(json.dumps(response, indent=2).encode())
            
        else:
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            response = {
                'error': 'Endpoint not found',
                'path': self.path,
                'available_endpoints': [
                    '/',
                    '/status'
                ]
            }
            
            self.wfile.write(json.dumps(response, indent=2).encode())
    
    def log_message(self, format, *args):
        """Custom logging to avoid duplicate logs"""
        return  # Suppress default logging since we're doing custom logging in do_GET

def run_server(port=3000):
    """Run the backend server"""
    server_address = ('127.0.0.1', port)
    httpd = HTTPServer(server_address, BackendHandler)
    
    print("=" * 50)
    print("Backend Service Starting")
    print("=" * 50)
    print(f"[✓] Server running on http://127.0.0.1:{port}")
    print(f"[*] Available endpoints:")
    print(f"    GET / - Main endpoint with proxy headers")
    print(f"    GET /status - Service status")
    print("[*] Press Ctrl+C to stop")
    print("=" * 50)
    print()
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Shutting down server...")
        httpd.shutdown()
        print("[✓] Server stopped")
        sys.exit(0)

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 3000
    run_server(port)
