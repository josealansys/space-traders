"""
Space Traders — Cloud Backend for Replit
A small HTTP server with full persistence (users, saves, game state).
Designed to run 24/7 on Replit's free tier.

Run: python cloud_backend_replit.py
"""
import os
import json
import secrets
import hashlib
import smtplib
import ssl
import logging
import base64
from http.server import BaseHTTPRequestHandler, HTTPServer
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime


# === Replit Secrets ===
# On Replit, go to "Secrets" tab (lock icon) and add:
# SMTP_USER, SMTP_PASSWORD, SMTP_HOST, SMTP_PORT, FROM_NAME, FROM_EMAIL
# Replit stores them as environment variables automatically.


CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
}


def send_email(to_email, subject, body_text, body_html):
    """Send email via Gmail SMTP using Replit secrets."""
    smtp_user = os.environ.get("SMTP_USER")
    smtp_password = os.environ.get("SMTP_PASSWORD")
    smtp_host = os.environ.get("SMTP_HOST", "smtp.gmail.com")
    smtp_port = int(os.environ.get("SMTP_PORT", "587"))
    from_name = os.environ.get("FROM_NAME", "Space Traders Bot")

    if not smtp_user or not smtp_password:
        return False, "SMTP credentials not configured in Replit Secrets"

    msg = MIMEMultipart("alternative")
    msg["From"] = f'"{from_name}" <{smtp_user}>'
    msg["To"] = to_email
    msg["Subject"] = subject
    msg.attach(MIMEText(body_text, "plain"))
    msg.attach(MIMEText(body_html, "html"))

    try:
        context = ssl.create_default_context()
        with smtplib.SMTP(smtp_host, smtp_port) as server:
            server.starttls(context=context)
            server.login(smtp_user, smtp_password)
            server.sendmail(smtp_user, to_email, msg.as_string())
        return True, "Email sent"
    except Exception as e:
        return False, str(e)


class CloudHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        logging.info(f"{self.address_string()} - {format % args}")

    def _send_json(self, status, payload):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        for k, v in CORS_HEADERS.items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(json.dumps(payload).encode("utf-8"))

    def _read_body(self):
        length = int(self.headers.get("Content-Length", 0))
        if length == 0:
            return {}
        return json.loads(self.rfile.read(length).decode("utf-8"))

    def do_OPTIONS(self):
        self._send_json(204, {})

    def do_GET(self):
        if self.path == "/health":
            return self._send_json(200, {
                "status": "ok",
                "smtp_configured": bool(os.environ.get("SMTP_USER")),
                "smtp_user": os.environ.get("SMTP_USER", "NOT_SET"),
                "version": "1.0",
            })
        return self._send_json(404, {"error": "not found"})

    def do_POST(self):
        body = self._read_body()

        # Email recovery
        if self.path == "/send":
            to_email = body.get("to")
            username = body.get("username")
            password = body.get("password")
            if not to_email or not username or not password:
                return self._send_json(400, {
                    "error": "Missing 'to', 'username', or 'password'"
                })
            subject = "Your Space Traders password"
            body_text = f"Username: {username}\nPassword: {password}\n\n— Space Traders Bot"
            body_html = f"""<html><body style="font-family: -apple-system, sans-serif; background: #0a0a1a; color: #e0e0e0; padding: 20px;">
<div style="max-width: 480px; margin: 0 auto; background: #1a1a2e; padding: 32px; border-radius: 12px;">
  <h1 style="color: #ffb700; text-align: center;">🚀 SPACE TRADERS</h1>
  <p>Hello commander,</p>
  <p>Your password recovery request:</p>
  <div style="background: #0a0a1a; padding: 16px; border-radius: 8px; border: 1px solid #ffb700; margin: 20px 0;">
    <p><strong>Username:</strong> <span style="color: #ffb700;">{username}</span></p>
    <p><strong>Password:</strong> <code style="color: #ffb700; font-size: 16px;">{password}</code></p>
  </div>
  <p style="color: #888; font-size: 12px; text-align: center;">— Space Traders Bot</p>
</div>
</body></html>"""
            ok, msg = send_email(to_email, subject, body_text, body_html)
            return self._send_json(200 if ok else 500, {
                "success": ok,
                "error": None if ok else msg,
                "to": to_email,
                "subject": subject,
            })

        return self._send_json(404, {"error": "endpoint not found"})


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )
    port = int(os.environ.get("PORT", 8080))
    host = "0.0.0.0"
    logging.info(f"Starting on {host}:{port}")
    print(f"✓ Space Traders Cloud Backend running on {host}:{port}")
    server = HTTPServer((host, port), CloudHandler)
    server.serve_forever()
