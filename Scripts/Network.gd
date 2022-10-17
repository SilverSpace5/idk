extends Node

var websocket_url = "wss://idk.silverspace505.repl.co"
var player = load("res://Player.tscn")
var playerData = {}
var data = {}
var databaseData = {}
var lastData = {}
var connected = false
var returnData = {}
var received = []
var lastReceived = []
var deletedItems = []
var clearReceivedTimer = 0
var gotData = false
var auto = true
var admins = []
var admin = false

var peer = WebSocketClient.new()
var id = ""

func connectToServer():
	peer.disconnect_from_host()
	peer = WebSocketClient.new()
	peer.connect("connection_established", self, "_connected")
	peer.connect("connection_error", self, "_closed")
	peer.connect("connection_closed", self, "_closed")
	peer.connect("data_received", self, "_on_data")
	var err = peer.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)

func _ready():
	id = Global.getId(10)
	
	peer.connect("connection_established", self, "_connected")
	peer.connect("connection_error", self, "_closed")
	peer.connect("connection_closed", self, "_closed")
	peer.connect("data_received", self, "_on_data")
	var err = peer.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)
	
	yield(get_tree().create_timer(2), "timeout")
	while not connected:
		print("Retrying")
		connectToServer()
		yield(get_tree().create_timer(2), "timeout")

func sendMsg(data, wait=false):
	peer.get_peer(1).put_packet(JSON.print(data).to_utf8())
	if wait:
		returnData = {}
		gotData = false
		while not gotData:
			yield(get_tree().create_timer(0.1), "timeout")
		return returnData

func updateDatabaseData(id):
	sendMsg({"databaseset": databaseData, "databaseid": id})

func getDatabaseData(id):
	return yield(sendMsg({"databaseget": id}, true), "completed")

func getDatabase():
	return yield(sendMsg({"databaselist": "idk"}, true), "completed")
	
func deleteDatabaseData(id):
	sendMsg({"databasedelete": id})

func _player_connected(id):
	#Console.log2("Player Joined: " + id)
	print("Player Joined: " + id)
	#instance_player(id)

func _player_disconnected(id):
	#Console.log2("Player Left: " + id)
	#print("Player Left: " + id)
	playerLeaveGame(id)
	playerData.erase(id)

func playerJoinGame(id):
	if Global.playTime > 0.5:
		Console.log2(playerData[id]["username"] + " Joined!")
	if Global.sceneName == "Game" or Global.sceneName == "Loading":
		instance_player(id)
		Global.scene.get_node("CanvasLayer/Players").add_item(playerData[id]["username"], null, false)

func playerLeaveGame(id):
	if Global.sceneName == "Game":
		Console.log2(playerData[id]["username"] + " Left :(")
		for i in range(Global.scene.get_node("CanvasLayer/Players").get_item_count()):
			var item = Global.scene.get_node("CanvasLayer/Players").get_item_text(i)
			if item == playerData[id]["username"]:
				Global.scene.get_node("CanvasLayer/Players").remove_item(i)
	if Players.has_node(str(id)):
		Players.get_node(str(id)).queue_free()

func _closed(was_clean = false):
	var lastScene = Global.sceneName
	Console.log2("Disconnected")
	#print("disconnected: " + str(was_clean))
	connected = false
	Global.ready = false
	Global.changeScene("Disconnected")
	for node in Players.get_children():
		node.queue_free()
	
	if auto:
		while not connected:
			print("Retrying")
			connectToServer()
			yield(get_tree().create_timer(2), "timeout")
		Global.changeScene(lastScene)
		Global.ready = true

func _connected(proto):
	Console.log2("Connected")
	#print("Connected")
	connected = true
	sendMsg({"join": id, "password": "idkwhattocallthisgame"})
	#print("Connected with protocol: ", proto)
	#peer.get_peer(1).put_packet(JSON.print({"join": id, "password": "weroweinafoien"}).to_utf8())
	#Global.player = instance_player(id)

