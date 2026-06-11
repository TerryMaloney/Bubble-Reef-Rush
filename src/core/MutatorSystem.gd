# Autoload that tracks active mutators for the current run and applies them
# at level load. Effects are implemented incrementally starting in Phase 19.
extends Node

## Active mutator IDs for this run. Set by GameManager before scene change.
var active_mutators: Array[String] = []

## Apply active mutators to level components.
## Called from LevelRoot._ready() after all child nodes are initialized.
## player: PlayerController node, scroll: ScrollService autoload, root: LevelRoot node.
func apply(_player: Node, _scroll: Node, _root: Node) -> void:
	pass  # Phase 19 implements each mutator effect


## Check whether a specific mutator is currently active.
func is_active(mutator_id: String) -> bool:
	return mutator_id in active_mutators


## Clear active mutators (called by GameManager when returning to menu).
func clear() -> void:
	if not active_mutators.is_empty():
		active_mutators.clear()
		EventBus.mutators_changed.emit([])
