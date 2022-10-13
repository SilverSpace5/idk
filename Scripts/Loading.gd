extends Control

func _ready():
	Global.worldMap = yield(Network.getDatabaseData("world"), "completed")
	Global.changeScene("Game")
