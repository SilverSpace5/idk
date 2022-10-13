extends Node2D

var frame = 0
var frameTimer = 0
var nearbyBlockTimer = 99
var selectedSlot = 1
var lastPlaced = -2
var hotbar = [-1, -1, -1, -1, -1]
var hotbarAmount = [0, 0, 0, 0, 0]
var hotbarSlots = [null, null, null, null, null]
var hotbarCooldown = [0, 0, 0, 0, 0]
var item = load("res://Item.tscn")
var godmode = false
var updated = false
var setBlockQueue = []
var nearbyBlocks = []
var lastPlayerPos = Vector2(999, 999)

export var saving = true
export var loading = true
export var borderMin = Vector2(0, 0)
export var borderMax = Vector2(0, 0)

"""
Blocks:
0 - Air | 1 - Dirt | 2 - Glass
3 - Gold Ore | 4 - Grey | 5 - Grass
6 - Wood | 7 - Gold | 8 - Platform
9 - Stone | 10 - Leaf | 11 - Log
12 - Obsidian | 13 - Red | 14 - Orange
15 - Yellow | 16 - Green | 17 - Blue
18 - Purple | 19 - White | 20 - Black
21 - Test | 23 - Rainbow | 29 - Water 
37 - Lava
"""

var blocks = {
	"air": 0,
	"dirt": 1,
	"glass": 2,
	"gold ore": 3,
	"grey": 4
}

func getWorldList(from, to):
	var worldList = []
	for x in range(to.x-from.x):
		for y in range(to.y-from.y):
			worldList.append($World.get_cell(from.x+x, from.y+y))
	return worldList

func loadWorldList(from, to, worldList):
	for x in range(to.x-from.x):
		for y in range(to.y-from.y):
			$World.set_cell(from.x+x, from.y+y, int(worldList[y+x*(to.y-from.y)]))

func updateNearbyBlocks():
	if updated:
		return
	updated = true
	var screenWidth = 1536*$Camera2D.zoom.x
	var screenHeight = 900*$Camera2D.zoom.y
	var playerPos = Global.player.position
	nearbyBlocks = []
	for tilePos in $World.get_used_cells():
		if abs(playerPos.x - tilePos.x*64) < screenWidth and abs(playerPos.y - tilePos.y*64) < screenHeight:
			nearbyBlocks.append(tilePos)
	worldUpdated()

func getBlocks(id):
	var foundBlocks = []
	for tilePos in nearbyBlocks:
		if $World.get_cellv(tilePos) == id:
			foundBlocks.append(tilePos)
	return foundBlocks

func worldUpdated():
	var screenWidth = 1024*$Camera2D.zoom.x
	var screenHeight = 600*$Camera2D.zoom.y
	var playerPos = Global.player.position
	for tilePos in getBlocks(1):
		if abs(playerPos.x - tilePos.x*64) < screenWidth and abs(playerPos.y - tilePos.y*64) < screenHeight:
			if $World.get_cell(tilePos.x, tilePos.y - 1) == -1:
				setBlock(tilePos, 5, true, false)
	for tilePos in getBlocks(5):
		if abs(playerPos.x - tilePos.x*64) < screenWidth and abs(playerPos.y - tilePos.y*64) < screenHeight:
			if $World.get_cell(tilePos.x, tilePos.y - 1) != -1:
				setBlock(tilePos, 1, true, false)

func getWorld():
	var worldMap = []
	for tilePos in $World.get_used_cells():
		worldMap.append([[tilePos.x, tilePos.y], $World.get_cellv(tilePos)])
	return worldMap

func setWorld(worldMap):
	for tilePos in $World.get_used_cells():
		$World.set_cellv(tilePos, -1)
	for block in worldMap:
		$World.set_cell(block[0][0], block[0][1], block[1])

func setBlock(pos, id, important=true, send=true):
	if pos.x >= borderMin.x and pos.x <= borderMax.x and pos.y >= borderMin.y and pos.y <= borderMax.y:
		pass
	else:
		return false
	if id == $World.get_cellv(pos):
		return false
	$World.set_cellv(pos, id)
	if id != 0 and id != 2:
		$WorldLighter.set_cellv(pos, id)
		$WorldDarker.set_cellv(pos, id)
	else:
		$WorldLighter.set_cellv(pos, -1)
		$WorldDarker.set_cellv(pos, -1)
	if important:
		updateNearbyBlocks()
		if send:
			if borderMin.x < 0:
				setBlockQueue.append([[abs(borderMin.x)+pos.x, pos.y], id])
			else:
				setBlockQueue.append([[pos.x, pos.y], id])
	return true

func animateBlocks(fromId, toId):
	var tiles = $World.get_used_cells_by_id(fromId+((frame-1)%(toId-fromId+1)))
	for tilePos in tiles:
		setBlock(tilePos, fromId+(frame%(toId-fromId+1)), false)

