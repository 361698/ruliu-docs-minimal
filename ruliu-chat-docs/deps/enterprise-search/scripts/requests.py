#!/usr/bin/env python3
"""Tiny requests-compatible shim for the bundled enterprise-search scripts.

The scripts only need requests.post(...).json(). This file keeps the skill usable
on fresh macOS machines where the third-party requests package is not installed.
"""

import json as json_module
import urllib.error
import urllib.request


class Response:
    def __init__(self, status_code, text, headers=None):
        self.status_code = status_code
        self.text = text
        self.headers = headers or {}

    def json(self):
        return json_module.loads(self.text)


def post(url, headers=None, json=None, data=None, timeout=None):
    body = data
    request_headers = dict(headers or {})
    if json is not None:
        body = json_module.dumps(json, ensure_ascii=False)
        request_headers.setdefault("Content-Type", "application/json; charset=utf-8")
    if isinstance(body, str):
        body = body.encode("utf-8")

    req = urllib.request.Request(
        url,
        data=body,
        headers=request_headers,
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            text = resp.read().decode("utf-8", errors="replace")
            return Response(resp.status, text, dict(resp.headers))
    except urllib.error.HTTPError as exc:
        text = exc.read().decode("utf-8", errors="replace")
        return Response(exc.code, text, dict(exc.headers))
