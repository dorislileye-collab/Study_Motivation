#!/usr/bin/env python3
import http.server
import socketserver
import os
import sys

PORT = int(os.environ.get('DEPLOY_RUN_PORT', 5000))
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

if __name__ == '__main__':
    with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
        print(f"Serving on port {PORT}", flush=True)
        sys.stdout.flush()
        httpd.serve_forever()