func _process(delta):
	
	Network.databaseData["inventory"] = hotbar
	Network.databaseData["inventoryAmount"] = hotbarAmount
	
	if Input.is_action_just_pressed("test"):
		generateWorld([0, 0, 200, 100, true])
	
	nearbyBlockTimer += delta
	if nearbyBlockTimer >= 0.25 or len(setBlockQueue) < 100:
		nearbyBlockTimer = 0
		for i2 in range(5):
			var send = []
			if len(setBlockQueue) >= 100:
				for i in range(100):
					send.append(setBlockQueue[0])
					setBlockQueue.pop_at(0)
				Network.sendMsg({"setBlock": send})
			else:
				if len(setBlockQueue) > 0:
					Network.sendMsg({"setBlock": setBlockQueue})
				setBlockQueue = []
		#loadWorldList(Vector2(0, 0), Vector2(10, 10), Global.decode(Global.encode(getWorldList(Vector2(0, 0), Vector2(10, 10)))))
		#loadWorldList(Vector2(0, 0), Vector2(10, 10), getWorldList(Vector2(0, 0), Vector2(10, 10)))
	var roundedPos = Vector2(round(Global.player.position.x/(1024*$Camera2D.zoom.x)), round(Global.player.position.y/(600*$Camera2D.zoom.y)))
	if roundedPos != lastPlayerPos:
		lastPlayerPos = roundedPos
		updateNearbyBlocks()
	
	updated = false
	
	if Input.is_action_just_pressed("godmode"):
		if godmode:
			godmode = false
		else:
			godmode = true
	Global.player.godmode = godmode
	
	for i in range(len(hotbarCooldown)):
		hotbarCooldown[i] -= 1
	
	var zoomSpeed = 0.01
	
	if Input.is_action_pressed("zoomIn"):
		$Camera2D.zoom -= Vector2(zoomSpeed, zoomSpeed)*$Camera2D.zoom
	
	if Input.is_action_pressed("zoomOut"):
		$Camera2D.zoom += Vector2(zoomSpeed, zoomSpeed)*$Camera2D.zoom
	
	var zoom = $Camera2D.zoom.x
	if zoom < 0.1:
		zoom = 0.1
	if not godmode:
		zoom = clamp(zoom, 0.1, 2.5)
	$Camera2D.zoom = Vector2(zoom, zoom)
	
	if Input.is_action_just_pressed("hotbar1"):
		selectedSlot = 1
	if Input.is_action_just_pressed("hotbar2"):
		selectedSlot = 2
	if Input.is_action_just_pressed("hotbar3"):
		selectedSlot = 3
	if Input.is_action_just_pressed("hotbar4"):
		selectedSlot = 4
	if Input.is_action_just_pressed("hotbar5"):
		selectedSlot = 5
	
	$Camera2D.position += (Global.player.position - $Camera2D.position) / 7.5
	
	frameTimer += delta
	if frameTimer > 0.1:
		frameTimer = 0
		frame += 1
		animateBlocks(21, 22) # Test
		animateBlocks(23, 28) # Rainbow
		animateBlocks(29, 36) # Water
		animateBlocks(37, 44) # Lava
	var mousePos = get_global_mouse_position()
	var mp = Vector2(round((mousePos.x+32)/64), round((mousePos.y+32)/64))
	$MouseSelect.position = Vector2(mp.x*64-32, mp.y*64-32)
	mp.x -= 1
	mp.y -= 1
	if not Input.is_action_pressed("leftClick"):
		lastPlaced = -2
	if Input.is_action_pressed("leftClick") and hotbar[selectedSlot-1] != $World.get_cellv(mp) and hotbar[selectedSlot-1] != 0 and (hotbar[selectedSlot-1] == lastPlaced or lastPlaced == -2):
		var oldBlock = $World.get_cellv(mp)
		var replaced = true
		var can = true
		
		if oldBlock == 5 and hotbar[selectedSlot-1] == 1:
			can = false
		if oldBlock == 1 and hotbar[selectedSlot-1] == 5:
			can = false
		
		if hotbarSlots[selectedSlot-1].amount > 0 and oldBlock != 12 and can:
			if oldBlock in hotbar:
				hotbarSlots[hotbar.find(oldBlock)].amount += 1
			elif -1 in hotbar:
				hotbarSlots[hotbar.find(-1)].item = oldBlock
				hotbarSlots[hotbar.find(-1)].amount = 1
			else:
				replaced = false
		else:
			replaced = false
		if oldBlock == -1:
			replaced = true
		if oldBlock == 12:
			replaced = false
		
