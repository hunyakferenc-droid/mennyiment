"""Read-only HTTP regressions against INDITAS.ps1 on 127.0.0.1:7357.

Python is only a developer test dependency; the launcher itself needs none.
Start the server first, then pass the same extracted web directory with --root.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import http.client
import json
from pathlib import Path
import socket
import time

parser = argparse.ArgumentParser()
parser.add_argument("--root", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
checks = []


def get(path, method="GET"):
    connection = http.client.HTTPConnection("127.0.0.1", 7357, timeout=20)
    try:
        connection.request(method, path)
        response = connection.getresponse()
        return response.status, dict(response.getheaders()), response.read()
    finally:
        connection.close()


expected = (args.root / "version.json").read_bytes()
status, headers, body = get("/version.json")
assert status == 200 and body == expected
checks.append("Normal GET returns the exact version document")

with socket.create_connection(("127.0.0.1", 7357), timeout=5) as delayed:
    time.sleep(1)
    delayed.sendall(b"GET /version.json HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n")
    response = http.client.HTTPResponse(delayed)
    response.begin()
    assert response.status == 200 and response.read() == expected
checks.append("Valid headers arriving one second after TCP connect still receive a complete 200 response")

with socket.create_connection(("127.0.0.1", 7357), timeout=5):
    start = time.monotonic()
    assert get("/version.json")[2] == expected
    elapsed = time.monotonic() - start
    assert elapsed < 2, elapsed
checks.append("An idle preconnect does not block another client's request")

wasm = "canvaskit/chromium/canvaskit.wasm"
data = (args.root / wasm).read_bytes()
digest = hashlib.sha256(data).hexdigest()


def download(_):
    status, headers, body = get("/" + wasm)
    assert status == 200 and headers["Content-Type"] == "application/wasm"
    assert int(headers["Content-Length"]) == len(data)
    assert hashlib.sha256(body).hexdigest() == digest
    return len(body)


with ThreadPoolExecutor(max_workers=6) as pool:
    lengths = list(pool.map(download, range(12)))
assert lengths == [len(data)] * 12
checks.append("Twelve complete WASM downloads on six concurrent clients match the file SHA-256")
status, headers, body = get("/" + wasm, "HEAD")
assert status == 200 and not body and int(headers["Content-Length"]) == len(data)
checks.append("HEAD sends the correct WASM length without a response body")
assert get("/%2e%2e/forbidden.txt")[0] == 403
checks.append("Encoded traversal is forbidden")
assert get("/no-such-resource-228")[0] == 404
checks.append("Missing files return 404")
assert get("/version.json", "POST")[0] == 405
checks.append("Unsupported write methods return 405")
result = {"checks": checks, "passed": len(checks), "idleRequestSeconds": elapsed,
          "wasmBytes": len(data), "wasmSha256": digest,
          "parallelDownloads": len(lengths), "server": "127.0.0.1:7357"}
args.output.write_text(json.dumps(result, indent=2) + "\n")
print(f"{len(checks)} HTTP checks passed; 12 full WASM downloads verified")
