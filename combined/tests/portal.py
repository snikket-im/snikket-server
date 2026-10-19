"""Exercise the running portal against its real Prosody backend and HTTPS proxy."""
import base64
import http.cookiejar
import re
import ssl
import sys
import urllib.parse
import urllib.request

base = "https://example.test"
client = urllib.request.build_opener(
    urllib.request.ProxyHandler({}),
    urllib.request.HTTPSHandler(context=ssl._create_unverified_context()),
    urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()),
)


def request(path, data=None, headers=None):
    req = urllib.request.Request(base + path, data=data, headers=headers or {})
    with client.open(req, timeout=10) as response:
        assert response.status == 200
        return response.url, response.read().decode()


def csrf(html):
    return re.search(r'name="csrf_token"[^>]*value="([^"]+)"', html).group(1)


def form(path, data):
    return request(path, urllib.parse.urlencode(data).encode())


_, page = request("/login", headers={"Accept-Language": "de"})
assert 'lang="de"' in page and "Anmelden" in page
url, _ = form("/login", {
    "address": "review@example.test",
    "password": "review-test-password",
    "csrf_token": csrf(page),
})
assert url.endswith("/user/"), url
_, page = request("/user/profile")
if "--check" in sys.argv:
    assert "Review Avatar" in page
    print("PASS login and persisted profile after restart/storage migration")
    sys.exit(0)

url, page = form("/user/profile", {
    "nickname": "Review Name",
    "profile_access_model": "open",
    "csrf_token": csrf(page),
})
assert url.endswith("/user/profile") and "Review Name" in page
boundary = "snikket-smoke-boundary"
parts = []
for key, value in {
    "nickname": "Review Avatar",
    "profile_access_model": "open",
    "csrf_token": csrf(page),
}.items():
    parts.append((f'--{boundary}\r\nContent-Disposition: form-data; name="{key}"\r\n\r\n{value}\r\n').encode())
png = base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9ZQmcAAAAASUVORK5CYII=")
parts.append((f'--{boundary}\r\nContent-Disposition: form-data; name="avatar"; filename="avatar.png"\r\nContent-Type: image/png\r\n\r\n').encode() + png + b"\r\n")
parts.append(f"--{boundary}--\r\n".encode())
_, page = request("/user/profile", b"".join(parts), {"Content-Type": f"multipart/form-data; boundary={boundary}"})
assert "Review Avatar" in page
print("PASS localization, login, nickname and avatar upload with CSRF")