func _on_data():
	var data = JSON.parse(peer.get_peer(1).get_packet().get_string_from_utf8()).result
	#print(data)
	#print("Got data from server: ", data)
	
	var found = false
	if data["secure"]:
		var dataJSON = JSON.print(data)
		
		for data2 in received:
			if JSON.print(data2) == dataJSON:
				found = true
	
	if not found:
		if data.has("generateWorld"):
			Global.scene.generateWorld([170, 0, 200, 100, true])
		if data.has("settings"):
			var data2 = data["settings"]
			if data2["version"] > Global.version:
				Global.changeScene("Reload")
			if data2["maintenance"]:
				Global.changeScene("Maintenance")
			elif Global.sceneName == "Maintenance":
				Global.changeScene("Menu")
			auto = data2["auto"]
			admins = data2["admins"]
		if data["secure"]:
			received.append(data)
			sendMsg({"received": data})
		if data.has("send") and Global.sceneName == "Game":
			Console.log2(data["send"])
		if data.has("connected"):
			_player_connected(data["connected"])
		if data.has("disconnected"):
			_player_disconnected(data["disconnected"])
		if data.has("players"):
			for player in data["players"]:
				if player != id:
					_player_connected(player)
		if data.has("data"):
			playerData[data["id"]] = data["data"]
		if data.has("databaseget"):
			gotData = true
			returnData = data["databaseget"]
		if data.has("databaselist"):
			gotData = true
			returnData = data["databaselist"]
		if data.has("joingame"):
			playerJoinGame(data["joingame"])
		if data.has("leavegame"):
			playerLeaveGame(data["leavegame"])
		if data.has("setBlock") and Global.sceneName == "Game":
			for setBlock in data["setBlock"]:
				var block = int(setBlock[1])
				var pos = Global.scene.borderMin + Vector2(int(setBlock[0][0]), int(setBlock[0][1]))
				#print("Setting block at " + str(pos) + " to " + str(block))
				Global.scene.setBlock(pos, block, true, false)
		if data.has("removeItem") and Global.sceneName == "Game":
			Global.scene.hotbarSlots[Global.scene.hotbar.find(data["removeItem"])].amount -= 1
			if Global.scene.hotbarSlots[Global.scene.hotbar.find(data["removeItem"])].amount <= 0:
				Global.scene.hotbarSlots[Global.scene.hotbar.find(data["removeItem"])].item = -1
		if data.has("deleteItem") and Global.sceneName == "Game":
			deletedItems.append(data["deleteItem"])
		if data.has("breakBlock") and Global.sceneName == "Game":
			var itemNew = Global.scene.item.instance()
			Global.scene.add_child(itemNew)
			itemNew.id = data["breakBlock"]["id"]
			itemNew.item = data["breakBlock"]["oldBlock"]
			itemNew.position = Vector2(data["breakBlock"]["mpX"], data["breakBlock"]["mpY"])*64 + Vector2(32, 32)
	

func _process(delta):
	peer.poll()
	if Global.ready:
		playerData[id] = data
		sendMsg({"data": data, "id": id})
		admin = Global.id in admins
	clearReceivedTimer += delta
	if clearReceivedTimer >= 0.5:
		clearReceivedTimer = 0
		if Global.ready:
			if JSON.print(databaseData) != JSON.print(lastData):
				updateDatabaseData(Global.id)
				lastData = databaseData.duplicate(true)
		var i = 0
		for data2 in received:
			var dataJSON = JSON.print(data2)
			var found = false

			for data3 in lastReceived:
				if JSON.print(data3) == dataJSON:
					found = true
			if found:
				received.remove(i)
			i += 1
		lastReceived = received.duplicate(true)

func _exit_tree():
	peer.disconnect_from_host()

func instance_player(id, pos=Vector2(0, 0)) -> Object:
	var player_instance = Global.instance_node_at_location(player, Players, pos)
	player_instance.name = str(id)
	return player_instance
