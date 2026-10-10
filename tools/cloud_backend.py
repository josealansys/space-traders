"""
Space Traders — Cloud Backend for Render.com
Uses background threads to avoid Render's 30-second HTTP timeout.
"""
import os
import json
import smtplib
import ssl
import logging
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime


CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}


def send_email_async(to, subject, text, html):
    """Send email in a background thread. Returns immediately."""
    def _send():
        try:
            user = os.environ.get("SMTP_USER")
            pwd = os.environ.get("SMTP_PASSWORD")
            if not user or not pwd:
                logging.error("SMTP not configured")
                return
            msg = MIMEMultipart("alternative")
            msg["From"] = user
            msg["To"] = to
            msg["Subject"] = subject
            msg.attach(MIMEText(text, "plain"))
            msg.attach(MIMEText(html, "html"))
            ctx = ssl.create_default_context()
            with smtplib.SMTP("smtp.gmail.com", 587, timeout=20) as s:
                s.starttls(context=ctx)
                s.login(user, pwd)
                s.sendmail(user, to, msg.as_string())
            logging.info(f"Email sent to {to}")
        except Exception as e:
            logging.error(f"Email send failed: {e}")

    # Start in background - the HTTP response returns immediately
    thread = threading.Thread(target=_send, daemon=True)
    thread.start()
    return True


class H(BaseHTTPRequestHandler):
    def send_json(self, status, payload):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        for k, v in CORS_HEADERS.items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(json.dumps(payload).encode())

    def log_message(self, format, *args):
        logging.info(f"{self.address_string()} - {format % args}")

    def do_OPTIONS(self):
        self.send_json(204, {})

    def do_GET(self):
        if self.path == "/health":
            return self.send_json(200, {
                "status": "ok",
                "smtp": bool(os.environ.get("SMTP_USER")),
                "user": os.environ.get("SMTP_USER", "NOT_SET"),
                "version": "2.0-async",
            })
        self.send_json(404, {"error": "not found"})

    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(n).decode()) if n else {}
        if self.path == "/send":
            to = body.get("to")
            user = body.get("username")
            pwd = body.get("password")
            if not (to and user and pwd):
                return self.send_json(400, {"error": "missing fields"})

            # Queue the email in a background thread
            # The HTTP response returns immediately (well under Render's 30s timeout)
            send_email_async(
                to, "Your Space Traders password",
                f"Username: {user}\nPassword: {pwd}\n\n— Space Traders Bot",
                f'<html><body style="background:#0a0a1a;color:#fff;padding:20px;font-family:sans-serif"><h1 style="color:#ffb700">SPACE TRADERS</h1><p>Username: <b>{user}</b></p><p>Password: <code style="color:#ffb700;font-size:18px">{pwd}</code></p></body></html>'
            )
            return self.send_json(200, {
                "success": True,
                "to": to,
                "queued": True,
                "message": "Email queued for delivery",
            })
        self.send_json(404, {"error": "not found"})


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    port = int(os.environ.get("PORT", 8080))
    print(f"Running on 0.0.0.0:{port}")
    HTTPServer(("0.0.0.0", port), H).serve_forever()
