extends RefCounted

# Godot's mixer consumes stop commands asynchronously. Keep resource-leak checks
# enabled and allow pending playback references to drain before SceneTree.quit.
static func drain(tree: SceneTree) -> void:
 tree.root.get_node("Soundscape").stop_all()
 await tree.create_timer(0.25).timeout
