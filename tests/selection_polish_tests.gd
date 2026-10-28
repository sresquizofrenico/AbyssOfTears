extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func run() -> void:
 var progress=root.get_node("Progress")
 progress.storage_path="user://selection-polish-progress.json"
 progress.data=progress.fresh()
 progress.redeem("ABISMO-TOTAL")
 check(not GuestRoster.enabled() and GuestRoster.entries().is_empty(),"Public build never enables private characters or assets")
 for direction in ["front","left","right"]:
  var texture:=ShaderArt.direction_texture(direction)
  var image:=texture.get_image()
  var whites:=0
  for y in range(148,190):
   for x in range(110,270):
    var pixel:=image.get_pixel(x,y)
    if pixel.r>0.9 and pixel.g>0.85 and pixel.b>0.8 and pixel.a>0.8: whites+=1
  check(whites>250,"Shader has readable eye whites in "+direction)
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.show_character_selection()
 var selection: CharacterSelection=game.panel
 for i in range(CharacterCatalog.DATA.size()):
  selection.index=i
  selection.refresh()
  for sample in range(50):
   selection._process(0.16)
   check(selection.character.look.y>0.98,"Selection keeps face visible without abrupt profile switching")
   check(is_equal_approx(selection.character.scale.x,selection.character.scale.y),"Preview is never stretched nonuniformly")
 var character:=selection.character
 character.pose_weight=0
 character.pose="present"
 character.update_pose(0.01)
 check(character.pose_weight>0 and character.pose_weight<0.2,"Arm pose eases in instead of snapping")
 character.update_pose(1)
 check(character.pose_weight>0.99,"Presentation settles smoothly")
 character.pose="rest"
 character.update_pose(0.01)
 check(character.pose_weight>0.8,"Arm pose eases back instead of snapping")
 var initial: int=selection.index
 for i in range(40): selection.select_offset(1)
 check(selection.index==initial,"Repeated navigation wraps without stale tweens")
 var old:=RunSnapshot.capture(game) if is_instance_valid(game.player) else {}
 game.start_dungeon(25)
 game.set_world_active(false)
 game.set_physics_process(false)
 var checkpoint:=RunSnapshot.capture(game)
 for key in checkpoint.ability.character_state.keys():
  if str(key).begins_with("guest_"): checkpoint.ability.character_state.erase(key)
 check(RunSnapshot.valid(checkpoint),"0.13 checkpoints without optional guest fields still validate")
 game.player.restore_ability(checkpoint.ability)
 check(game.player.character_state.has("guest_reserve"),"Optional state migrated with defaults without losing old abilities")
 game.queue_free()
 await process_frame
 root.get_node("RunSave").flush()
 await preload("res://tests/audio_test_cleanup.gd").drain(self)
 print("SELECTION POLISH RESULT: %d checks, %d failures" % [checks,failures])
 quit(0 if failures==0 else 1)
