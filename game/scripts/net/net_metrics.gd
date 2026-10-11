class_name NetMetrics
extends RefCounted


var rtt_ms: = -1.0
var jitter_ms: = 0.0
var snapshot_kbps: = 0.0
var missing_percent: = 0.0
var encode_ms: = 0.0
var _elapsed: = 0.0
var _bytes: = 0
var _received: = 0
var _missing: = 0
var _last_tick: = -1
var _net: Dictionary = Data.load_json("network")


func latency(seconds: float) -> void :
	var sample: = seconds * 1000.0
	if rtt_ms < 0:
		rtt_ms = sample
	else:
		jitter_ms = lerpf(jitter_ms, absf(sample - rtt_ms), 0.2)
		rtt_ms = lerpf(rtt_ms, sample, 0.2)


func bytes_transferred(count: int) -> void :
	_bytes += maxi(0, count)


func snapshot(tick: int) -> void :
	if _last_tick >= 0:
		_missing += maxi(0, roundi(float(tick - _last_tick) * float(_net.snapshotHz) / 60.0) - 1)
	_last_tick = tick
	_received += 1


func advance(dt: float) -> void :
	_elapsed += dt
	if _elapsed < float(_net.metricsWindow):
		return
	snapshot_kbps = float(_bytes) / 1024.0 / _elapsed
	missing_percent = 100.0 * _missing / maxi(1, _received + _missing)
	_elapsed = 0
	_bytes = 0
	_received = 0
	_missing = 0
