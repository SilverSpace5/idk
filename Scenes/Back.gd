extends Button

func _on_Back_pressed():
	for child in Players.get_children():
		child.queue_free()
	if Global.sceneName == "Game":
		Network.sendMsg({"leavegame": Network.id})
	Global.changeScene("Menu")
