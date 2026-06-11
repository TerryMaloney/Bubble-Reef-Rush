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
