extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("TEST FAILED: "+message)
func _initialize() -> void:
 run.call_deferred()
func click(button: Button) -> void:
 for pressed in [true,false]:
  var event := InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_LEFT
  event.position = button.get_global_rect().get_center()
  event.pressed = pressed
  root.push_input(event,true)
func run() -> void:
 root.size=Vector2i(960,540)
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 var menu: AnimatedMainMenu = game.panel
 menu.skip_intro()
 menu.guard_time=0
 await process_frame
 click(menu.buttons.new_game)
 menu._process(0.46)
 check(game.state=="character_selection","New game GUI opens selection")
 var selection: CharacterSelection=game.panel
 await process_frame
 check(selection.heading.text.contains("Neris"),"Real character name displayed")
 check(selection.entries.size()==11 and selection.left_button.visible and selection.right_button.visible,"All eleven characters are browsable from first launch")
 check(not selection.begin_button.disabled,"Neris starts unlocked")
 var stats: ActorStats=CharacterCatalog.initial_stats("neris")
 check(stats.health==6 and stats.damage==1 and stats.speed==185 and is_equal_approx(stats.attack_interval,1.0/2.8),"Catalog preserves existing real base stats")
 check(selection.details.text.contains("2.80") and selection.details.text.contains("185"),"Preview derives cadence and speed from stats")
 check(selection.details.text.contains("ninguno"),"No fictitious starting item")
 check(CharacterCatalog.initial_stats("missing")==null and not game.begin_character_run("missing"),"Unknown character denied by gameplay boundary")
 var old_clock: float=selection.character.clock
 selection._process(0.1)
 check(selection.character.clock>old_clock,"Preview idle is animated")
 for dimensions in [Vector2i(960,540),Vector2i(1280,540),Vector2i(960,600)]:
  root.size=dimensions
  await process_frame
  selection.layout_selection()
  await process_frame
  for button: Button in [selection.begin_button,selection.back_button]:
   var rect := button.get_global_rect()
   check(rect.size.y>=52 and rect.position.x>=0 and rect.end.x<=dimensions.x and rect.end.y<=dimensions.y,"Touch targets remain large and onscreen")
  check(not selection.begin_button.get_global_rect().intersects(selection.back_button.get_global_rect()),"Begin and back never overlap")
  check(selection.status.get_global_rect().end.x<=dimensions.x,"Unlock status stays onscreen")
  check(selection.status.get_minimum_size().y<=selection.status.size.y,"Unlock status wraps without cutting text")
  check(selection.plate.get_global_rect().end.x<=dimensions.x,"Stats panel stays inside screen")
  check(selection.character.position.x-100>selection.plate.get_global_rect().end.x,"Large protagonist stays separate from stats")
  check(selection.left_scroll.size.y<=selection.plate.size.y-30,"Details fit available height")
 root.size=Vector2i(960,540)
 await process_frame
 # Synthetic locked fixture exercises reusable navigation without inventing released content.
 selection.entries.resize(1)
 selection.entries.append({"id":"locked_fixture","name":"Silueta","unlocked":false,"requirement":"Requisito de prueba"})
 selection.refresh()
 check(selection.left_button.visible and selection.right_button.visible,"Arrows enabled when more than one entry exists")
 click(selection.right_button)
 check(selection.index==1 and selection.begin_button.disabled,"Right arrow selects locked silhouette and disables begin")
 check(selection.status.text.contains("Requisito de prueba") and selection.character.modulate.r<0.1,"Locked entry shows silhouette and unlock requirement")
 selection.start()
 check(not selection.pending,"Locked selection cannot start")
 click(selection.left_button)
 check(selection.index==0 and not selection.begin_button.disabled,"Left arrow returns to Neris")
 selection.entries.resize(1)
 selection.refresh()
 # Back returns with no run mutation.
 click(selection.back_button)
 check(game.state=="menu" and game.world==null,"Back cancels without creating a run")
 game.show_character_selection()
 selection=game.panel
 await process_frame
 click(selection.begin_button)
 check(selection.pending and game.state=="character_selection","Begin plays short preview reaction before loading")
 selection.start()
 selection._process(0.43)
 check(game.state=="playing" and game.dungeon_mode and game.layout.floor_index==0 and game.layout.current==0,"Begin loads initial room of existing dungeon")
 check(game.player.stats.health==stats.health and game.player.stats.damage==stats.damage and game.player.stats.speed==stats.speed and game.player.stats.attack_interval==stats.attack_interval,"Gameplay receives exact preview stats")
 check(game.controls.enabled,"Existing touch controls enabled for new run")
 check(game.layout.rooms.size()==12 and EnemyCatalog.DATA.size()==20,"Exploration and twenty existing enemy definitions preserved")
 game.player.stats.damage=8
 game.show_main_menu()
 game.show_character_selection()
 selection=game.panel
 await process_frame
 selection.start()
 selection._process(0.43)
 check(game.player.stats.damage==1,"New selection resets previous run upgrades")
 game.show_main_menu()
 game.show_options("menu")
 await process_frame
 check(game.state=="options","Options still open")
 check(game.panel.get_global_rect().position.y>=0 and game.panel.get_global_rect().end.y<=540,"Options and relocated links fit screen")
 game.queue_free()
 await process_frame
 print("SELECTION RESULT: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
