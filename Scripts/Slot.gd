extends Area2D

export (bool) var isHotbar = false
export (int) var item = 0
export (int) var amount = 1

func _process(delta):
	for i in range(5):
		if item == i+24:
			item = 23
	for i in range(7):
		if item == i+30:
			item = 29
	for i in range(7):
		if item == i+38:
			item = 37
	if item < 0:
		$Item.visible = false
		$CanvasLayer/Amount.visible = false
	else:
		$Item.visible = true
		$CanvasLayer/Amount.visible = true
		$Item.set_cell(-1, -1, item)
	
	$CanvasLayer.offset = position
	$CanvasLayer.scale = scale
	if amount != 1:
		$CanvasLayer/Amount.text = str(amount)
	else:
		$CanvasLayer/Amount.text = ""
	
	if isHotbar:
		Global.scene.hotbar[int(name[4])-1] = item
		Global.scene.hotbarSlots[int(name[4])-1] = self
		if int(name[4]) == Global.scene.selectedSlot:
			scale = Vector2(4.4, 4.4)
			modulate = Color(1, 1, 1)
		else:
			scale = Vector2(4, 4)
			modulate = Color(0.85, 0.85, 0.85)
