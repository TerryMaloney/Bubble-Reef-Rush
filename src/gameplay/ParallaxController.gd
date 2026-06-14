## ParallaxController — drop-in scrolling parallax background.
##
## Looks for art at  res://assets/backgrounds/z<zone>_bg_l<0..5>.png  and, for
## each layer that exists, builds a horizontally-tiled, infinitely-scrolling
## band. Layers scroll at depth-based speeds (l0 nearest/fastest … l5
## farthest/slowest) driven by the gameplay scroll speed.
##
## If NO art is present for a zone it stays inactive and the flat ZONE_COLORS
## gradient shows instead — so shipping this with no art changes nothing visible.
##
## Drop in PNGs named per the art bible and they appear automatically:
##   z1_bg_l0_seabed.png → save as  z1_bg_l0.png   (and l1..l5)
extends CanvasLayer

class_name ParallaxController

const DIR: String = "res://assets/backgrounds/"
const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0

# Depth-based scroll speed per layer index (l0 nearest … l5 farthest overlay).
const SPEEDS: Dictionary = {0: 1.20, 1: 1.00, 2: 0.60, 3: 0.30, 4: 0.15, 5: 0.05}

var active: bool = false

var _layers: Array = []   # [{holder: Node2D, speed: float, tile_w: float}]
var _offset: float = 0.0


func _ready() -> void:
	layer = -5  # behind gameplay (layer 0), above nothing else


## Build layers for a zone. Returns true if any art was found (→ active).
func build(zone: int) -> bool:
	for c: Node in get_children():
		c.queue_free()
	_layers.clear()
	_offset = 0.0
	active = false

	# Add back-to-front so nearer layers (l0) draw on top.
	for n: int in [5, 4, 3, 2, 1, 0]:
		var path: String = DIR + "z%d_bg_l%d.png" % [zone, n]
		if not ResourceLoader.exists(path):
			continue
		var tex: Texture2D = load(path) as Texture2D
		if tex == null or tex.get_height() <= 0:
			continue
		var sc: float = SCREEN_H / float(tex.get_height())
		var tile_w: float = float(tex.get_width()) * sc
		if tile_w < 1.0:
			continue
		var count: int = int(ceil(SCREEN_W / tile_w)) + 2
		var holder: Node2D = Node2D.new()
		add_child(holder)
		for i: int in range(count):
			var sp: Sprite2D = Sprite2D.new()
			sp.texture = tex
			sp.centered = false
			sp.scale = Vector2(sc, sc)
			sp.position = Vector2(float(i) * tile_w, 0.0)
			holder.add_child(sp)
		_layers.append({"holder": holder, "speed": float(SPEEDS[n]), "tile_w": tile_w})

	active = not _layers.is_empty()
	return active


func _process(delta: float) -> void:
	if not active:
		return
	_offset += ScrollService.speed_now() * delta
	for layer_data: Dictionary in _layers:
		var w: float = float(layer_data["tile_w"])
		var holder: Node2D = layer_data["holder"] as Node2D
		holder.position.x = -fmod(_offset * float(layer_data["speed"]), w)
