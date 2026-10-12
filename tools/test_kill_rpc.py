#!/usr/bin/env python3
"""两个真实ENet进程，验证击败事件预算和AI接管后的身份恢复；无需游戏画面。"""
import json
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(os.environ.get("KILL_TEST_OUT", ROOT / "work/kill_phase1/kill_rpc"))
OUT.mkdir(parents=True, exist_ok=True)
receipts = []
for offset, case in enumerate(("reward", "takeover")):
    peers = []
    try:
        for role in ("host", "client"):
            path = OUT / f"{case}_{role}.log"
            log = path.open("w")
            proc = subprocess.Popen(
                [os.environ.get("GODOT", "godot"), "--headless", "--path", str(ROOT / "game"),
                 "res://tests/kill_rpc_peer.tscn", "--", "--role", role, "--case", case,
                 "--port", str(29840 + offset)], stdout=log, stderr=subprocess.STDOUT)
            peers.append((proc, log, path))
            if role == "host":
                time.sleep(0.3)
        for proc, log, path in peers:
            code = proc.wait(timeout=25)
            log.close()
            content = path.read_text()
            rows = [json.loads(line[len("KILL_RPC_RESULT "):]) for line in content.splitlines()
                    if line.startswith("KILL_RPC_RESULT ")]
            assert code == 0 and rows and all(row["ok"] for row in rows), content
            assert "SCRIPT ERROR" not in content and "ERROR:" not in content, content
            receipts.extend(rows)
        print(case, "passed", flush=True)
    finally:
        for proc, log, path in peers:
            if proc.poll() is None:
                proc.kill()
                proc.wait()
            log.close()
(OUT / "results.json").write_text(json.dumps(receipts, ensure_ascii=False, indent=2) + "\n")
