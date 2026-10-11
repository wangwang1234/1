#!/usr/bin/env python3
"""Real two-process ENet regression for three consecutive rematches."""
import json
import os
from pathlib import Path
import subprocess
import time

root = Path(__file__).resolve().parents[1]
out = root / "review/qol_pass1/lan"
out.mkdir(parents=True, exist_ok=True)
processes = []
receipts = []
try:
    for role in ("host", "client"):
        path = out / f"qol_{role}.log"
        log = path.open("w")
        process = subprocess.Popen([os.environ.get("GODOT", "godot"), "--headless", "--path", str(root / "game"), "res://tests/qol_lan_peer.tscn", "--", "--test-role", role, "--port", "29921"], stdout=log, stderr=subprocess.STDOUT)
        processes.append((process, log, path))
        if role == "host":
            time.sleep(0.3)
    for process, log, path in processes:
        code = process.wait(timeout=40)
        log.close()
        content = path.read_text()
        errors = [line for line in content.splitlines() if (line.startswith("ERROR:") or "SCRIPT ERROR" in line) and not any(known in line for known in ("ALSA", "init_output_device", "resources still in use at exit"))]
        rows = [json.loads(line.removeprefix("QOL_LAN_RECEIPT ")) for line in content.splitlines() if line.startswith("QOL_LAN_RECEIPT ")]
        assert code == 0 and not errors and len(rows) == 1 and rows[0]["ok"], content[-5000:]
        receipts.extend(rows)
    (out / "qol_receipts.json").write_text(json.dumps(receipts, ensure_ascii=False, indent=2))
    print(json.dumps(receipts, ensure_ascii=False))
finally:
    for process, log, _ in processes:
        if process.poll() is None:
            process.kill()
            process.wait()
        log.close()
