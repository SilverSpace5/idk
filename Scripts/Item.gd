extends RigidBody2D

var item = 0
var pickingUp = false
var found = 0
var colliding = false
var cooldown = 0
var id = ""
var despawnTimer = 0
var nearestPlayer

func _ready():
	if id in Network.deletedItems:
		Network.deletedItems.remove(id)

func _process(delta):
	despawnTimer += delta
	if despawnTimer >= 10:
		queue_free()
		return
	if id in Network.deletedItems:
		queue_free()
	
	cooldown -= delta
	
	for i in range(5):
		if item == i+24:
			item = 23
	for i in range(7):
		if item == i+30:
			item = 29
	for i in range(7):
		if item == i+38:
			item = 37
	
	if item == -1:
		queue_free()
		return
	if position.y >= 10000:
		position = Vector2(0, 0)
		linear_velocity = Vector2(0, 0)
		angular_velocity = 0
	visible = true
		
	$Sprite.set_cell(-1, -1, item)
	if pickingUp and Global.scene.hotbarCooldown[Global.scene.hotbar.find(item)] <= 0 and cooldown <= 0:
		Global.scene.hotbarCooldown[Global.scene.hotbar.find(item)] = 0.1
		var hotbarSlots = Global.scene.hotbarSlots
		var hotbar = Global.scene.hotbar
		if item in hotbar:
			hotbarSlots[hotbar.find(item)].amount += 1
			Network.sendMsg({"pickupItem": [id, item]})
			queue_free()
		elif -1 in hotbar:
			hotbarSlots[hotbar.find(-1)].item = item
			hotbarSlots[hotbar.find(-1)].amount = 1
			queue_free()
	
	found -= delta
	
	nearestPlayer = Global.player
	var shortestDistance = position.distance_to(Global.player.position)
	for player in Players.get_children():
		if position.distance_to(player.position) < shortestDistance:
			nearestPlayer = player
	
	if position.distance_to(nearestPlayer.position) < 300:
		found = 1
		if position.distance_to(nearestPlayer.position) < 200:
			collision_layer = 4
			collision_mask = 4
		else:
			collision_layer = 1
			collision_mask = 1
		apply_impulse(Vector2(0, 0), (nearestPlayer.position - position)/5)
	elif found < 0:
		collision_layer = 1
		collision_mask = 1
	if position.distance_to(nearestPlayer.position) < 50:
		pickingUp = true
#		collision_layer = 4
#		collision_mask = 4

func _on_Item_body_entered(body):
	if body.name == Network.id:
		pickingUp = true
#	elif nearestPlayer:
#		if body.name == nearestPlayer.name:
#			queue_free()
		
func _on_Item_body_exited(body):
	if body.name == Network.id:
		pickingUp = false
