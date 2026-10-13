#!/usr/bin/env python3
"""Loopback OpenAI transcription adapter: SSH-forwarded Whisper, then local CLI.

Audio exists only in memory or a private temporary directory during fallback.
The Voxtype daemon owns clipboard output and transcript journaling.
"""
import argparse
import email.policy
import email.parser
import http.server
import json
import logging
import os
import subprocess
import tempfile
import threading
import time
import urllib.request

LOG = logging.getLogger("voxtype-fallback")


class Backend:
    def __init__(self, args):
        self.args = args
        self.lock = threading.Lock()
        self.offline = False
        self.retry_at = 0.0

    def notify(self, title, message):
        try:
            result = subprocess.run(["notify-send", "--app-name=Voxtype", title, message],
                                    timeout=3, check=False, stdout=subprocess.DEVNULL,
                                    stderr=subprocess.DEVNULL)
            if result.returncode:
                LOG.warning("Desktop notification command failed")
        except (OSError, subprocess.TimeoutExpired):
            LOG.warning("Desktop notification unavailable")

    def local(self, body, content_type):
        message = email.parser.BytesParser(policy=email.policy.default).parsebytes(
            b"Content-Type: " + content_type.encode("ascii") + b"\r\nMIME-Version: 1.0\r\n\r\n" + body)
        if not message.is_multipart():
            raise ValueError("Expected multipart audio")
        audio = next((part.get_payload(decode=True) for part in message.iter_parts()
                      if part.get_param("name", header="content-disposition") == "file"), None)
        if not audio:
            raise ValueError("Missing audio file")
        with tempfile.TemporaryDirectory(prefix="voxtype-fallback-") as folder:
            path = os.path.join(folder, "audio.wav")
            with open(path, "wb") as stream:
                stream.write(audio)
            result = subprocess.run(
                [self.args.local_binary, "-q", "--config", self.args.local_config,
                 "--whisper-mode", "local", "transcribe", path],
                capture_output=True, text=True, timeout=self.args.local_timeout)
            if result.returncode:
                raise RuntimeError("Local transcription failed; see model/driver configuration")
            # Voxtype 0.7.5's file CLI prints three diagnostic lines to stdout.
            lines = result.stdout.splitlines()
            prefixes = ("Loading audio file:", "Audio format:", "Processing ")
            if len(lines) < 3 or not all(lines[i].startswith(p) for i, p in enumerate(prefixes)):
                raise RuntimeError("Unexpected local CLI output format")
            return {"text": "\n".join(lines[3:]).strip()}

    def transcribe(self, body, content_type):
        # Bound concurrency: eager chunks must not spawn simultaneous GPU/CPU jobs.
        with self.lock:
            if time.monotonic() >= self.retry_at:
                try:
                    request = urllib.request.Request(
                        self.args.remote_url, data=body,
                        headers={"Content-Type": content_type}, method="POST")
                    # 16 kHz mono PCM is ~32 kB/s. Allow longer whole recordings
                    # more compute time, while eager chunks fail over promptly.
                    timeout = max(self.args.remote_timeout, min(45, len(body) / 32000 * 0.06))
                    with urllib.request.urlopen(request, timeout=timeout) as response:
                        result = json.load(response)
                    if not isinstance(result.get("text"), str):
                        raise ValueError("Remote response has no text")
                    if self.offline:
                        self.notify("YOLO transcription restored", "Dictation is using YOLO's GPU again.")
                    self.offline = False
                    LOG.info("Transcription completed on YOLO")
                    return {"text": result["text"]}
                except Exception as error:
                    LOG.warning("YOLO unavailable (%s); using local model", type(error).__name__)
                    self.retry_at = time.monotonic() + 15
                    if not self.offline:
                        self.notify("YOLO unavailable — using local transcription",
                                    "YOLO or its network connection is unavailable. Dictation continues on Chewy.")
                    self.offline = True
            result = self.local(body, content_type)
            LOG.info("Transcription completed locally")
            return result


def handler_for(backend):
    class Handler(http.server.BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass

        def respond(self, status, value):
            payload = json.dumps(value).encode()
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

        def do_GET(self):
            self.respond(200 if self.path == "/health" else 404,
                         {"status": "ready", "backend": "local" if backend.offline else "remote"})

        def do_POST(self):
            if self.path != "/v1/audio/transcriptions":
                self.respond(404, {"error": "Unknown endpoint"})
                return
            try:
                self.connection.settimeout(20)
                length = int(self.headers.get("Content-Length", "0"))
                if not 0 < length <= 25 * 1024 * 1024:
                    self.respond(413, {"error": "Audio must be between 1 byte and 25 MiB"})
                    return
                body = self.rfile.read(length)
                if len(body) != length:
                    raise ValueError("Incomplete request")
                result = backend.transcribe(body, self.headers.get("Content-Type", ""))
                self.respond(200, result)
            except Exception as error:
                LOG.error("Transcription failed (%s)", type(error).__name__)
                self.respond(502, {"error": "Transcription failed on remote and/or local backend"})
    return Handler


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=18081)
    parser.add_argument("--remote-url", default="http://127.0.0.1:18080/v1/audio/transcriptions")
    parser.add_argument("--remote-timeout", type=float, default=3)
    parser.add_argument("--local-timeout", type=float, default=300)
    parser.add_argument("--local-binary", default="/usr/lib/voxtype/voxtype-vulkan")
    parser.add_argument("--local-config", default=os.path.expanduser("~/.config/voxtype/local-fallback.toml"))
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    os.umask(0o077)
    server = http.server.ThreadingHTTPServer(("127.0.0.1", args.port), handler_for(Backend(args)))
    LOG.info("Fallback adapter listening on loopback port %s", args.port)
    server.serve_forever()


if __name__ == "__main__":
    main()
