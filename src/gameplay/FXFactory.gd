## FXFactory autoload — pooled CPUParticles2D one-shots for hit/collect effects.
## Gated by Accessibility.reduced_motion() (50% emission when reduced).
extends Node

const POOL_SIZE: int = 8

var _pool: Array[CPUParticles2D] = []


func _ready() -> void:
	for _i: int in range(POOL_SIZE):
		var p: CPUParticles2D = _make_particle()
		_pool.append(p)
		add_child(p)


## Trigger a burst at canvas position `pos` with optional `color`.
## Safe to call when no level is active — effects appear on whatever scene is current.
func burst(pos: Vector2, color: Color = Color.WHITE) -> void:
	var p: CPUParticles2D = _acquire()
	if p == null:
		return
	p.global_position = pos
	p.color = color
	var emission_count: int = 12 if not Accessibility.reduced_motion() else 6
	p.amount = emission_count
	p.emitting = true


func _acquire() -> CPUParticles2D:
	for p: CPUParticles2D in _pool:
		if not p.emitting:
			return p
	return null


func _make_particle() -> CPUParticles2D:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = 12
	p.lifetime = 0.4
	p.explosiveness = 0.9
	p.spread = 180.0
	p.gravity = Vector2(0.0, 200.0)
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 200.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	return p
