extends SceneTree
var checks:=0
var failures:=0
func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var variants: Dictionary={}
 var signatures: Dictionary={}
 var fallbacks:=0
 for seed_value in range(32):
  for floor_index in range(3):
   for room_id in range(12):
    var data:=RoomBlueprint.create(seed_value,floor_index,room_id,"combat")
    var repeated:=RoomBlueprint.create(seed_value,floor_index,room_id,"combat")
    check(data==repeated,"Same seed produces exact interior geometry")
    check(RoomBlueprint.connected(data),"All free grid regions and four doorway anchors remain connected")
    check(not RoomBlueprint.blocks(data,RoomBlueprint.START,16),"Player entry point remains clear")
    variants[data.variant]=true
    signatures[str(data.circles)+str(data.walls)]=true
    if data.fallback: fallbacks+=1
    for location: Vector2 in [Vector2(150,140),Vector2(800,140),Vector2(480,120),Vector2(820,300),Vector2(140,330),Vector2(480,250)]:
     var spawn:=RoomBlueprint.safe_point(data,location)
     check(not RoomBlueprint.blocks(data,spawn,26),"Enemy spawn resolves outside solid geometry")
 check(variants.size()==12,"All twelve interior templates appear")
 check(signatures.size()>100,"Seeded offsets provide varied distributions beyond recolors")
 check(fallbacks==0,"Designed templates pass validation without falling back in sampled seeds")
 for kind in ["start","shop","treasure","secret","special","boss"]:
  var data:=RoomBlueprint.create(54321,2,9,kind)
  check(data.variant==0 and data.circles.is_empty() and data.walls.is_empty(),"Important room preserves open space for rewards and attacks: "+kind)
 root.size=Vector2i(960,540)
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_dungeon(12345)
 check(game.chamber.blueprint.variant==0,"Starting room is actually open in runtime")
 check(game.layout.rooms.size()==12 and game.layout.floor_index==0,"Existing map and floor progression remain intact")
 var signature: Dictionary
 for room_id in range(game.layout.rooms.size()):
  game.layout.current=room_id
  game.start_game()
  check(not game.chamber.blueprint.is_empty(),"Every live dungeon room uses its seeded structure")
  signature=game.chamber.blueprint.duplicate(true)
  for enemy: AbyssEnemy in game.enemies:
   check(not game.chamber.blocks(enemy.position,20),"Actual instantiated enemy is not inside a structure")
  for pickup: RelicPickup in game.pickups:
   check(not game.chamber.blocks(pickup.position,32),"Actual reward has player-sized access around it")
  for quality in range(3):
   game.chamber.quality=quality
   check(game.chamber.blueprint==signature,"Graphics profiles do not regenerate or alter collision geometry")
  game.start_game(true)
  check(game.chamber.blueprint==signature,"Re-entering room preserves exact structures")
 # Physics bodies and projectile sweeps must agree with visible wall geometry.
 game.start_dungeon(7)
 game.layout.current=1
 game.layout.rooms[1].kind="combat"
 game.start_game()
 var wall: Rect2=game.chamber.blueprint.walls[0]
 await physics_frame
 var from: Vector2=game.world.global_position+Vector2(wall.position.x-35,wall.get_center().y)
 var to: Vector2=game.world.global_position+wall.get_center()
 var query:=PhysicsRayQueryParameters2D.create(from,to,1)
 var collision: Dictionary=game.world.get_world_2d().direct_space_state.intersect_ray(query)
 check(not collision.is_empty(),"New interior wall has a real layer-one physics body")
 game.spawn_bullet(Vector2(wall.position.x-35,wall.get_center().y),Vector2.RIGHT,300,1,200,false)
 var bullet: AbyssProjectile=game.bullets.back()
 game._physics_process(0.2)
 check(bullet.expired,"Existing projectile sweep collides with new wall geometry")
 game.show_character_selection()
 var selection: CharacterSelection=game.panel
 await process_frame
 check(selection.plate.position.x<selection.character.position.x,"Character stats are in a real left sidebar")
 check(selection.character.position.x>selection.plate.get_global_rect().end.x+90,"Animated protagonist has clear central space")
 check(selection.begin_button.position.x>selection.character.position.x+100,"Begin is large and separate on the right")
 check(selection.details.text.contains("540") and selection.details.text.contains("SUERTE") and selection.details.text.contains("DEFENSA"),"Sidebar includes actual range luck and defense")
 check(CharacterCatalog.DATA.size()==11 and selection.left_button.visible,"Expanded roster exposes character navigation")
 selection.start()
 selection._process(0.43)
 check(game.state=="playing" and game.layout.floor_index==0,"Redesigned selection starts real dungeon")
 game.show_main_menu()
 var menu: AnimatedMainMenu=game.panel
 check(menu.buttons.size()==3 and not menu.buttons.has("continue"),"Simple functional menu is conserved")
 game.queue_free()
 await process_frame
 print("ROOM STRUCTURE RESULT: %d checks, %d failures, %d variants, %d fallbacks" % [checks,failures,variants.size(),fallbacks])
 await AudioTestCleanup.drain(self)
 quit(1 if failures else 0)
