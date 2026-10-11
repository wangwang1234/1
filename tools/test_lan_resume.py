#!/usr/bin/env python3
"""Two real Godot ENet peers plus UDP room discovery; no mocked transport."""
import json, os, pathlib, subprocess, time, threading, socket, select, random, heapq
ROOT = pathlib.Path(__file__).resolve().parents[1]
GODOT = os.environ.get("GODOT", "godot")
OUT = pathlib.Path(os.environ.get("LAN_OUT", ROOT / "review/lan_input_lobby"))
OUT.mkdir(parents=True, exist_ok=True)
receipts = []
class Proxy:
    def __init__(self, target, stress=False):
        self.front = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.front.bind(("127.0.0.1", 0))
        self.backs = {}
        self.clients = {}
        self.target = ("127.0.0.1", target)
        self.stopped = False
        self.packets = self.lost = 0
        self.burst_dropped = 0
        self.stress = stress
        self.started = None
        self.thread = threading.Thread(target=self.run, daemon=True)
        self.thread.start()
    def run(self):
        rng, queue, serial = random.Random(731), [], 0
        while not self.stopped:
            now = time.monotonic()
            while queue and queue[0][0] <= now:
                _, _, sock, data, dest = heapq.heappop(queue)
                sock.sendto(data, dest)
            ready, _, _ = select.select([self.front, *self.clients], [], [], 0.003)
            for sock in ready:
                data, address = sock.recvfrom(65535)
                self.packets += 1
                if sock is self.front:
                    if address not in self.backs:
                        back = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                        back.bind(("127.0.0.1", 0))
                        self.backs[address] = back
                        self.clients[back] = address
                    output, dest = self.backs[address], self.target
                else:
                    output, dest = self.front, self.clients[sock]
                if dest is None:
                    continue
                if self.started is None:
                    self.started = time.monotonic()
                age = time.monotonic() - self.started
                burst = self.stress and (25 <= age < 26.2 or 55 <= age < 65)
                if burst or rng.random() < (0.04 if self.stress else 0.02):
                    self.lost += 1
                    self.burst_dropped += int(burst)
                    continue
                serial += 1
                heapq.heappush(queue, (time.monotonic() + rng.uniform(.025, .100 if self.stress else .075), serial, output, data, dest))
    def close(self):
        self.stopped = True
        self.thread.join()
        self.front.close()
        for back in self.clients:
            back.close()

for index, scenario in enumerate(("resume", "expiry", "invalid", "mismatch", "quality", "ui", "ghost", "pending", "malformed", "stress", "return", "return_ui", "actions")):
    if os.environ.get("LAN_ONLY") and scenario != os.environ["LAN_ONLY"]:
        continue
    peers = []
    proxy = Proxy(29865 + index, scenario == "stress") if scenario in ("quality", "stress") else None
    try:
        for role in ("host", "client"):
            path = OUT / f"{scenario}_{role}.log"
            log = path.open("w")
            p = subprocess.Popen([GODOT, "--headless", "--path", str(ROOT / "game"),
                "res://tests/lan_action_peer.tscn" if scenario == "actions" else "res://tests/lan_resume_peer.tscn", "--", "--test-role", role,
                "--case", "resume" if scenario in ("quality", "ui", "ghost") else ("return" if scenario == "return_ui" else scenario), "--port", str(29865 + index)] +
                (["--quality", "1", "--join-port", str(proxy.front.getsockname()[1])] if proxy else (["--ui", "1"] if scenario in ("ui", "return_ui") else (["--ghost", "1"] if scenario == "ghost" else []))), stdout=log, stderr=subprocess.STDOUT)
            peers.append((p, log, path))
            if role == "host":
                time.sleep(0.25)
        for p, log, path in peers:
            code = p.wait(timeout=180 if scenario == "stress" else 35)
            log.close()
            text = path.read_text()
            errors = [line for line in text.splitlines() if (line.startswith("ERROR:") or "SCRIPT ERROR" in line)
                and not any(noise in line for noise in ("ALSA", "init_output_device", "resources still in use at exit", "ObjectDB instances were leaked"))]
            assert code == 0 and not errors, text[-4000:]
            rows = [json.loads(line[8:]) for line in text.splitlines() if line.startswith("RECEIPT ")]
            assert len(rows) == 1 and rows[0]["ok"], text[-4000:]
            receipts.extend(rows)
        print(scenario, "passed", flush=True)
    finally:
        for p, log, path in peers:
            if p.poll() is None:
                p.kill()
                p.wait()
            log.close()
        if proxy:
            proxy.close()
            receipts.append({"case": scenario + "-proxy", "ok": True, "packets": proxy.packets, "dropped": proxy.lost, "burst_dropped": proxy.burst_dropped, "one_way_delay_ms": [25, 100 if proxy.stress else 75], "random_loss": 0.04 if proxy.stress else 0.02, "blackouts_seconds": [[25, 26.2], [55, 65]] if proxy.stress else []})
if not os.environ.get("LAN_ONLY") or os.environ["LAN_ONLY"] == "ten":
    # Ten real processes on the full map: host + 9 clients, then an eleventh that must be refused.
    peers, port = [], 29900
    try:
        specs = [("host", [])] + [("client", ["--idx", str(i)] + (["--quit", "1"] if i == 9 else [])) for i in range(1, 10)] + [("overflow", ["--idx", "10", "--overflow", "1"])]
        for name, extra in specs:
            path = OUT / f"ten_{name}{extra[1] if extra else ''}.log"
            log = path.open("w")
            p = subprocess.Popen([GODOT, "--headless", "--path", str(ROOT / "game"), "res://tests/lan_multi_peer.tscn", "--",
                "--test-role", "host" if name == "host" else "client", "--port", str(port), "--players", "10"] + extra, stdout=log, stderr=subprocess.STDOUT)
            peers.append((p, log, path))
            time.sleep(0.25)
        for p, log, path in peers:
            code = p.wait(timeout=200)
            log.close()
            text = path.read_text()
            errors = [line for line in text.splitlines() if (line.startswith("ERROR:") or "SCRIPT ERROR" in line)
                and not any(noise in line for noise in ("ALSA", "init_output_device", "resources still in use at exit", "ObjectDB instances were leaked"))]
            assert code == 0 and not errors, path.name + "\n" + text[-4000:]
            rows = [json.loads(line[8:]) for line in text.splitlines() if line.startswith("RECEIPT ")]
            assert len(rows) == 1 and rows[0]["ok"], path.name + "\n" + text[-4000:]
            rows[0].update(*[json.loads(line[7:]) for line in text.splitlines() if line.startswith("METRIC ")])
            receipts.extend(rows)
        print("ten passed", flush=True)
    finally:
        for p, log, path in peers:
            if p.poll() is None:
                p.kill()
                p.wait()
            log.close()
if not os.environ.get("LAN_ONLY") or os.environ["LAN_ONLY"] == "lobby":
    result = subprocess.run([GODOT, "--headless", "--path", str(ROOT / "game"), "res://tests/lan_lobby_state.tscn"], capture_output=True, text=True, timeout=20)
    output = result.stdout + result.stderr
    (OUT / "lobby_map.log").write_text(output)
    rows = [json.loads(line[8:]) for line in output.splitlines() if line.startswith("RECEIPT ")]
    assert result.returncode == 0 and "SCRIPT ERROR" not in output and len(rows) == 1 and rows[0]["ok"], output
    receipts.extend(rows)
    print("lobby passed", flush=True)
(OUT / "integration.json").write_text(json.dumps(receipts, ensure_ascii=False, indent=2))
