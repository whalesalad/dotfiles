"""Failure/recovery tests; no audio, clipboard, or desktop side effects."""
import argparse
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch
import urllib.error
import io

spec = importlib.util.spec_from_file_location("adapter", Path(__file__).with_name("remote-fallback.py"))
adapter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(adapter)


class FallbackTests(unittest.TestCase):
    def setUp(self):
        self.backend = adapter.Backend(argparse.Namespace(
            remote_url="http://127.0.0.1:18080/v1/audio/transcriptions",
            remote_timeout=8))
        self.notifications = []
        self.local_requests = []
        self.backend.notify = lambda *args: self.notifications.append(args)
        self.backend.local = self.local

    def local(self, body, content_type):
        self.local_requests.append((body, content_type))
        return {"text": "local result"}

    def test_failure_preserves_audio_and_notifies_once(self):
        with patch.object(adapter.urllib.request, "urlopen", side_effect=urllib.error.URLError("offline")) as remote:
            for _ in range(2):
                self.assertEqual(self.backend.transcribe(b"original audio", "multipart/form-data"),
                                 {"text": "local result"})
        self.assertEqual(remote.call_count, 1)
        self.assertEqual(self.local_requests, [(b"original audio", "multipart/form-data")] * 2)
        self.assertEqual(len(self.notifications), 1)

    def test_timeout_falls_back(self):
        with patch.object(adapter.urllib.request, "urlopen", side_effect=TimeoutError):
            self.assertEqual(self.backend.transcribe(b"audio", "multipart/form-data"), {"text": "local result"})
        self.assertTrue(self.backend.offline)

    def test_invalid_response_falls_back(self):
        with patch.object(adapter.urllib.request, "urlopen", return_value=io.BytesIO(b'{"error":"bad"}')):
            self.assertEqual(self.backend.transcribe(b"audio", "multipart/form-data"), {"text": "local result"})

    def test_recovery_returns_remote_once(self):
        self.backend.offline = True
        with patch.object(adapter.urllib.request, "urlopen", return_value=io.BytesIO(b'{"text":"remote result"}')):
            self.assertEqual(self.backend.transcribe(b"audio", "multipart/form-data"), {"text": "remote result"})
        self.assertFalse(self.backend.offline)
        self.assertEqual(self.local_requests, [])
        self.assertEqual(len(self.notifications), 1)

    def test_local_failure_propagates(self):
        self.backend.local = lambda *_: (_ for _ in ()).throw(RuntimeError("GPU failed"))
        with patch.object(adapter.urllib.request, "urlopen", side_effect=TimeoutError):
            with self.assertRaises(RuntimeError):
                self.backend.transcribe(b"audio", "multipart/form-data")


if __name__ == "__main__":
    unittest.main()
