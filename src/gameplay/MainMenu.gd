extends Control

class_name MainMenu


func _ready() -> void:
	$Layout/JourneyButton.pressed.connect(_on_journey_pressed)
	$Layout/CreateButton.pressed.connect(_on_create_pressed)
	$Layout/ReefRivalsButton.pressed.connect(_on_reef_rivals_pressed)
	$Layout/PartyButton.pressed.connect(_on_party_pressed)
	$Layout/RadioShuffleButton.pressed.connect(_on_radio_shuffle_pressed)
	$Layout/CollectionRoomButton.pressed.connect(_on_collection_room_pressed)
	$SettingsButton.pressed.connect(_on_settings_pressed)
	_animate_in()


func _animate_in() -> void:
	var title: Label = $Layout/Title
	title.pivot_offset = title.size * 0.5
	title.scale = Vector2(0.8, 0.8)
	title.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(title, "scale", Vector2.ONE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(title, "modulate:a", 1.0, 0.25)
	var buttons: Array[Node] = $Layout.get_children().filter(func(n: Node) -> bool: return n is Button)
	for i: int in range(buttons.size()):
		var btn: Button = buttons[i] as Button
		btn.modulate.a = 0.0
		tween.tween_property(btn, "modulate:a", 1.0, 0.15).set_delay(0.04 * i)


func _on_journey_pressed() -> void:
	GameManager.go_to_zone_select()


func _on_create_pressed() -> void:
	GameManager.open_build_mode()


func _on_reef_rivals_pressed() -> void:
	var screen: Control = load("res://scenes/ui/ReefRivalsScreen.tscn").instantiate() as Control
	add_child(screen)


func _on_party_pressed() -> void:
	var screen: Control = load("res://scenes/ui/PartyHubScreen.tscn").instantiate() as Control
	add_child(screen)


func _on_radio_shuffle_pressed() -> void:
	var screen: Control = load("res://scenes/ui/RadioShuffleScreen.tscn").instantiate() as Control
	add_child(screen)


func _on_collection_room_pressed() -> void:
	var screen: Control = load("res://scenes/ui/CollectionRoomScreen.tscn").instantiate() as Control
	add_child(screen)


func _on_settings_pressed() -> void:
	GameManager.go_to_settings(GameManager.MAIN_MENU_SCENE)
