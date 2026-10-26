extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func _initialize() -> void:
 run.call_deferred()
func touch(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
 var event:=InputEventScreenTouch.new()
 event.index=index
 event.position=position
 event.pressed=pressed
 return event
func run() -> void:
 root.size=Vector2i(960,540)
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 var menu: AnimatedMainMenu=game.panel
 check(menu.intro.active and menu.buttons.new_game.disabled,"Intro blocks buttons initially")
 check(menu.darkness.color.a>0.8,"Startup is dark")
 var intro:=MenuIntro.new()
 var phases: Dictionary={}
 for i in range(67):
  phases[intro.phase()]=true
  intro.advance(0.1)
 check(not intro.active and is_equal_approx(intro.elapsed,6.5),"Introduction duration is 6.5 seconds")
 check(phases.size()==7,"All intro phases execute")
 var old_stats: Dictionary=root.get_node("Settings").values.duplicate()
 root.push_input(touch(0,Vector2(800,120),true),true)
 check(not menu.intro.active,"Touch skips introduction")
 root.push_input(touch(0,Vector2(800,120),false),true)
 check(menu.pending=="" and game.state=="menu","Skip does not accidentally activate new game")
 menu.guard_time=0
 menu.refresh_visuals()
 check(not menu.buttons.new_game.disabled,"New game enabled after intro")
 for action in ["continue","characters","collection"]:
  check(menu.buttons[action].disabled,"Unimplemented action disabled: "+action)
  menu.request_action(action)
  check(menu.pending=="","Disabled action has no callback")
 for dimensions in [Vector2i(960,540),Vector2i(1280,540),Vector2i(960,600)]:
  root.size=dimensions
  await process_frame
  menu.layout_menu()
  await process_frame
  var rectangles: Array[Rect2]=[]
  for action: String in menu.buttons:
   var rect: Rect2=menu.buttons[action].get_global_rect()
   check(rect.size.y>=44 and rect.position.x>=0 and rect.end.x<=dimensions.x+1 and rect.end.y<=dimensions.y+1,"Buttons remain touch sized and within screen")
   for previous: Rect2 in rectangles: check(not rect.intersects(previous),"Menu buttons do not overlap")
   rectangles.append(rect)
  check(game.backdrop.center().x+65<menu.button_panel.position.x,"Character stage is separate from buttons")
 root.size=Vector2i(960,540)
 await process_frame
 menu=game.panel
 menu.guard_time=0
 # Actual GUI pointer dispatch, matching Android's emulated mouse for regular Controls.
 var button: Button=menu.buttons.options
 var event:=InputEventMouseButton.new()
 event.button_index=MOUSE_BUTTON_LEFT
 event.pressed=true
 event.position=button.get_global_rect().get_center()
 root.push_input(event,true)
 var release:=InputEventMouseButton.new()
 release.button_index=MOUSE_BUTTON_LEFT
 release.pressed=false
 release.position=event.position
 root.push_input(release,true)
 check(menu.pending=="options","GUI button receives press/release")
 check(game.backdrop.reaction=="options","Options triggers protagonist reaction")
 menu._process(0.2)
 check(game.state=="options" and game.panel.visible,"Options opens after short transition")
 game.show_main_menu()
 menu=game.panel
 check(not menu.intro.active,"Returning to menu does not replay intro")
 var positions: Array[Vector2]=[]
 var actions: Dictionary={}
 for i in range(181):
  game.backdrop._process(0.1)
  actions[game.backdrop.ambient_action]=true
  positions.append(game.backdrop.character.position)
 check(actions.size()==6,"All six ambient actions occur")
 check(positions[0].distance_to(positions[20])>1,"Protagonist moves automatically")
 for quality in range(3):
  root.get_node("Settings").values.quality=quality
  game.backdrop._process(0.1)
  check(game.backdrop.particle_count()==[4,10,18][quality],"Graphics profiles have bounded particles")
 check(root.get_node("Settings").values.size()==old_stats.size(),"Menu creates no save or inventory state")
 root.get_node("Settings").values=old_stats
 check(game.world==null and game.enemies.is_empty() and game.coins==0,"Ambient actions create no combat world or rewards")
 menu.request_action("credits")
 check(game.backdrop.reaction=="credits","Credits changes gaze")
 menu._process(0.2)
 check(game.state=="credits","Credits opens")
 game.show_main_menu()
 menu=game.panel
 menu.request_action("new_game")
 menu.request_action("options")
 check(menu.pending=="new_game","Repeated input cannot replace pending action")
 check(game.backdrop.reaction=="new_game","New game starts door reaction")
 menu._process(0.46)
 check(game.state=="playing" and game.enemies.size()==6,"New game starts after the animation")
 check(not game.backdrop.visible,"Menu animations hidden during play")
 game.show_main_menu()
 game.show_modes()
 check(game.state=="modes","Existing modes remain available")
 game.start_dungeon()
 check(game.dungeon_mode and game.state=="playing","Dungeon still starts")
 game.show_main_menu()
 var standalone: AnimatedMainMenu=load("res://scenes/ui/main_menu.tscn").instantiate()
 standalone.stage=game.backdrop
 standalone.play_intro=false
 var requests: Array[String]=[]
 standalone.action_requested.connect(func(action: String): requests.append(action))
 root.add_child(standalone)
 await process_frame
 standalone.request_action("exit")
 standalone._process(0.2)
 check(requests==["exit"],"Exit dispatches a real action without triggering combat")
 standalone.queue_free()
 game.queue_free()
 await process_frame
 print("MENU RESULT: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
