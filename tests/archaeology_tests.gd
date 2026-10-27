extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func item(game, id: String, chest: bool=false) -> RelicPickup:
 return game.spawn_pickup({"id":id,"reward_kind":"artifact","position":Vector2(480,300),"chest":chest,"collected":false})
func run() -> void:
 var progress=root.get_node("Progress")
 var old: Dictionary=progress.data.duplicate(true)
 var old_path: String=progress.storage_path
 progress.data=progress.fresh()
 progress.storage_path="user://archaeology-tests.json"
 root.size=Vector2i(960,540)
 check(ArchaeologyCatalog.errors().is_empty(),"Archaeology registry validates all source data")
 check(ArchaeologyCatalog.entries().size()==12,"Twelve actual narrative finds")
 var ids: Dictionary={}
 var icons: Dictionary={}
 for entry: Dictionary in ArchaeologyCatalog.entries():
  check(not ids.has(entry.id) and RelicCatalog.definition(entry.id).is_empty(),"Artifact IDs never duplicate combat items")
  ids[entry.id]=true
  check(not icons.has(entry.icon) and ResourceLoader.exists(entry.icon),"Each find has a distinct original icon")
  icons[entry.icon]=true
  check(entry.story.length()>50 and not ArchaeologyCatalog.definition(entry.id).is_empty(),"Each find contains retrievable narrative and data")
 var rng:=RandomNumberGenerator.new()
 for seed_value in range(40):
  for floor_index in range(3):
   rng.seed=seed_value
   var rolled:=ArchaeologyCatalog.roll(rng,floor_index,"secret",[])
   check(int(ArchaeologyCatalog.definition(rolled).floor)==floor_index,"Finds respect floor table")
   rng.seed=seed_value
   check(ArchaeologyCatalog.roll(rng,floor_index,"secret",[])==rolled,"Same seed reproduces archaeological reward")
 check(ArchaeologyCatalog.roll(rng,0,"shop",[])=="","Archaeology is not silently added to shop stock")
 check(ArchaeologyCatalog.roll(rng,0,"secret",ids.keys())=="","Exhausted discovered catalog produces no duplicate rewards")
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_dungeon(9044)
 var first_id: String=""
 for floor_index in range(3):
  game.layout.generate(9044,floor_index,true)
  game.layout.current=game.layout.secret_room
  game.start_game(true)
  var finds: Array=[]
  for pickup: RelicPickup in game.pickups:
   if pickup is ArchaeologyPickup: finds.append(pickup)
  check(finds.size()==1,"Real secret room contains one physical archaeology cache")
  var find: RelicPickup=finds[0]
  check(not game.chamber.blocks(find.position,32),"Cache is accessible outside obstacles")
  game.player.position=find.position+Vector2(70,0)
  find.cooldown=0
  game.update_pickup_interaction()
  await process_frame
  check(game.pickup_interaction.get_global_rect().end.y<=540,"Archaeology interaction stays inside Android viewport")
  for pressed in [true,false]:
   var touch:=InputEventScreenTouch.new()
   touch.index=72
   touch.position=game.pickup_interaction.action.get_global_rect().get_center()
   touch.pressed=pressed
   root.push_input(touch,true)
  check(find.data.get("opened",false) and not find.open_chest(),"Real touch opens archaeological cache exactly once")
  find.cooldown=0
  find.open_age=1
  game.player.position=find.position
  find._physics_process(0.016)
  check(find.data.collected and progress.data.journal.artifacts.has(find.data.id),"Physical proximity pickup records persistent archaeology")
  check(not find.claim(),"Archaeological reward cannot be claimed twice")
  if first_id.is_empty(): first_id=find.data.id
 progress.data.journal.artifacts.clear() # Isolate functional effects from random cache finds.
 game.start_dungeon(9045)
 var keys_before: int=game.keys
 var cash: int=game.coins
 var damage: float=game.player.stats.damage
 var key_find:=item(game,"gate_tooth")
 # Earlier random find might already be this one; isolate the key demonstration.
 progress.data.journal.artifacts.erase("gate_tooth")
 check(not game.collect_artifact(key_find),"Direct callback cannot bypass the common claim reservation")
 check(key_find.claim() and game.keys==keys_before+1,"First archaeological key is functional")
 var duplicate:=item(game,"gate_tooth")
 check(duplicate.claim() and game.keys==keys_before+1,"Prepared duplicate is consumed without farming keys")
 check(game.coins==cash and game.player.stats.damage==damage,"Archaeology does not inflate coins or combat stats")
 var hint:=item(game,"tide_needle")
 var secrets_before: int=progress.data.journal.secrets.size()
 check(game.layout.room_hidden(game.layout.secret_room),"Secret starts hidden")
 check(hint.claim() and not game.layout.room_hidden(game.layout.secret_room),"Needle reveals one real secret entrance")
 check(game.layout.rooms[game.layout.secret_room].locked and progress.data.journal.secrets.size()==secrets_before,"Hint neither unlocks nor falsely visits the secret")
 var chart:=item(game,"salt_chart")
 var visible_before: int=game.layout.visible_rooms().size()
 check(chart.claim() and game.layout.visible_rooms().size()>visible_before,"Chart expands actual minimap visibility")
 check(progress.data.journal.maps.is_empty() and game.layout.rooms.filter(func(room): return room.visited).size()==1,"Mapped rooms are not visited or a free completed map")
 var story:=item(game,"salt_bell")
 check(story.claim() and progress.data.journal.artifacts.has("salt_bell"),"Narrative-only find unlocks a real diary story")
 var bad:=item(game,"not_real")
 check(not bad.valid_reward() and not bad.claim(),"Malformed artifact is not consumed or awarded")
 var guarded:=item(game,"root_seal")
 var path: String=progress.storage_path
 progress.storage_path="user://missing-archaeology-parent/progress.json"
 check(not guarded.claim() and not guarded.data.collected and not progress.data.journal.artifacts.has("root_seal"),"Failed persistence leaves archaeological pickup available")
 progress.storage_path=path
 check(guarded.claim(),"Pickup can retry after storage failure")
 var count: int=progress.data.journal.artifacts.size()
 var backup: String=progress.export_code()
 progress.data=progress.fresh()
 check(progress.import_code(backup) and progress.data.journal.artifacts.size()==count,"Archaeology survives portable restore")
 progress.load_progress()
 check(progress.data.journal.artifacts.size()==count,"Archaeology survives actual reload")
 game.pause_game()
 game.show_diary("paused")
 var diary: AbyssDiary=game.panel
 diary.select_category("artifacts")
 check(diary.content.get_child_count()>0 and diary.heading.text.contains(str(count)),"Diary displays collected archaeological icons and stories")
 game.close_diary()
 game.show_main_menu()
 game.start_relic_room()
 var laboratory_find:=item(game,"crystal_latch")
 check(not laboratory_find.claim() and not progress.data.journal.artifacts.has("crystal_latch"),"Laboratory cannot grant persistent archaeology")
 # All twelve effects and rewards can execute through the real claim interface.
 progress.data.journal.artifacts.clear()
 game.show_main_menu()
 for entry: Dictionary in ArchaeologyCatalog.entries():
  game.start_dungeon(9046)
  var specimen:=item(game,entry.id)
  check(specimen.claim(),"Functional collectable: "+str(entry.id))
 check(progress.data.journal.artifacts.size()==12 and RelicCatalog.DATA.size()==100,"All twelve finds are separate from the hundred combat items")
 game.queue_free()
 await process_frame
 await preload("res://tests/audio_test_cleanup.gd").drain(self)
 progress.data=old
 progress.storage_path=old_path
 print("ARCHAEOLOGY RESULT: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
