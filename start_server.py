#!/usr/bin/env python3
"""
CORS-enabled HTTP Server für Flutter Web Preview
"""
import http.server
import socketserver

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('X-Frame-Options', 'ALLOWALL')
        self.send_header('Content-Security-Policy', 'frame-ancestors *')
        super().end_headers()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

if __name__ == '__main__':
    PORT = 5060
    with socketserver.TCPServer(('0.0.0.0', PORT), CORSRequestHandler) as httpd:
        print(f'✅ Flutter Web Preview läuft auf Port {PORT}')
        print(f'🌐 URL: https://5060-i0sts42562ps3y0etjezb-583b4d74.sandbox.novita.ai')
        httpd.serve_forever()
