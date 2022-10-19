extends Control

var timer = 0

func _ready():
	if Network.auto:
		$Label2.text = "Reconnecting"

