extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 root.size=Vector2i(960,540)
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_game()
 for definition: Dictionary in RelicCatalog.DATA: RelicCatalog.icon(definition.id)
 for enemy in game.enemies: enemy.set_physics_process(false)
 for i in range(20): await process_frame
 print("VISUAL_RESOURCE_PROBE ",JSON.stringify({"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}))
 game.queue_free()
 await process_frame
 quit()
