extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func clear_enemies(game) -> void:
 for attempt in range(8):
  for enemy in game.enemies.duplicate():
   if is_instance_valid(enemy): enemy.take_damage(10000)
  if game.enemies.is_empty(): break
 for hazard in game.hazards:
  if is_instance_valid(hazard) and hazard.kind=="explosion": hazard._physics_process(2)
func run() -> void:
 root.size=Vector2i(960,540)
 var progress=root.get_node("Progress")
 var original: Dictionary=progress.data.duplicate(true)
 var old_path: String=progress.storage_path
 progress.storage_path="user://bond-edge-tests.json"
 progress.data=progress.fresh()
 check(not progress.record_bond("engineering_done","done") and not progress.record_bond("future_final","done") and not progress.record_bond("no_heal","done"),"Advanced proof flags require their actual prerequisite sets")
 var bad: Dictionary=progress.fresh()
 bad.bonds.universal="yes"
 check(progress.validate(bad).is_empty(),"Code entitlement requires an actual boolean")
 bad=progress.fresh()
 bad.bonds.sets.machines=[12]
 check(progress.validate(bad).is_empty(),"Malformed objective sets rejected")
 check(not progress.record_bond("components","c99") and not progress.record_bond("races","99"),"Unknown components and variants rejected")
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_bond_challenge("race",0)
 game.bonds.tick(41)
 game.clear_wave()
 check(game.bonds.failed and game.state=="playing" and progress.data.bonds.sets.races.is_empty(),"Timed-out race cannot award victory or unlock progress")
 var serial: int=progress.data.serial
 game.bonds.interact()
 check(game.progress.data.serial==serial+1 and not game.bonds.failed and game.bonds.checkpoint==0,"Retry starts a clean attempt")
 game.pause_game()
 var timer: float=game.bonds.timer
 await process_frame
 check(game.bonds.timer==timer and not game.bonds.panel.visible,"Pause freezes challenge timer and hides actions")
 game.resume_game()
 game.start_bond_challenge("circuit",0)
 game.player.position=Vector2(480,274)
 game.bonds.tick(0.016)
 game.clear_wave()
 check(game.bonds.failed and game.bonds.falls==1 and progress.data.bonds.sets.circuits.is_empty(),"Falling in a visible pit prevents a clean circuit reward")
 game.start_bond_challenge("endurance",0)
 game.player.immunity=0
 game.player.take_damage(1)
 game.player.stats.health+=0.5
 game.update_health(game.player.stats.health,game.player.stats.max_health)
 check(game.bonds.healed,"Actual healing is tracked inside endurance encounters")
 game.bonds.timer=0
 clear_enemies(game)
 game.clear_wave()
 check(progress.data.bonds.sets.endurance.has("0") and not progress.data.bonds.no_heal,"Healed encounter may win but cannot claim the no-healing achievement")
 game.start_bond_challenge("ecology",0)
 game.player.position=game.bonds.stations[0].point
 game.bonds.refresh_panel()
 var crafted: int=progress.data.bonds.antidotes
 game.bonds.interact()
 check(progress.data.bonds.antidotes==crafted and game.player.character_state.antidotes==0,"Cannot craft antidote without biomass")
 for pickup in game.pickups:
  if pickup is BondPickup: pickup.claim()
 game.bonds.interact()
 game.bonds.interact()
 check(game.bonds.antidote_time==6 and game.player.character_state.samples==0,"Craft/use consumes two resources and grants exactly six seconds")
 game.bonds.tick(6.1)
 var hp: float=game.player.stats.health
 game.player.immunity=0
 game.player.take_damage(1,"acid")
 check(game.player.stats.health<hp and not game.bonds.env_clean,"Environmental protection expires and damage invalidates clean-room proof")
 game.start_dungeon(1288)
 game.layout.current=9
 game.start_game(true)
 for pickup in game.pickups:
  if pickup is BondPickup and pickup.data.reward_kind=="component": pickup.claim()
 var machine: Dictionary=game.bonds.stations[0]
 game.player.position=machine.point
 game.bonds.refresh_panel()
 game.bonds.interact()
 check(game.layout.rooms[9].get("machine_done",false),"Campaign workshop uses the same repair interaction")
 var stock: Dictionary=game.player.character_state.component_stock.duplicate(true)
 game.start_game(true)
 check(game.bonds.stations[0].used and game.player.character_state.component_stock==stock,"Revisiting a repaired campaign machine cannot consume resources again")
 # Shared touch button: one tap is one action, emulation/release outside are safe.
 var button:=AbyssTouchButton.new()
 button.position=Vector2(200,180)
 button.size=Vector2(200,60)
 game.ui.add_child(button)
 var presses: Array=[]
 button.pressed.connect(func(): presses.append(true))
 await process_frame
 for down in [true,false]:
  var event:=InputEventScreenTouch.new()
  event.index=95
  event.position=button.get_global_rect().get_center()
  event.pressed=down
  root.push_input(event,true)
 check(presses.size()==1,"New menu buttons accept actual ScreenTouch once")
 for down in [true,false]:
  var mouse:=InputEventMouseButton.new()
  mouse.device=InputEvent.DEVICE_ID_EMULATION
  mouse.button_index=MOUSE_BUTTON_LEFT
  mouse.position=button.get_global_rect().get_center()
  mouse.pressed=down
  root.push_input(mouse,true)
 check(presses.size()==1,"Emulated mouse cannot duplicate a touch action")
 var press:=InputEventScreenTouch.new()
 press.index=95
 press.position=button.get_global_rect().get_center()
 press.pressed=true
 root.push_input(press,true)
 press.position=Vector2(10,10)
 press.pressed=false
 root.push_input(press,true)
 check(presses.size()==1 and button.owner_finger==-1,"Release outside cancels and never leaves the button captured")
 button.queue_free()
 game.show_main_menu()
 game.start_relic_room()
 var fake: RelicPickup=game.spawn_pickup({"id":"c5","reward_kind":"component","position":Vector2(480,300),"chest":false,"collected":false})
 check(not fake.claim() and not progress.data.bonds.sets.components.has("c5"),"Laboratory cannot fabricate exploration components")
 game.show_main_menu()
 game.show_modes()
 await process_frame
 check(game.panel.get_global_rect().position.y>=0 and game.panel.get_global_rect().end.y<=540,"Expanded mode menu remains within Android viewport")
 # Every visible challenge menu is accessible and fits the same viewport.
 game.show_bond_hub()
 await process_frame
 check(game.panel.get_global_rect().end.y<=540,"Nine challenge groups fit the main hub")
 for kind in ["engineering","ecology","future","theater","race","circuit","tactics","endurance","family"]:
  game.show_bond_variants(kind)
  await process_frame
  check(game.panel.get_global_rect().position.y>=0 and game.panel.get_global_rect().end.y<=540,"Variant screen fits: "+kind)
 game.queue_free()
 await process_frame
 await preload("res://tests/audio_test_cleanup.gd").drain(self)
 progress.data=original
 progress.storage_path=old_path
 print("BOND EDGE RESULT: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
