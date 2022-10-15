extends Control

onready var username = $VBoxContainer/Username
onready var playerDisplay = $Sprite

func _ready():
	$VBoxContainer/id.text = Global.id
	username.text = Network.databaseData["username"]

func _process(delta):
	Network.databaseData["username"] = username.text
	playerDisplay.frame = Network.databaseData["player"]

func _on_Change_pressed():
	Network.databaseData["player"] += 1
	if Network.databaseData["player"] >= 4:
		Network.databaseData["player"] = 0