#		if abs(mp.x) >= 35 or mp.y <= -20 or mp.y >= 12:
#			replaced = false
		
		if hotbarSlots[selectedSlot-1].amount > 0 and replaced:
			lastPlaced = hotbar[selectedSlot-1]
			if setBlock(mp, hotbar[selectedSlot-1]):
				if not godmode:
					hotbarSlots[selectedSlot-1].amount -= 1
				if hotbarSlots[selectedSlot-1].amount <= 0:
					hotbarSlots[selectedSlot-1].item = -1
	if Input.is_action_pressed("rightClick"):
		var oldBlock = $World.get_cellv(mp)
		if oldBlock != 12:
			if setBlock(mp, -1):
				var itemNew = item.instance()
				add_child(itemNew)
				itemNew.item = oldBlock
				itemNew.position = mp*64 + Vector2(32, 32)

func _ready():
	if Network.databaseData.has("inventory"):
		hotbar = Network.databaseData["inventory"]

	if Network.databaseData.has("inventoryAmount"):
		hotbarAmount = Network.databaseData["inventoryAmount"]
	
	$MeshInstance2D.scale = Vector2(99999999, 99999999)
	
	if Network.databaseData.has("pos"):
		Global.player = Network.instance_player(Network.id, Vector2(Network.databaseData["pos"][0], Network.databaseData["pos"][1]))
	else:
		Global.player = Network.instance_player(Network.id)
	$Camera2D.position = Global.player.position
	borderMax.x += 1
	borderMax.y += 1
	
	if loading:
		loadWorldList(borderMin, borderMax, Global.decode(Global.worldMap))
	
#	for tilePos in $World.get_used_cells():
#		setBlock(tilePos, -1)
	
	borderMax.x -= 1
	borderMax.y -= 1
	
	#generateWorld([0, 0, 200, 100, true])
	#generateWorld([-150, 0, 300, 100])
	#generateWorld([170, 0, 200, 100])
	updateNearbyBlocks()
	
	
	for tilePos in $WorldLighter.get_used_cells():
		$WorldLighter.set_cellv(tilePos, -1)
	
	for tilePos in $WorldDarker.get_used_cells():
		$WorldDarker.set_cellv(tilePos, -1)
	
	for tilePos in $World.get_used_cells():
		if $World.get_cellv(tilePos) != 2:
			$WorldLighter.set_cellv(tilePos, $World.get_cellv(tilePos))
			$WorldDarker.set_cellv(tilePos, $World.get_cellv(tilePos))
	
	$WorldLighter.visible = true
	$WorldDarker.visible = true

func _on_Back_pressed():
	for child in Players.get_children():
		child.queue_free()
	Network.sendMsg({"leavegame": Network.id})
	Global.changeScene("Menu")

func generateWorld(userdata):
	var posX = userdata[0]
	var posY = userdata[1]
	var width = userdata[2]
	var height = userdata[3]
	var clear = false
	var seed2 = randi()
	if len(userdata) >= 5:
		clear = userdata[4]
	if len(userdata) >= 6:
		seed2 = userdata[5]
	var noise = OpenSimplexNoise.new()
	noise.seed = seed2
	noise.octaves = 4
	noise.period = 300
	noise.persistence = 0.5
	
	Global.setupRandom(seed2+1923)
	
	var structures = []
	
	
	if clear:
		for x in width:
			for y in height:
				setBlock(Vector2(posX+x, posY+(height-y)), -1)
	var structureCooldown = 0
	for x in width:
		structureCooldown -= 1
		var y = 0
		var genY = round(clamp(abs(noise.get_noise_1d(x*10)*10) * height / 100 + height*0.75, height*0.35, height))
		for i in range(floor(genY/2)):
			setBlock(Vector2(posX+x, posY+(height-y)), 9)
			y += 1
		for i2 in range(ceil(genY/2)):
			setBlock(Vector2(posX+x, posY+(height-y)), 1)
			y += 1
		randomize()
		
		if structureCooldown <= 0:
			if Global.getRandom(0, 100, x) <= 3 and x < width-7:
				structures.append(["pond", posX+x, posY+(height-y)])
				structureCooldown = 7
			elif Global.getRandom(0, 100, x+25) <= 7 and x >= 2 and x < width-2:
				structures.append(["tree", posX+x, posY+(height-y)])
				structureCooldown = 2
			elif Global.getRandom(0, 100, x+50) <= 1 and x < width-10:
				structures.append(["house", posX+x, posY+(height-y)])
				structureCooldown = 10
		
		
