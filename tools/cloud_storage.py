"""
Space Traders — Cloud Backend (NO SMTP, just HTTP storage)
Designed for Render.com free tier. Stores users + game saves to disk.
No SMTP — the game itself sends emails via my Cloudflare tunnel.
"""
import os
import json
import hashlib
import secrets
import logging
import shutil
from http.server import BaseHTTPRequestHandler, HTTPServer
from datetime import datetime
from pathlib import Path


# Storage on disk
DATA_DIR = Path(os.environ.get("DATA_DIR", "/opt/render/project/src/data"))
DATA_DIR.mkdir(parents=True, exist_ok=True)
USERS_FILE = DATA_DIR / "users.json"
SAVES_DIR = DATA_DIR / "saves"
SAVES_DIR.mkdir(parents=True, exist_ok=True)


def load_users():
    if not USERS_FILE.exists():
        return {}
    try:
        return json.loads(USERS_FILE.read_text())
    except Exception:
        return {}


def save_users(users):
    USERS_FILE.write_text(json.dumps(users, indent=2))


def hash_password(password, salt):
    return hashlib.sha256(f"{salt}{password}".encode()).hexdigest()


def generate_salt():
    return secrets.token_hex(8)


CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}


class H(BaseHTTPRequestHandler):
    def log_message(self, f, *a):
        logging.info(f"{self.address_string()} {f%a}")

    def send_json(self, status, payload):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        for k, v in CORS.items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(json.dumps(payload).encode())

    def read_body(self):
        n = int(self.headers.get("Content-Length", 0))
        if n == 0:
            return {}
        return json.loads(self.rfile.read(n).decode())

    def do_OPTIONS(self):
        self.send_json(204, {})

    def do_GET(self):
        if self.path == "/health":
            return self.send_json(200, {
                "status": "ok",
                "users": len(load_users()),
                "saves": len(list(SAVES_DIR.glob("*.json"))),
                "data_dir": str(DATA_DIR),
            })
        # Get a save by player_id
        if self.path.startswith("/save/"):
            player_id = self.path.split("/")[-1]
            save_file = SAVES_DIR / f"{player_id}.json"
            if save_file.exists():
                return self.send_json(200, json.loads(save_file.read_text()))
            return self.send_json(404, {"error": "Save not found"})
        # Get all users (admin)
        if self.path == "/users":
            users = load_users()
            # Don't expose password hashes
            public_users = [
                {"username": u["username"], "email": u.get("email"), "createdAt": u.get("createdAt")}
                for u in users.values()
            ]
            return self.send_json(200, {"users": public_users})
        return self.send_json(404, {"error": "not found"})

    def do_POST(self):
        body = self.read_body()

        # Register
        if self.path == "/auth/register":
            username = body.get("username", "").strip()
            email = body.get("email", "").strip().lower()
            password = body.get("password")
            if not (username and email and password):
                return self.send_json(400, {"error": "Missing fields"})
            if len(username) < 3 or len(username) > 20:
                return self.send_json(400, {"error": "Username 3-20 chars"})
            if "@" not in email or "." not in email:
                return self.send_json(400, {"error": "Invalid email"})
            if len(password) < 6:
                return self.send_json(400, {"error": "Password 6+ chars"})
            users = load_users()
            if username in users:
                return self.send_json(400, {"error": "Username already taken"})
            for u in users.values():
                if u.get("email") == email:
                    return self.send_json(400, {"error": "Email already registered"})
            salt = generate_salt()
            password_hash = hash_password(password, salt)
            users[username] = {
                "username": username,
                "email": email,
                "passwordHash": password_hash,
                "salt": salt,
                "createdAt": datetime.now().isoformat(),
                "lastLogin": datetime.now().isoformat(),
            }
            save_users(users)
            return self.send_json(200, {
                "success": True,
                "username": username,
                "email": email,
            })

        # Login
        if self.path == "/auth/login":
            username = body.get("username", "").strip()
            password = body.get("password")
            if not (username and password):
                return self.send_json(400, {"error": "Missing fields"})
            users = load_users()
            user = users.get(username)
            if not user:
                return self.send_json(401, {"error": "Invalid username or password"})
            if user["passwordHash"] != hash_password(password, user["salt"]):
                return self.send_json(401, {"error": "Invalid username or password"})
            user["lastLogin"] = datetime.now().isoformat()
            users[username] = user
            save_users(users)
            return self.send_json(200, {
                "success": True,
                "username": username,
                "email": user.get("email"),
            })

        # Check username exists (for "Delete all" replacement etc)
        if self.path == "/auth/check":
            username = body.get("username", "").strip()
            if not username:
                return self.send_json(400, {"error": "Missing username"})
            users = load_users()
            exists = username in users
            email = users.get(username, {}).get("email")
            return self.send_json(200, {
                "username": username,
                "exists": exists,
                "email": email if exists else None,
            })

        # Forgot password - return the email on file
        if self.path == "/auth/forgot":
            username = body.get("username", "").strip()
            if not username:
                return self.send_json(400, {"error": "Missing username"})
            users = load_users()
            user = users.get(username)
            if not user:
                return self.send_json(404, {"error": "No user found"})
            return self.send_json(200, {
                "success": True,
                "email": user.get("email"),
                "username": username,
            })

        # Save game
        if self.path.startswith("/save/"):
            player_id = self.path.split("/")[-1]
            if not player_id:
                return self.send_json(400, {"error": "Missing player_id"})
            save_file = SAVES_DIR / f"{player_id}.json"
            save_file.write_text(json.dumps(body, indent=2))
            return self.send_json(200, {
                "success": True,
                "player_id": player_id,
                "saved_at": datetime.now().isoformat(),
            })

        return self.send_json(404, {"error": "not found"})

    def do_DELETE(self):
        if self.path.startswith("/save/"):
            player_id = self.path.split("/")[-1]
            save_file = SAVES_DIR / f"{player_id}.json"
            if save_file.exists():
                save_file.unlink()
            return self.send_json(200, {"success": True})
        if self.path == "/users":
            # Wipe all users (admin)
            USERS_FILE.unlink(missing_ok=True)
            return self.send_json(200, {"success": True})
        return self.send_json(404, {"error": "not found"})


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    port = int(os.environ.get("PORT", 8080))
    logging.info(f"Storage: {DATA_DIR}")
    logging.info(f"Users file: {USERS_FILE}")
    print(f"Space Traders Cloud Backend running on 0.0.0.0:{port}")
    HTTPServer(("0.0.0.0", port), H).serve_forever()
