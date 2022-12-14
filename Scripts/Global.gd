extends Node

var player
var scene
var sceneName = "Connect"
var ready = false
var worldMap = []
var id = ""
var randomSeed = randi()
var noise
var playTime = 0
var aToZ = "abcdefghijklmnopqrstuvwxyzABCDEFFGHIJKLMNOPQRSTUVWXYZ"
var letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

var version = 0

var defaultDatabase = {
	"pos": [0, 0],
	"hotbar": [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
	"hotbarAmount": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	"username": "Unnamed",
	"player": 3
}

func changeScene(newScene):
	sceneName = newScene
	get_tree().change_scene("res://Scenes/" + newScene + ".tscn")

func _process(delta):
	if sceneName == "Game":
		playTime += delta
		Network.data["playing"] = true
	else:
		playTime = 0
		Network.data["playing"] = false
	if ready:
		Network.data["username"] = Network.databaseData["username"]
	scene = get_tree().get_root().get_node(sceneName)

func _ready():
	randomize()
	randomSeed = randi()
	
	while not Network.connected:
		yield(get_tree().create_timer(0.1), "timeout")
	
	var data = SaveLoad.loadData("silver-idk-id5.data")
	if data.has("id"):
		id = data["id"]
	else:
		id = getId(10)
		Network.databaseData = defaultDatabase.duplicate(true)
		Network.updateDatabaseData(id)
		SaveLoad.saveData("silver-idk-id5.data", {"id": id})
	
	#print("Getting database data...")
	Console.log2("Getting database data...")
	var list = yield(Network.getDatabase(), "completed")
	Network.databaseData = yield(Network.getDatabaseData(id), "completed")
	if Network.databaseData.has("inventory"):
		for i in range(len(Network.databaseData["inventory"])-1):
			Network.databaseData["inventory"][i] = int(Network.databaseData["inventory"][i])
	if Network.databaseData.has("inventoryAmount"):
		for i in range(len(Network.databaseData["inventoryAmount"])-1):
			Network.databaseData["inventoryAmount"][i] = int(Network.databaseData["inventoryAmount"][i])
	for key in Network.databaseData:
		if not key in defaultDatabase.keys():
			Network.databaseData.erase(key)
	
	for key in defaultDatabase:
		if not key in Network.databaseData.keys():
			Network.databaseData[key] = defaultDatabase[key]
	print("Got data: " + str(Network.databaseData))
	#Console.log2("Got data: " + str(Network.databaseData))
	Console.log2("Done")
	
	ready = true

func setupRandom(seed2):
	if seed2:
		randomSeed = seed2
	noise = OpenSimplexNoise.new()
	noise.seed = randomSeed
	noise.octaves = 4
	noise.period = 100
	noise.persistence = 0.5

func getRandom(min2, max2, val):
	return clamp(abs(noise.get_noise_1d(val*142))*2.85, 0, 1) * (max2 - min2) + min2

func decode(encoded):
	var decoded = []
	var index = 0
	var block = "0"
	var length = 1
	while index < len(encoded)-1:
		block = ""
		while not encoded[index] in aToZ and index < len(encoded)-1:
			block += encoded[index]
			index += 1
		length = int(aToZ.find(encoded[index]))
		index += 1
		
		for i in range(length):
			decoded.append(block)
	return decoded

func encode(array):
	var encoded = ""
	var length = 1
	var lastBlock = array[0]
	var i = 0
	for item in array:
		i += 1
		if i > 1:
			if lastBlock == item and length < 26:
				length += 1
			else:
				encoded += str(lastBlock) + str(aToZ[length])
				length = 1
				lastBlock = item
	encoded += str(lastBlock) + str(aToZ[length])
	return encoded

func instance_node_at_location(node: Object, parent: Object, location: Vector2) -> Object:
	var node_instance = instance_node(node, parent)
	node_instance.global_position = location
	return node_instance

func instance_node(node: Object, parent: Object) -> Object:
	var node_instance = node.instance()
	parent.add_child(node_instance)
	return node_instance

func getVector(string):
	var vector = string
	vector[0] = "["
	vector[len(vector)-1] = "]"
	vector = parse_json(vector)
	vector = Vector2(vector[0], vector[1])
	return vector
	
func getId(digits) -> String:
	var id = ""
	for i in range(digits):
		randomize()
		id += str(letters[floor(rand_range(0, len(letters)-1))])
	return id
