extends Node2D

var frame = 0
var frameTimer = 0
var nearbyBlockTimer = 99
var selectedSlot = 0
var lastPlaced = -2
var hotbar = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1]
var hotbarAmount = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var hotbarSlots = [null, null, null, null, null, null, null, null, null, null]
var hotbarCooldown = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var item = load("res://Item.tscn")
var godmode = false
var updated = false
var setBlockQueue = []
var nearbyBlocks = []
var nearbyBlockIds = []
var lastPlayerPos = Vector2(999, 999)
var editCooldown = 0
var blockCooldowns = {}
var protected = [
	[150, 0, 170, 100]
]
var waterAlpha = 0
var lavaAlpha = 0
var playersAlpha = 0

export var saving = true
export var loading = true
export var borderMin = Vector2(0, 0)
export var borderMax = Vector2(0, 0)

var connections = [
	[29, 30, 31, 32, 33, 34, 35, 36],
	[37, 38, 39, 40, 41, 42, 43, 44],
	[21, 22],
	[23, 24, 25, 26, 27, 28]
]
#var lava = [29, 30, 31, 32, 33, 34, 35, 36]

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

func flowBlocks(fromId, toId, dis):
	var flowIds = []
	var tiles = []
	var changes = []
	for i in range(toId-fromId+1):
		flowIds.append(fromId+i)
		tiles.append_array(getBlocks(fromId+i))
		
	for tilePos in tiles:
		var moved = false
		if $World.get_cell(tilePos.x, tilePos.y+1) == -1 and not moved:
			changes.append([tilePos, -1])
			changes.append([Vector2(tilePos.x, tilePos.y+1), fromId])
			moved = true
#			setBlock(tilePos, -1, false, true)
#			setBlock(Vector2(tilePos.x, tilePos.y+1), 29, false, true)
		
		var downPosX = 1
		var downNegX = 1
		var posX = 1
		var negX = 1
		while ($World.get_cellv(Vector2(tilePos.x + posX, tilePos.y)) == -1 or $World.get_cellv(Vector2(tilePos.x + posX, tilePos.y)) in flowIds) and posX < dis:
			posX += 1
		while ($World.get_cellv(Vector2(tilePos.x - negX, tilePos.y)) == -1 or $World.get_cellv(Vector2(tilePos.x - negX, tilePos.y)) in flowIds) and negX < dis:
			negX += 1
		while $World.get_cellv(Vector2(tilePos.x + downPosX, tilePos.y + 1)) != -1 and not $World.get_cellv(Vector2(tilePos.x + downPosX, tilePos.y + 1)) in flowIds and downPosX < dis:
			downPosX += 1
		while $World.get_cellv(Vector2(tilePos.x - downNegX, tilePos.y + 1)) != -1 and not $World.get_cellv(Vector2(tilePos.x - downNegX, tilePos.y + 1)) in flowIds and downNegX < dis:
			downNegX += 1
		
		if downPosX < downNegX and $World.get_cellv(Vector2(tilePos.x + 1, tilePos.y)) == -1 and not moved:
			if not $World.get_cellv(Vector2(tilePos.x + 2, tilePos.y)) in flowIds:
				changes.append([tilePos, -1])
				changes.append([Vector2(tilePos.x + 1, tilePos.y), fromId])
				moved = true
		
		if downNegX < downPosX and $World.get_cellv(Vector2(tilePos.x - 1, tilePos.y)) == -1 and not moved:
			if not $World.get_cellv(Vector2(tilePos.x - 2, tilePos.y)) in flowIds:
				changes.append([tilePos, -1])
				changes.append([Vector2(tilePos.x - 1, tilePos.y), fromId])
				moved = true
	
	if len(changes) > 0:
		for change in changes:
			setBlock(change[0], change[1], false, true)
		updateNearbyBlocks()

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
	nearbyBlockIds = []
	for tilePos in $World.get_used_cells():
		if abs(playerPos.x - tilePos.x*64) < screenWidth and abs(playerPos.y - tilePos.y*64) < screenHeight:
			nearbyBlocks.append(tilePos)
			nearbyBlockIds.append($World.get_cellv(tilePos))
	worldUpdated()

func getBlocks(id):
	var foundBlocks = []
	var i = 0
	for tilePos in nearbyBlocks:
		if nearbyBlockIds[i] == id:
			foundBlocks.append(tilePos)
		i += 1
	return foundBlocks

func worldUpdated():
	var screenWidth = 1024*$Camera2D.zoom.x
	var screenHeight = 600*$Camera2D.zoom.y
	var playerPos = Global.player.position
	for tilePos in getBlocks(1):
		if abs(playerPos.x - tilePos.x*64) < screenWidth and abs(playerPos.y - tilePos.y*64) < screenHeight:
			if $World.get_cell(tilePos.x, tilePos.y - 1) == -1:
				setBlock(tilePos, 5, true, true)
	for tilePos in getBlocks(5):
		if abs(playerPos.x - tilePos.x*64) < screenWidth and abs(playerPos.y - tilePos.y*64) < screenHeight:
			if $World.get_cell(tilePos.x, tilePos.y - 1) != -1:
				setBlock(tilePos, 1, true, true)

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
	var tiles = []
	for i in range(toId-fromId+1):
		tiles.append_array(getBlocks(fromId+i))
	#var tiles = $World.get_used_cells_by_id(fromId+((frame-1)%(toId-fromId+1)))
	for tilePos in tiles:
		setBlock(tilePos, fromId+(frame%(toId-fromId+1)), false, false)

