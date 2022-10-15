extends Control

func _ready():
	if Network.auto:
		$Label2.text = "Reconnecting"
