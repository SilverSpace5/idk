extends Control

func _ready():
	Global.worldMap = yield(Network.getDatabaseData("world"), "completed")
	Network.sendMsg({"joingame": Network.id})
	Global.changeScene("Game")
