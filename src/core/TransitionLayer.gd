## TransitionLayer autoload — 0.25s screen fade for all scene changes.
## Usage: TransitionLayer.go_to(scene_path) instead of get_tree().change_scene_to_file().
extends CanvasLayer

const FADE_DURATION: float = 0.25

var _overlay: ColorRect = null
var _tween: Tween = null


func _ready() -> void:
	layer = 128  # on top of everything
	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.color.a = 0.0
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)


## Fade to black, change scene, then fade from black.
func go_to(scene_path: String) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_overlay, "color:a", 1.0, FADE_DURATION)
	_tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file(scene_path)
	)
	_tween.tween_property(_overlay, "color:a", 0.0, FADE_DURATION)