#		for i in range(height-y):
#			if $World.get_cellv(Vector2(posX+x, posY+(height-y))) != "leaf":	
#				setBlock(Vector2(posX+x, posY+(height-y)), -1)
#			y += 1
			
	for structure in structures:
		var pos = Vector2(0, 0)
		if structure[0] == "house":
			pos = Vector2(structure[1], structure[2])
			setBlock(Vector2(pos.x, pos.y+1), 11)
			setBlock(Vector2(pos.x+1, pos.y+1), 6)
			setBlock(Vector2(pos.x+2, pos.y+1), 6)
			setBlock(Vector2(pos.x+3, pos.y+1), 6)
			setBlock(Vector2(pos.x+4, pos.y+1), 11)
			
			setBlock(Vector2(pos.x, pos.y-1), 11)
			setBlock(Vector2(pos.x+4, pos.y-1), 11)
			
			
			setBlock(Vector2(pos.x, pos.y-2), 11)
			#setBlock(Vector2(pos.x+3, pos.y-2), "light")
			setBlock(Vector2(pos.x+4, pos.y-2), 11)
			
			setBlock(Vector2(pos.x, pos.y-3), 11)
			setBlock(Vector2(pos.x+1, pos.y-3), 6)
			setBlock(Vector2(pos.x+2, pos.y-3), 6)
			setBlock(Vector2(pos.x+3, pos.y-3), 6)
			setBlock(Vector2(pos.x+4, pos.y-3), 11)
			
		
		if structure[0] == "tree":
			pos = Vector2(structure[1], structure[2])
			setBlock(Vector2(pos.x, pos.y), 11)
			setBlock(Vector2(pos.x, pos.y-1), 11)
			setBlock(Vector2(pos.x, pos.y-2), 11)
			
			setBlock(Vector2(pos.x-2, pos.y-3), 10)
			setBlock(Vector2(pos.x-1, pos.y-3), 10)
			setBlock(Vector2(pos.x, pos.y-3), 10)
			setBlock(Vector2(pos.x+1, pos.y-3), 10)
			setBlock(Vector2(pos.x+2, pos.y-3), 10)
			
			setBlock(Vector2(pos.x-1, pos.y-4), 10)
			setBlock(Vector2(pos.x, pos.y-4), 10)
			setBlock(Vector2(pos.x+1, pos.y-4), 10)
			
			setBlock(Vector2(pos.x, pos.y-5), 10)
		
		if structure[0] == "pond":
			pos = Vector2(structure[1], structure[2])
			setBlock(Vector2(pos.x, pos.y+1), 29)
			setBlock(Vector2(pos.x+1, pos.y+1), 29)
			setBlock(Vector2(pos.x+2, pos.y+1), 29)
			setBlock(Vector2(pos.x+3, pos.y+1), 29)
			setBlock(Vector2(pos.x+4, pos.y+1), 29)
			
			setBlock(Vector2(pos.x+1, pos.y+2), 29)
			setBlock(Vector2(pos.x+2, pos.y+2), 29)
			setBlock(Vector2(pos.x+3, pos.y+2), 29)
	
	#print(posX+width-3)
	#print(posY+height-1)
	#print(posX+2)
	#print(posY+height*0.65)
	for i in range(round(Global.getRandom(width/5, width/2, 5982))):
		var pos = Vector2(round(Global.getRandom(posX+2, posX+width-3, i)), round(Global.getRandom(posY+height*0.65, posY+height-1, i*100)))
		#print(pos)
		setBlock(pos, 3)
		var y = 0
		y += 1
		if Global.getRandom(0, 100, i+y) <= 50:
			setBlock(Vector2(pos.x+1, pos.y), 3)
		y += 1
		if Global.getRandom(0, 100, i+y) <= 50:
			setBlock(Vector2(pos.x-1, pos.y), 3)
		y += 1
		if Global.getRandom(0, 100, i+y) <= 50:
			setBlock(Vector2(pos.x, pos.y+1), 3)
		y += 1
		if Global.getRandom(0, 100, i+y) <= 50:
			setBlock(Vector2(pos.x, pos.y-1), 3)

		y += 1
		if Global.getRandom(0, 100, i+y) <= 25:
			setBlock(Vector2(pos.x+2, pos.y), 3)
		y += 1
		if Global.getRandom(0, 100, i+y) <= 25:
			setBlock(Vector2(pos.x-2, pos.y), 3)
		y += 1
		if Global.getRandom(0, 100, i+y) <= 25:
			setBlock(Vector2(pos.x, pos.y+2), 3)
		y += 1
		if Global.getRandom(0, 100, i+y) <= 25:
			setBlock(Vector2(pos.x, pos.y-2), 3)

		y += 1
		if Global.getRandom(0, 100, i+y) <= 25:
			setBlock(Vector2(pos.x+1, pos.y+1), 3)
		y += 1
		if Global.getRandom(0, 100, i+y) <= 25:
			setBlock(Vector2(pos.x-1, pos.y-1), 3)
		y += 1
		if Global.getRandom(0, 100, i+y) <= 25:
			setBlock(Vector2(pos.x+1, pos.y-1), 3)
		y += 1
		if Global.getRandom(0, 100, i+y) <= 25:
			setBlock(Vector2(pos.x-1, pos.y+1), 3)
