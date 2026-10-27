extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func tap(button: Button) -> void:
 for pressed in [true,false]:
  var event:=InputEventScreenTouch.new()
  event.index=77
  event.position=button.get_global_rect().get_center()
  event.pressed=pressed
  root.push_input(event,true)
func run() -> void:
 root.size=Vector2i(960,540)
 var progress=root.get_node("Progress")
 var before: Dictionary=progress.data.duplicate(true)
 var old_path: String=progress.storage_path
 progress.storage_path="user://journal-test.json"
 progress.data=progress.fresh()
 for version in [1,2]:
  var legacy: Dictionary=progress.fresh()
  legacy.erase("journal")
  legacy.version=version
  legacy.items=["crystal"]
  legacy.boss_types=["root_matron"]
  legacy.unlocked=["neris","mira"]
  legacy.counters.enemies=150
  legacy.counters.floors=3
  var migrated: Dictionary=progress.validate(JSON.parse_string(JSON.stringify(legacy)))
  check(migrated.version==progress.VERSION and migrated.items==["crystal"] and migrated.unlocked.has("mira"),"Older save migrates without losing items or characters")
  check(migrated.journal.bosses==["root_matron"],"Old verified boss IDs provide honest journal evidence")
  check(migrated.journal.creatures.is_empty() and migrated.journal.maps.is_empty() and migrated.journal.floors.is_empty(),"Aggregate old counters never fabricate species or maps")
  check(progress.import_code("AOT%d." % version+Marshalls.utf8_to_base64(JSON.stringify(legacy))),"Old backup code imports")
 check(not progress.discover({"machines":["unimplemented_machine"]}),"No invented machines or repairs")
 check(not progress.discover({"creatures":["not_real"]}),"Unknown creature rejected")
 var malformed: Dictionary=progress.fresh()
 malformed.journal.creatures="bad"
 check(progress.validate(malformed).is_empty(),"Malformed journal category rejected")
 malformed=progress.fresh()
 malformed.journal.secrets=[14]
 check(progress.validate(malformed).is_empty(),"Non-string route evidence rejected")
 for invalid in ["salt_crypt:01:0:0","salt_crypt:-1:0:0","salt_crypt:1:999:0","missing:0:0:0","salt_crypt:1:0:0:extra"]:
  check(not AbyssJournal.valid_id("secrets",invalid),"Invalid route syntax rejected")
 check(progress.discover({"floors":["salt_crypt"],"creatures":["shadow"]}),"Known discoveries stored atomically")
 var saved: Dictionary=progress.data.duplicate(true)
 var mtime:=FileAccess.get_modified_time(progress.storage_path)
 check(not progress.discover({"floors":["salt_crypt"],"creatures":["shadow"]}) and progress.data==saved and FileAccess.get_modified_time(progress.storage_path)==mtime,"Repeated observations never duplicate entries or rewrite the file")
 progress.load_progress()
 check(progress.data==saved,"Discoveries survive real disk reload")
 var current_path: String=progress.storage_path
 progress.storage_path="user://missing-journal-parent/progress.json"
 check(not progress.discover({"creatures":["eye"]}) and progress.data==saved,"Failed save rolls back journal mutation")
 progress.storage_path=current_path
 var code: String=progress.export_code()
 check(code.begins_with("AOT4."),"New portable backup carries journal version")
 progress.discover({"creatures":["eye"]})
 check(progress.import_code(code) and progress.data.journal.creatures.has("eye"),"Restoring old backup preserves newer observations")
 var fresh_backup: String=progress.export_code()
 progress.data=progress.fresh()
 check(progress.import_code(fresh_backup) and progress.data.journal.creatures.has("eye") and progress.data.items.has("crystal"),"Portable code restores journal and existing item collection together")
 var file:=FileAccess.open(progress.storage_path,FileAccess.WRITE)
 file.store_string("broken")
 file.close()
 progress.load_progress()
 check(progress.recovered and not progress.data.journal.creatures.is_empty(),"Corrupt primary recovers valid journal backup")
 progress.data=progress.fresh()
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 check(progress.data.journal.floors.is_empty(),"Menu animations do not discover floors")
 game.start_relic_room()
 await process_frame
 check(progress.data.journal.creatures.is_empty() and progress.data.journal.floors.is_empty(),"Laboratory creates no species or floor records")
 game.show_main_menu()
 game.start_dungeon(1502)
 check(progress.data.journal.floors==["salt_crypt"],"Actual expedition start registers first floor")
 check(progress.data.journal.maps.is_empty(),"Entering a floor is not completing its map")
 game.layout.current=1
 game.start_game(true)
 check(not progress.data.journal.creatures.is_empty(),"Living encountered enemies are recorded without requiring kills")
 var species_before: int=progress.data.journal.creatures.size()
 game.observe_journal_room()
 check(progress.data.journal.creatures.size()==species_before,"Room revisit does not duplicate species")
 var elite_count: int=progress.amount("elites")
 game.spawn_enemy(18,Vector2(700,200),false,"elite")
 await process_frame
 check(progress.data.journal.creatures.has(EnemyCatalog.DATA[18].id) and progress.amount("elites")==elite_count,"Dynamic spawn is observed without awarding kill progress")
 var item: RelicPickup=game.spawn_pickup({"id":"crystal","position":Vector2(480,300),"chest":false,"collected":false})
 check(not progress.data.items.has("crystal"),"Visible uncollected item is not a collected object")
 check(item.claim() and AbyssJournal.entries(progress.data,"items").has("crystal"),"True accepted pickup appears in journal")
 var maps_before: int=progress.data.journal.maps.size()
 for room: Dictionary in game.layout.rooms: room.visited=true
 game.layout.rooms[game.layout.secret_room].visited=false
 game.observe_journal_room()
 check(progress.data.journal.maps.size()==maps_before,"Hidden unvisited secret prevents false 100 percent map")
 game.layout.current=game.layout.secret_room
 game.start_game(true)
 check(progress.data.journal.maps==["salt_crypt"] and progress.data.journal.secrets.size()==1,"Visiting final secret completes the real map and unique route")
 var route: String=progress.data.journal.secrets[0]
 game.observe_journal_room()
 check(progress.data.journal.secrets==[route],"Repeated secret observation does not farm route evidence")
 game.layout.generate(1502,0,true)
 game.layout.current=game.layout.secret_room
 game.start_game(true)
 check(progress.data.journal.secrets.size()==1,"Same seed and secret remain unique across generated maps")
 game.layout.generate(1503,0,true)
 game.layout.current=game.layout.secret_room
 game.start_game(true)
 check(progress.data.journal.secrets.size()==2,"Different map seed yields distinct secret route")
 for floor_index in [1,2]:
  game.layout.generate(1502,floor_index,true)
  for room: Dictionary in game.layout.rooms: room.visited=true
  game.layout.current=game.layout.boss_room
  game.start_game(true)
  check(progress.data.journal.maps.has(AbyssJournal.floor_id(floor_index)),"Each different floor contributes one completed map")
  check(progress.data.journal.bosses.has(TideWarden.BOSS_IDS[floor_index]),"Actual boss encounter recorded before victory")
 check(progress.data.journal.maps.size()==3,"Three different maps can be recorded without fake twelve-floor data")
 var coins: int=game.coins
 var health: float=game.player.stats.health
 var cooldown: float=game.player.ability_remaining
 game.pause_game()
 game.show_diary("paused")
 await process_frame
 var diary: AbyssDiary=game.panel
 check(game.state=="diary" and not game.controls.enabled and game.world.process_mode==Node.PROCESS_MODE_DISABLED,"Diary pauses real combat and releases gameplay controls")
 var start_point: Vector2=diary.navigation.get_parent().get_global_rect().get_center()
 var press:=InputEventScreenTouch.new()
 press.index=81
 press.pressed=true
 press.position=start_point
 root.push_input(press,true)
 var drag:=InputEventScreenDrag.new()
 drag.index=81
 drag.position=start_point-Vector2(0,160)
 root.push_input(drag,true)
 press.pressed=false
 press.position=drag.position
 root.push_input(press,true)
 check(diary.navigation.get_parent().scroll_vertical>0 and diary.category=="floors","Real touch scrolls category list without selecting a crossed button")
 for dimensions in [Vector2i(960,540),Vector2i(1280,540),Vector2i(960,600)]:
  root.size=dimensions
  await process_frame
  check(diary.size==Vector2(dimensions),"Journal fills supported viewport")
  for category: String in AbyssJournal.CATEGORIES:
   diary.select_category(category)
   await process_frame
   check(diary.content.get_child_count()<=4,"Journal uses bounded pages")
   check(diary.scroll.get_global_rect().end.x<=dimensions.x and diary.scroll.get_global_rect().end.y<=dimensions.y,"Entry list stays onscreen")
  for button: Button in [diary.previous,diary.next,diary.back]:
   var rect:=button.get_global_rect()
   check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=dimensions.x and rect.end.y<=dimensions.y and rect.size.y>=44,"Diary controls are onscreen and touch sized")
  check(diary.paging.get_global_rect().end.y<=dimensions.y and diary.paging.size.x>=100,"Page indicator stays readable on one line")
 check(game.coins==coins and game.player.stats.health==health and game.player.ability_remaining==cooldown,"Reading diary never modifies resources or ability timers")
 tap(diary.back)
 check(game.state=="paused","Real touch returns to pause without losing the run")
 game.resume_game()
 check(game.controls.enabled and game.coins==coins,"Resume restores multitouch after journal")
 game.show_main_menu()
 game.show_archive()
 game.show_diary()
 await process_frame
 tap(game.panel.back)
 check(game.state=="archive" and game.world==null,"Menu diary returns to archive without creating an expedition")
 # Large existing item collection is paginated, with names and real effects.
 for entry: Dictionary in RelicCatalog.DATA:
  if not progress.data.items.has(entry.id): progress.data.items.append(entry.id)
 game.show_diary()
 diary=game.panel
 diary.select_category("items")
 check(diary.content.get_child_count()==4 and diary.next.disabled==false,"Hundred-item journal only creates four item rows")
 diary.page=24
 diary.refresh()
 check(diary.paging.text=="25 / 25" and diary.next.disabled,"All hundred entries can be reached")
 check(CharacterCatalog.DATA.size()==20 and not CharacterCatalog.playable("lyra") and not CharacterCatalog.playable("darian"),"Unimplemented characters are not advertised as playable")
 game.queue_free()
 await process_frame
 await preload("res://tests/audio_test_cleanup.gd").drain(self)
 progress.data=before
 progress.storage_path=old_path
 print("JOURNAL RESULT: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
