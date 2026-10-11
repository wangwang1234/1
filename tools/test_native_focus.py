#!/usr/bin/env python3
"""Drive real X11 focus changes and window events, including repeated alt-tab equivalents.
Run with DISPLAY and GODOT set, within the same display/network namespace as Xvfb.
"""
import ctypes as C
import json
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(os.environ.get("BUGFIX_REVIEW", ROOT / "review/bugfix_focus"))
OUT.mkdir(parents=True, exist_ok=True)
X = C.CDLL("libX11.so.6")
D = C.c_void_p
W = C.c_ulong
for name, args, ret in [
    ("XOpenDisplay", [C.c_char_p], D),
    ("XDefaultRootWindow", [D], W),
    ("XCreateSimpleWindow", [D, W, C.c_int, C.c_int, C.c_uint, C.c_uint, C.c_uint, W, W], W),
    ("XMapWindow", [D, W], C.c_int),
    ("XSetInputFocus", [D, W, C.c_int, W], C.c_int),
    ("XQueryTree", [D, W, C.POINTER(W), C.POINTER(W), C.POINTER(C.POINTER(W)), C.POINTER(C.c_uint)], C.c_int),
    ("XFetchName", [D, W, C.POINTER(C.c_char_p)], C.c_int),
    ("XKeysymToKeycode", [D, W], C.c_uint),
    ("XSendEvent", [D, W, C.c_int, C.c_long, D], C.c_int),
    ("XFlush", [D], C.c_int),
    ("XFree", [D], C.c_int),
    ("XCloseDisplay", [D], C.c_int),
]:
    fn = getattr(X, name)
    fn.argtypes = args
    fn.restype = ret

class Event(C.Structure):
    _fields_ = [("type", C.c_int), ("serial", W), ("send_event", C.c_int), ("display", D),
                ("window", W), ("root", W), ("subwindow", W), ("time", W),
                ("x", C.c_int), ("y", C.c_int), ("x_root", C.c_int), ("y_root", C.c_int),
                ("state", C.c_uint), ("code", C.c_uint), ("same_screen", C.c_int), ("pad", C.c_long * 12)]

def wait_for(predicate, timeout=15):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        try:
            state = json.loads((OUT / "native_state.json").read_text())
            if predicate(state):
                return state
        except (OSError, json.JSONDecodeError):
            pass
        time.sleep(0.03)
    raise AssertionError("Timed out waiting for native state: " + str(state if 'state' in locals() else None))

def find_game(display, root):
    children, count, root_return, parent = C.POINTER(W)(), C.c_uint(), W(), W()
    X.XQueryTree(display, root, C.byref(root_return), C.byref(parent), C.byref(children), C.byref(count))
    found = None
    for i in range(count.value):
        name = C.c_char_p()
        if X.XFetchName(display, children[i], C.byref(name)) and name.value:
            if "满载而鼠" in name.value.decode(errors="replace"):
                found = int(children[i])
            X.XFree(name)
    if children:
        X.XFree(children)
    return found

log = (OUT / "native_focus.log").open("w")
(OUT / "native_state.json").unlink(missing_ok=True)
process = subprocess.Popen([os.environ.get("GODOT", "godot"), "--path", str(ROOT / "game"), "--resolution", "960x540", "--audio-driver", "Dummy", "res://tests/native_focus_probe.tscn"], stdout=log, stderr=subprocess.STDOUT)
display = X.XOpenDisplay(None)
assert display
root = X.XDefaultRootWindow(display)
other = X.XCreateSimpleWindow(display, root, 980, 0, 200, 200, 0, 0, 0)
X.XMapWindow(display, other)
X.XFlush(display)
receipts = []
try:
    wait_for(lambda s: s["ready"], 45)
    window = find_game(display, root)
    assert window is not None
    def focus(w):
        X.XSetInputFocus(display, w, 1, 0)
        X.XFlush(display)
    def event(kind, code, state=0):
        ev = Event(type=kind, display=display, window=window, root=root,
                   x=400, y=260, x_root=400, y_root=260, state=state, code=code, same_screen=1)
        X.XSendEvent(display, window, 0, 0, C.byref(ev))
        X.XFlush(display)
    def key(sym, down):
        event(2 if down else 3, X.XKeysymToKeycode(display, sym))
    focus(window)
    wait_for(lambda s: not s["paused"])
    for cycle in range(3):
        key(ord('w'), True)
        wait_for(lambda s: s["my"] == -1)
        event(4, 1)
        wait_for(lambda s: s["fire"])
        # Deliberately omit key/mouse releases; the lost-focus path must clear them.
        focus(other)
        wait_for(lambda s: s["paused"] and s["tree_paused"] and s["focus_pause"] and s["menu"])
        focus(window)
        if cycle == 1:
            # The focus-acquiring mouse press must not become a gunshot.
            event(4, 1)
        wait_for(lambda s: not s["paused"] and not s["menu"] and s["my"] == 0 and not s["fire"])
        if cycle == 1:
            event(5, 1, 256)
            wait_for(lambda s: not s["fire"])
        key(ord('d'), True)
        wait_for(lambda s: s["mx"] == 1)
        event(4, 1)
        wait_for(lambda s: s["fire"])
        key(ord('d'), False)
        event(5, 1, 256)
        wait_for(lambda s: s["mx"] == 0 and not s["fire"])
        receipts.append({"cycle": cycle + 1, "focus_resume_and_fresh_inputs": True})
    key(0xff1b, True)
    key(0xff1b, False)
    wait_for(lambda s: s["paused"] and not s["focus_pause"])
    focus(other)
    time.sleep(0.15)
    focus(window)
    time.sleep(0.2)
    state = wait_for(lambda s: s["paused"] and s["menu"] and not s["focus_pause"])
    key(0xff1b, True)
    key(0xff1b, False)
    wait_for(lambda s: not s["paused"])
    receipts.append({"manual_pause_preserved": True, "escape_resumes": True})
    log.flush()
    errors = [line for line in (OUT / "native_focus.log").read_text().splitlines() if "SCRIPT ERROR" in line or line.startswith("ERROR:")]
    assert not errors, errors
    (OUT / "native_receipts.json").write_text(json.dumps(receipts, indent=2))
    print(json.dumps(receipts))
finally:
    process.terminate()
    try:
        process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
    log.close()
    X.XCloseDisplay(display)
