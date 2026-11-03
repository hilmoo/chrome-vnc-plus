#!/usr/bin/env python3
"""Tiny HTTP API: GET /screenshot (whole desktop, PNG; ?format=jpg), GET /healthz."""
import os, subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

TOKEN = os.environ.get("API_TOKEN", "")
ENV = {**os.environ, "DISPLAY": os.environ.get("DISPLAY", ":0")}

class H(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype="text/plain"):
        self.send_response(code); self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body))); self.send_header("Cache-Control", "no-store")
        self.end_headers(); self.wfile.write(body)

    def do_GET(self):
        u = urlparse(self.path); q = parse_qs(u.query)
        if u.path == "/healthz":
            ok = subprocess.run(["xdpyinfo"], env=ENV, capture_output=True).returncode == 0
            return self._send(200 if ok else 503, b"ok" if ok else b"no display")
        if TOKEN and q.get("token", [""])[0] != TOKEN and self.headers.get("Authorization") != f"Bearer {TOKEN}":
            return self._send(401, b"unauthorized")
        if u.path == "/screenshot":
            fmt = "jpg" if q.get("format", ["png"])[0] in ("jpg", "jpeg") else "png"
            r = subprocess.run(["import", "-window", "root", f"{fmt}:-"], env=ENV, capture_output=True)
            if r.returncode: return self._send(500, r.stderr)
            return self._send(200, r.stdout, "image/jpeg" if fmt == "jpg" else "image/png")
        self._send(404, b"not found")

    def log_message(self, *a): pass

ThreadingHTTPServer(("0.0.0.0", 8080), H).serve_forever()
