from flask import Flask, request, jsonify, redirect
import sqlite3
import hashlib
import time
import random
import string
import os

app = Flask(__name__)

# Database setup (works inside Docker & local)
DB_PATH = '/app/data/urls.db' if os.path.exists('/app') else './data/urls.db'

def init_db():
    """Initialize the SQLite database"""
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS urls (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            short_code TEXT UNIQUE NOT NULL,
            long_url TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()
    print(f"✅ Database initialized at: {DB_PATH}")

def generate_short_code(url, length=6):
    """Generate a short code"""
    hash_obj = hashlib.md5(url.encode())
    hash_hex = hash_obj.hexdigest()
    random_chars = ''.join(random.choices(string.ascii_letters + string.digits, k=3))
    combined = hash_hex + random_chars
    return combined[:length]

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


@app.route('/')
def index():
    """Serve simple UI or fallback"""
    try:
        with open('index.html', 'r') as f:
            return f.read()
    except:
        return """
        <h1>URL Shortener API</h1>
        <p>POST /shorten {"url": "https://example.com"}</p>
        """


@app.route('/health')
def health_check():
    return jsonify({'status': 'healthy', 'timestamp': time.time()})


@app.route('/shorten', methods=['POST'])
def shorten_url():
    """Shorten a URL"""
    try:
        data = request.get_json()
        if not data or 'url' not in data:
            return jsonify({'error': 'URL is required'}), 400

        long_url = data['url']

        if not long_url.startswith(('http://', 'https://')):
            return jsonify({'error': 'URL must start with http:// or https://'}), 400

        # generate short code
        short_code = generate_short_code(long_url)

        conn = get_db_connection()
        cursor = conn.cursor()

        # avoid collisions
        for attempt in range(5):
            cursor.execute("SELECT id FROM urls WHERE short_code = ?", (short_code,))
            if cursor.fetchone() is None:
                break
            short_code = generate_short_code(long_url + str(attempt))
        else:
            conn.close()
            return jsonify({"error": "Failed to generate unique short code"}), 500

        # save to DB
        cursor.execute(
            "INSERT INTO urls (short_code, long_url) VALUES (?, ?)",
            (short_code, long_url)
        )
        conn.commit()
        conn.close()

        print(f"✅ Shortened URL: {long_url} -> {short_code}")

        # Use the current request's host URL to build the short URL dynamically
        base_url = request.host_url

        response = {
            "short_code": short_code,
            "short_url": f"{base_url}{short_code}",
            "long_url": long_url
        }

        return jsonify(response), 201

    except Exception as e:
        print(f"❌ Error: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/<short_code>')
def redirect_url(short_code):
    """Redirect to original URL"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT long_url FROM urls WHERE short_code = ?", (short_code,))
        row = cursor.fetchone()
        conn.close()

        if row:
            print(f"🔁 Redirecting {short_code} → {row['long_url']}")
            return redirect(row['long_url'])
        else:
            return jsonify({'error': 'Short URL not found'}), 404

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/stats')
def stats():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) as total FROM urls")
        total = cursor.fetchone()['total']
        conn.close()

        return jsonify({
            "total_shortened_urls": total,
            "service": "URL Shortener",
            "version": "1.0.0"
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/list')
def list_urls():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT short_code, long_url, created_at FROM urls ORDER BY created_at DESC LIMIT 10")
        rows = cursor.fetchall()
        conn.close()

        base_url = request.host_url

        urls = []
        for r in rows:
            urls.append({
                "short_code": r["short_code"],
                "long_url": r["long_url"],
                "created_at": r["created_at"],
                "short_url": f"{base_url}{r['short_code']}"
            })

        return jsonify({"recent_urls": urls})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == "__main__":
    print("🚀 Starting URL Shortener")
    print("="*40)
    init_db()
    app.run(host="0.0.0.0", port=5000, debug=True)
