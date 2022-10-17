extends KinematicBody2D

export var speed = 0
export var jumpSpeed = 0
export var gravity = 0

var velocity = Vector2(0, 0)
var frames = 99
var jump = 0
var data = {}
var hold = false
var onFloor = false
var godmode = false
var currentBlock = -1

onready var tween = $Tween

func _ready():
	pass
#	if Network.databaseData.has("pos"):
#		yield(get_tree().create_timer(0.1), "timeout")
#		position = Vector2(Network.databaseData["pos"][0], Network.databaseData["pos"][1])
		#Global.scene.get_node("Camera2D").position = position

func _process(delta):
	if Global.sceneName != "Game":
		return
	var scalex = abs(velocity.x)/3000+1
	var scaley = abs(velocity.y)/2500+1
	
	scalex = clamp(scalex, 1, 1.35)
	scaley = clamp(scaley, 1, 1.35)
	
	var scalex2 = scalex
	var scaley2 = scaley
	
	scalex /= scaley2
	scaley /= scalex2
	
	$Players.scale.x += (scalex - $Players.scale.x)/5
	$Players.scale.y += (scaley - $Players.scale.y)/5
	$Players.position.y = $Players.scale.y*2-1
	
	currentBlock = Global.scene.get_node("World").get_cell(round(position.x/64-0.5), round(position.y/64-0.5))
	for connection in Global.scene.connections:
		if currentBlock in connection:
			currentBlock = connection[0]
	
	if Network.playerData.has(name):
		data = Network.playerData[name]
	
	if name == Network.id:
		$Username.text = Network.databaseData["username"]
		$Players.frame = Network.databaseData["player"]
		var x_input = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
		var y_input = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
		
		if not godmode:
			if currentBlock == 29:
				velocity.y += gravity/3
			else:
				velocity.y += gravity
		
		$Area2D.update()
			
		if not Input.is_action_pressed("jump"):
			hold = false
		
		if onFloor:
			frames = 0
		else:
			frames += 1
		
		if is_on_floor():
			velocity.y = 0
			hold = true
			jump = 0
		if currentBlock == 29:
			jump = 0
			hold = true
		if is_on_ceiling():
			velocity.y = gravity
		if not Console.focus and (Input.is_action_just_pressed("jump") or (Input.is_action_pressed("jump") and jump > 0)) and (frames <= 3 or (jump <= 5 and hold)):
			var jump2 = jumpSpeed + (jumpSpeed*0.1*jump)
			velocity.y = -jump2
			jump += 1
		
		if godmode:
			collision_layer = 4
			collision_mask = 4
			speed *= 2
		else:
			collision_layer = 1
			collision_mask = 1
		
		if is_on_floor():
			velocity.x *= 0.33
		else:
			velocity.x *= 0.8
			speed /= 3
		if godmode:
			velocity.y *= 0.8
		
		if not Console.focus:
			velocity.x += x_input * speed
			if godmode:
				velocity.y += y_input * speed
		if not is_on_floor():
			speed *= 3
		
		if godmode:
			speed /= 2
		
		move_and_slide(velocity, Vector2.UP)
		
		Network.databaseData["pos"] = [position.x, position.y]
		
		
		if position.y >= 250*64:
			position = Vector2(0, 0)
			velocity = Vector2(0, 0)
	else:
		
		if not data.has("position"):
			return
		
		$Username.text = data["username"]
		$Players.frame = data["player"]
		
		var pos = Global.getVector(data["position"])
		velocity = Global.getVector(data["velocity"])
		
		if pos != position:
			tween.interpolate_property(self, "global_position", global_position, pos, 0.1)
			tween.start()
		if not tween.is_active():
			move_and_slide(velocity)

func _on_tick_rate_timeout():
	if name == Network.id:
		Network.data["position"] = global_position
		Network.data["velocity"] = velocity
		Network.data["username"] = $Username.text
		Network.data["player"] = $Players.frame
