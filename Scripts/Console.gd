extends CanvasLayer

var focus = false
var lines = []
var updated = 0
var targetAlpha = 0
var targetAlpha2 = 0
var lastUsername = ""

func log2(value):
	if updated < 1:
		updated = 1
	updated += len(value) / 7.5
	lines.append(value)
	if len(lines) > 5:
		lines.pop_front()

func _process(delta):
	if Global.ready:
		if lastUsername != Network.databaseData["username"]:
			lastUsername = Network.databaseData["username"]
			$VBoxContainer/LineEdit.max_length = 37-len(Network.databaseData["username"])
	
	var controls = ""
	if Global.sceneName == "Game":
		if not focus:
			controls += " (T) Open Chat"
		else:
			controls += " (ESC) Close Chat"
		
		controls += " (1-0) Hotbar"
	$Controls/Label.text = controls
	
	if not focus:
		updated -= delta
	
	
	
	if focus or updated > 0:
		targetAlpha = 0.75
		targetAlpha2 = 0.75
	else:
		targetAlpha = 0
		targetAlpha2 = 0
	
	if focus:
		if Input.is_action_just_pressed("send") and Global.ready:
			log2("[" + Network.databaseData["username"] + "] " + $VBoxContainer/LineEdit.text)
			Network.sendMsg({"broadcast": ["send", "[" + Network.databaseData["username"] + "] " + $VBoxContainer/LineEdit.text]})
			$VBoxContainer/LineEdit.text = ""
			focus = false
	else:
		$VBoxContainer/LineEdit.text = ""
	
	if Global.sceneName == "Game":
		if Input.is_action_just_pressed("chat"):
			focus = true
			$VBoxContainer/LineEdit.grab_focus()
		
		if Input.is_action_just_pressed("ui_cancel"):
			focus = false
	else:
		focus = false
	
	var text = ""
	for line in lines:
		text += "\n" + line
	$VBoxContainer/Label.text = text
	
	$VBoxContainer/Label.modulate.a += (targetAlpha2 - $VBoxContainer/Label.modulate.a)/5
	if focus:
		$VBoxContainer/LineEdit.modulate.a += (targetAlpha - $VBoxContainer/LineEdit.modulate.a)/5
	else:
		$VBoxContainer/LineEdit.modulate.a += (0 - $VBoxContainer/LineEdit.modulate.a)/5