func _process(delta):
	
	Network.databaseData["hotbar"] = hotbar
	Network.databaseData["hotbarAmount"] = hotbarAmount
	
	if Global.player.currentBlock in connections[0]:
		waterAlpha = 0.35
	else:
		waterAlpha = 0
	if Global.player.currentBlock in connections[1]:
		lavaAlpha = 0.35
	else:
		lavaAlpha = 0
		
	$CanvasLayer/Players.modulate.a += (playersAlpha - $CanvasLayer/Players.modulate.a)/5
	$CanvasLayer/PlayerBG.modulate.a += (playersAlpha - $CanvasLayer/PlayerBG.modulate.a)/5
	
	$CanvasLayer/Water.color.a += (waterAlpha - $CanvasLayer/Water.color.a)/10
	$CanvasLayer/Lava.color.a += (lavaAlpha - $CanvasLayer/Lava.color.a)/10
	
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
	
	if Input.is_action_just_pressed("godmode") and Network.admin:
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
		zoom = clamp(zoom, 0.1, 2.25)
	$Camera2D.zoom = Vector2(zoom, zoom)
	$Camera2D/Offset.scale.x = zoom*0.8
	$Camera2D/Offset.scale.y = zoom*0.8
	
	for i in range(10):
		if Input.is_action_just_pressed("hotbar" + str(i)):
			selectedSlot = i
	
	$Camera2D.position += (Global.player.position - $Camera2D.position) / 7.5
	
	frameTimer += delta
	if frameTimer > 0.1:
		frameTimer = 0
		frame += 1
		
		flowBlocks(29, 36, 5) # Water
		
		animateBlocks(21, 22) # Test
		animateBlocks(23, 28) # Rainbow
		animateBlocks(29, 36) # Water
		animateBlocks(37, 44) # Lava
	
	for blockCooldown in blockCooldowns:
		blockCooldowns[blockCooldown] -= delta
		if blockCooldowns[blockCooldown] <= 0:
			blockCooldowns.erase(blockCooldown)
	
	var mousePos = get_global_mouse_position()
	var mp = Vector2(round((mousePos.x+32)/64), round((mousePos.y+32)/64))
	$MouseSelect.position = Vector2(mp.x*64-32, mp.y*64-32)
	mp.x -= 1
	mp.y -= 1
	
	var blocked = false
	
	for area in protected:
		if mp.x >= area[0] and mp.x < area[2] and mp.y >= area[1] and mp.y < area[3]:
			blocked = true
	
	if godmode:
		blocked = false
	
	var inRange = godmode or (mp*64).distance_to(Global.player.position) <= 256
	var far = godmode or (mp*64).distance_to(Global.player.position) >= 64
	
	if not Input.is_action_pressed("leftClick"):
		lastPlaced = -2
	if Input.is_action_pressed("leftClick") and hotbar[selectedSlot] != $World.get_cellv(mp) and hotbar[selectedSlot] != -1 and (hotbar[selectedSlot] == lastPlaced or lastPlaced == -2) and not blocked and inRange and far:
		var oldBlock = $World.get_cellv(mp)
		var replaced = true
		var can = true
		
		for connection in connections:
			if oldBlock in connection:
				oldBlock = connection[0]
		
		if oldBlock == 5 and hotbar[selectedSlot] == 1:
			can = false
		if oldBlock == 1 and hotbar[selectedSlot] == 5:
			can = false
		
		if hotbarSlots[selectedSlot].amount > 0 and oldBlock != 12 and can:
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
		
		
		if hotbarSlots[selectedSlot].amount > 0 and replaced:
			lastPlaced = hotbar[selectedSlot]
			if setBlock(mp, hotbar[selectedSlot]):
				if not godmode:
					hotbarSlots[selectedSlot].amount -= 1
				if hotbarSlots[selectedSlot].amount <= 0:
					hotbarSlots[selectedSlot].item = -1
	if Input.is_action_pressed("rightClick") and not blockCooldowns.has(mp) and not blocked and inRange:
		var oldBlock = $World.get_cellv(mp)
		for connection in connections:
			if oldBlock in connection:
				oldBlock = connection[0]
		if oldBlock != 12:
			if setBlock(mp, -1):
				blockCooldowns[mp] = 0.25
				var itemId = Global.getId(10)
				Network.sendMsg({"broadcast": ["breakBlock", {"mpX": mp.x, "mpY": mp.y, "oldBlock": oldBlock, "id": itemId}]})
				var itemNew = item.instance()
				add_child(itemNew)
				itemNew.item = oldBlock
				itemNew.id = itemId
				itemNew.position = mp*64 + Vector2(32, 32)

func _ready():
	hotbar = Network.databaseData["hotbar"]
	hotbarAmount = Network.databaseData["hotbarAmount"]
	
	for i in range(len(hotbar)):
		hotbar[i] = int(hotbar[i])
	for i in range(len(hotbarAmount)):
		hotbarAmount[i] = int(hotbarAmount[i])
	
	var databaseHotbarLen = len(Global.defaultDatabase["hotbar"])
	var databaseHotbarAmountLen = len(Global.defaultDatabase["hotbarAmount"])

	while len(hotbar) < databaseHotbarLen:
		hotbar.append(-1)
	while len(hotbar) > databaseHotbarLen:
		hotbar.pop_front()
	while len(hotbarAmount) < databaseHotbarAmountLen:
		hotbarAmount.append(0)
	while len(hotbarAmount) > databaseHotbarAmountLen:
		hotbarAmount.pop_front()
	
	#$MeshInstance2D.scale = Vector2(99999999, 99999999)
	
	$CanvasLayer/Players.add_item(Network.databaseData["username"], null, false)
	
	Global.player = Network.instance_player(Network.id, Vector2(Network.databaseData["pos"][0], Network.databaseData["pos"][1]))
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


func _on_PlayersButton_pressed():
	if playersAlpha == 0:
		playersAlpha = 1
	else:
		playersAlpha = 0
