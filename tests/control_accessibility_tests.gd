extends SceneTree
var checks:=0
var failures:=0
var actions: Dictionary={"ability":0,"item":0,"awaken":0}
func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func _initialize() -> void: run.call_deferred()
func touch(index: int, point: Vector2, pressed: bool) -> void:
 var event:=InputEventScreenTouch.new()
 event.index=index
 event.position=point
 event.pressed=pressed
 root.push_input(event,true)
func drag(index: int, point: Vector2) -> void:
 var event:=InputEventScreenDrag.new()
 event.index=index
 event.position=point
 root.push_input(event,true)
func run() -> void:
 root.size=Vector2i(960,540)
 var settings:=root.get_node("Settings")
 var previous: Dictionary=settings.values.duplicate(true)
 var progress: Dictionary=root.get_node("Progress").data.duplicate(true)
 var old_settings: Dictionary={"version":1,"quality":0,"control_scale":1.2,"control_opacity":0.5,"stats_view":1}
 var migrated: Dictionary=settings.validate(JSON.parse_string(JSON.stringify(old_settings)))
 check(migrated.quality==0 and migrated.control_scale==1.2 and not migrated.left_handed and migrated.move_deadzone==0.12,"Old settings keep values and acquire safe input defaults")
 var bad: Dictionary=migrated.duplicate(true)
 bad.move_deadzone=NAN
 bad.fire_style=99
 bad.left_handed="yes"
 var clean: Dictionary=settings.validate(bad)
 check(clean.move_deadzone==0.12 and clean.fire_style==1 and not clean.left_handed,"Invalid control configuration is validated")
 var controls:=TouchControls.new()
 root.add_child(controls)
 controls.size=Vector2(960,540)
 controls.set_enabled(true)
 controls.ability_requested.connect(func(): actions.ability+=1)
 controls.item_requested.connect(func(): actions.item+=1)
 controls.awaken_requested.connect(func(): actions.awaken+=1)
 await process_frame
 # A finger started on scenery never turns into a firing finger on drag.
 touch(10,Vector2(480,200),true)
 drag(10,controls.attack_positions()[0])
 check(controls.fire_vector==Vector2.ZERO and controls.finger_roles.is_empty(),"Unowned scenery drag cannot fire")
 touch(10,controls.attack_positions()[0],false)
 touch(11,controls.joystick_center()+Vector2(25,0),true)
 touch(12,controls.attack_positions()[0],true)
 check(controls.move_vector.x>0 and controls.fire_vector==Vector2.UP,"Movement and firing remain independent")
 drag(12,controls.attack_center()+Vector2(40,-36))
 check(controls.fire_vector==Vector2.UP,"Direction hysteresis prevents diagonal jitter")
 drag(12,controls.attack_center()+Vector2(55,-5))
 check(controls.fire_vector==Vector2.RIGHT,"Firing direction changes continuously across button gaps")
 drag(12,controls.attack_center())
 check(controls.fire_vector==Vector2.RIGHT,"Crossing the firing centre does not drop a held shot")
 touch(13,controls.attack_positions()[2],true)
 drag(12,controls.attack_positions()[0])
 check(controls.fire_vector==Vector2.DOWN,"Older-finger drag cannot steal the last held firing direction")
 touch(13,controls.attack_positions()[2],false)
 check(controls.fire_vector==Vector2.UP,"Release restores the other held direction")
 touch(12,Vector2.ZERO,false)
 check(controls.fire_vector==Vector2.ZERO and controls.move_vector.x>0,"Release outside button clears only its original owner")
 touch(11,Vector2.ZERO,false)
 check(controls.finger_roles.is_empty() and controls.move_vector==Vector2.ZERO,"All original fingers release cleanly")
 controls.excluded_regions=[Rect2(controls.attack_center()-Vector2(80,80),Vector2(160,160))]
 touch(14,controls.attack_positions()[1],true)
 check(controls.fire_vector==Vector2.ZERO and not controls.finger_roles.has(14),"Interactive UI exclusion wins over game input")
 touch(14,Vector2.ZERO,false)
 controls.excluded_regions.clear()
 controls.item_visible=true
 controls.awaken_visible=true
 controls.item_cooldown=4
 controls.ability_cooldown=3
 controls.determination=50
 for pair in [[15,controls.item_center()],[16,controls.ability_center()],[17,controls.awaken_center()]]:
  touch(pair[0],pair[1],true)
  drag(pair[0],controls.attack_positions()[1])
 check(actions.item==0 and actions.ability==0 and actions.awaken==0 and controls.fire_vector==Vector2.ZERO,"Unready actions do not activate or become firing drags")
 controls.release_all()
 controls.item_cooldown=0
 controls.ability_cooldown=0
 controls.determination=100
 touch(18,controls.item_center(),true)
 touch(19,controls.ability_center(),true)
 touch(20,controls.awaken_center(),true)
 touch(19,controls.ability_center(),true)
 check(actions.item==1 and actions.ability==1 and actions.awaken==1,"Separate ready actions fire once; duplicate press is ignored")
 controls._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(controls.finger_roles.is_empty() and controls.special_fingers.is_empty(),"Focus loss clears all action fingers")
 touch(21,controls.attack_positions()[0],true)
 controls.hide()
 check(controls.fire_vector==Vector2.ZERO and controls.finger_roles.is_empty(),"Hiding a control layer cannot leave a held attack")
 controls.show()
 for handed in [false,true]:
  for floating in [false,true]:
   for style in [0,1]:
    for factor in [0.8,1.0,1.25]:
     controls.configure({"left_handed":handed,"floating_joystick":floating,"fire_style":style,"control_scale":factor})
     controls.safe_insets=Vector4(40,20,20,28)
     var anchor:=controls.joystick_anchor()
     var press:=anchor+Vector2(20,0)
     touch(30,press,true)
     if floating: check(controls.move_vector==Vector2.ZERO,"Floating joystick starts without an edge-clamping jump")
     drag(30,press+Vector2(50,0))
     touch(31,controls.attack_positions()[0],true)
     check(controls.move_vector.x>0 and controls.fire_vector==Vector2.UP,"All handedness, movement, firing and size profiles remain usable")
     for point: Vector2 in controls.attack_positions()+[controls.ability_center(),controls.awaken_center(),controls.item_center()]:
      check(point.x-30*factor>=controls.safe_insets.x and point.x+30*factor<=controls.size.x-controls.safe_insets.z and point.y-30*factor>=controls.safe_insets.y and point.y+30*factor<=controls.size.y-controls.safe_insets.w,"Largest controls respect synthetic safe screen insets")
     touch(30,Vector2.ZERO,false)
     touch(31,Vector2.ZERO,false)
 controls.configure({"move_deadzone":0.2})
 touch(40,controls.joystick_center()+Vector2(5,0),true)
 check(controls.move_vector==Vector2.ZERO,"Dead zone suppresses small movement noise")
 drag(40,controls.joystick_center()+Vector2(55,0))
 check(is_equal_approx(controls.move_vector.length(),1),"Rescaled dead zone preserves full movement speed")
 controls.release_all()
 touch(41,controls.attack_positions()[0],true)
 controls.size=Vector2(1280,540)
 check(controls.fire_vector==Vector2.ZERO,"Resize clears stale screen-coordinate captures")
 controls.queue_free()
 await process_frame
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_dungeon(12345)
 game.player.stats.health=4
 game.coins=17
 game.pause_game()
 game.show_control_options("paused")
 await process_frame
 check(game.state=="control_options" and game.panel.get_global_rect().end.y<=540,"Control settings are accessible and fit the viewport")
 settings.values.left_handed=true
 settings.values.fire_style=1
 game.show_control_preview()
 await process_frame
 var preview: ControlPractice=game.panel.get_child(0)
 check(game.state=="control_preview" and preview.controls.left_handed and preview.controls.fire_style==1,"Practice uses the selected settings independently")
 preview.controls.move_vector=Vector2.RIGHT
 preview._process(0.1)
 check(game.player.stats.health==4 and game.coins==17 and root.get_node("Progress").data.counters.endings==progress.counters.endings,"Practice cannot change combat or permanent rewards")
 preview.back_requested.emit()
 check(game.state=="control_options","Practice back returns to control settings")
 check(settings.save_settings()==OK,"New control preferences persist")
 var chosen: Dictionary=settings.values.duplicate(true)
 settings.values=settings.DEFAULTS.duplicate(true)
 settings.load_settings()
 check(settings.values.left_handed and settings.values.fire_style==1,"Handedness and firing style survive reload")
 game.apply_controls()
 check(game.controls.left_handed and game.hud.left_handed,"Gameplay and HUD adopt the same handedness")
 game.resume_game()
 await process_frame
 check(game.player.stats.health==4 and game.coins==17,"Returning from settings preserves the paused run")
 game.queue_free()
 await process_frame
 await create_timer(0.25).timeout
 settings.values=previous
 print("CONTROL ACCESSIBILITY RESULT: %d checks, %d failures" % [checks,failures])
 await AudioTestCleanup.drain(self)
 quit(1 if failures else 0)
