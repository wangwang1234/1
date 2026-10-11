class_name LanDiscovery
extends RefCounted
## Requests use an ephemeral reply port, so several clients can scan on one PC.
signal changed
var rooms: Dictionary = {}
var socket: PacketPeerUDP
var hosting := false
var scanning := false
var advertisement: Dictionary = {}
var error := OK
var _age := 0.0
var _nonce := ""
var _net: Dictionary = Data.load_json("network")
const MAGIC := "manzai-lan"

func start_host(info: Dictionary, listen_port: int = 0) -> Error:
	stop()
	socket = PacketPeerUDP.new()
	error = socket.bind(listen_port if listen_port > 0 else int(_net.discoveryPort), "0.0.0.0")
	hosting = error == OK
	advertisement = info.duplicate(true)
	return error

func start_scan() -> Error:
	stop()
	socket = PacketPeerUDP.new()
	error = socket.bind(0, "0.0.0.0")
	if error != OK:
		return error
	socket.set_broadcast_enabled(true)
	scanning = true
	_nonce = Crypto.new().generate_random_bytes(12).hex_encode()
	_age = float(_net.discoveryInterval)
	return OK

func query(address: String = "255.255.255.255", listen_port: int = 0) -> void:
	if not scanning:
		return
	_send({"magic": MAGIC, "kind": "query", "nonce": _nonce}, address,
		listen_port if listen_port > 0 else int(_net.discoveryPort))

func _send(packet: Dictionary, address: String, port: int) -> void:
	if socket.set_dest_address(address, port) == OK:
		socket.put_packet(JSON.stringify(packet).to_utf8_buffer())

func advance(dt: float) -> void:
	if socket == null or not socket.is_bound():
		return
	_age += dt
	if scanning and _age >= float(_net.discoveryInterval):
		_age = 0
		query()
		query("127.0.0.1")
	var updated := false
	# Bound work and packet size; discovery never instantiates received objects.
	for i in mini(socket.get_available_packet_count(), 32):
		var bytes := socket.get_packet()
		var address := socket.get_packet_ip()
		var port := socket.get_packet_port()
		if bytes.size() > 1400:
			continue
		var value: Variant = JSON.parse_string(bytes.get_string_from_utf8())
		if not value is Dictionary or value.get("magic") != MAGIC:
			continue
		if hosting and value.get("kind") == "query" and value.get("nonce") is String and value.nonce.length() <= 64:
			var reply := advertisement.duplicate(true)
			reply.merge({"magic": MAGIC, "kind": "room", "nonce": value.nonce}, true)
			_send(reply, address, port)
		elif scanning and value.get("kind") == "room" and value.get("nonce") == _nonce:
			var row := clean_room(value, address)
			if row.is_empty():
				continue
			var key := "%s:%d" % [address, row.port]
			row.age = 0.0
			for field in ["name", "state", "count", "capacity", "mode", "signature"]:
				updated = updated or not rooms.has(key) or rooms[key][field] != row[field]
			rooms[key] = row
	for key in rooms.keys():
		rooms[key].age += dt
		if rooms[key].age > float(_net.discoveryExpiry):
			rooms.erase(key)
			updated = true
	if updated:
		changed.emit()

static func clean_room(value: Dictionary, address: String) -> Dictionary:
	if not address.is_valid_ip_address() or address.contains(":"):
		return {}
	if not NetInput.finite_number(value.get("port")):
		return {}
	if value.port < 1024 or value.port > 65535 or value.port != floor(float(value.port)):
		return {}
	var port := int(value.port)
	if not value.get("name") is String or not value.get("signature") is String:
		return {}
	if value.signature.length() != 64:
		return {}
	for i in 64:
		if not "0123456789abcdef".contains(value.signature.substr(i, 1).to_lower()):
			return {}
	if not value.get("state") in ["open", "full", "playing"] or not value.get("mode") in ["slice", "full"]:
		return {}
	if not NetInput.finite_number(value.get("count")):
		return {}
	var limit := int(Data.load_json("network").maxPlayers)
	if not NetInput.finite_number(value.get("capacity")):
		return {}
	if value.capacity < 2 or value.capacity > limit or value.capacity != floor(float(value.capacity)):
		return {}
	var capacity := int(value.capacity)
	if value.count < 1 or value.count > capacity or value.count != floor(float(value.count)):
		return {}
	var count := int(value.count)
	return {"address": address, "port": port, "name": String(value.name).replace("\n", " ").substr(0, 16),
		"signature": String(value.signature).substr(0, 64), "state": value.state, "mode": value.mode, "count": count, "capacity": capacity}

func stop() -> void:
	if socket != null:
		socket.close()
	socket = null
	hosting = false
	scanning = false
	rooms.clear()
	_age = 0
