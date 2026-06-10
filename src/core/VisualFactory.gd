## VisualFactory.gd
## Builds a visual node for an in-game entity.
##
## Usage in each entity's _ready():
##   var vis: Node2D = VisualFactory.build_visual("sprite/obstacle/coral_spike", _build_placeholder)
##   add_child(vis)
##
## If a real texture exists in the manifest, returns a Sprite2D with that texture.
## Otherwise calls the placeholder Callable which should return a Polygon2D (or any Node2D).
## Dropping in a PNG + manifest entry swaps the visual with zero code changes.
extends Node


## Returns a Node2D that visually represents the entity.
## key: logical asset key in asset_manifest.json (e.g. "sprite/obstacle/coral_spike").
## placeholder: Callable that takes no arguments and returns a Node2D (the Polygon2D code).
func build_visual(key: String, placeholder: Callable) -> Node2D:
	var texture: Texture2D = AssetRegistry.get_texture(key)
	if texture != null:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = texture
		return sprite
	return placeholder.call() as Node2D
