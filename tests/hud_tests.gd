extends SceneTree
var checks:=0
var failures:=0
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
func tap(button: Button) -> void:
 var point:=button.get_global_rect().get_center()
 touch(5,point,true)
 touch(5,point,false)
func run() -> void:
 root.size=Vector2i(960,540)
 var settings=root.get_node("Settings")
 var original: Dictionary=settings.values.duplicate()
 var existed:=FileAccess.file_exists(settings.PATH)
 var contents:=FileAccess.get_file_as_string(settings.PATH) if existed else ""
 var migrated: Dictionary=settings.validate({"version":1,"quality":2,"control_scale":1.1,"control_opacity":0.6,"diagnostics":true})
 check(migrated.stats_view==0 and migrated.quality==2 and is_equal_approx(migrated.control_scale,1.1) and migrated.diagnostics,"Older settings gain default view without losing existing preferences")
 check(settings.validate({"version":1,"stats_view":1.0}).stats_view==1,"JSON numeric view round-trips after parsing floats")
 check(settings.validate({"version":1,"stats_view":99}).stats_view==2,"View enum is bounded")
 check(settings.validate({"version":1,"stats_view":"expanded"}).stats_view==0,"Invalid view data recovers safely")
 settings.values.stats_view=0
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 check(not game.hud.visible,"Gameplay HUD stays hidden on main menu")
 game.start_dungeon(12345)
 var hud: CompactHUD=game.hud
 await process_frame
 check(hud.visible and hud.compact.visible and not hud.detail.visible,"New run initially shows three stats")
 check(hud.compact_labels.size()==3 and hud.stats_labels.size()==8,"Compact view has three fields; expanded view contains eight implemented stats")
 check(hud.health_label.text=="6/6" and hud.health_bar.value==6,"Life icon has exact numeric and bar values")
 game.player.take_damage(0.25)
 check(hud.health_label.text=="5.75/6" and hud.health_bar.value==5.75,"Fractional damage updates health without rounding it upward")
 var heal=game.spawn_pickup({"id":"crystal","position":Vector2(480,274),"reward_kind":"heal","collected":false})
 check(heal.claim() and hud.health_label.text=="6/6","Healing immediately updates HUD")
 game.coins=163
 game.keys=3
 game.update_counts()
 check(hud.coins_label.text=="163" and hud.keys_label.text=="3","HUD displays actual balance and keys without changing economy")
 check(not hud.coins_label.text.contains("Óbolos") and not hud.enemies_label.text.contains("Sombras"),"Long counter labels removed")
 check(hud.ICONS.coins!=hud.ICONS.keys and hud.ICONS.shadows!=hud.ICONS.coins,"Currencies and enemies have distinct original icons")
 check(hud.compact_labels.damage.text=="1.00" and hud.compact_labels.cadence.text=="2.80/s" and hud.compact_labels.speed.text=="185px/s","Compact numbers derive from real combat stats and units")
 check(hud.stats_labels.range.text=="540px" and hud.stats_labels.luck.text=="0.00" and hud.stats_labels.defense.text=="0.00","Full view contains real range luck and defense")
 check(hud.stats_labels.critical.text=="0%" and not hud.stats_labels.has("ability"),"Critical chance is actual zero for a fresh Errante")
 # Second finger can use stats while movement remains held.
 touch(0,game.controls.joystick_center()+Vector2(0,-20),true)
 tap(hud.stats_button)
 check(hud.view==1 and hud.detail.visible and game.controls.joystick_finger==0,"Independent touch expands stats while joystick remains held")
 touch(0,game.controls.joystick_center(),false)
 settings.values.stats_view=0
 settings.load_settings()
 check(settings.values.stats_view==1,"Stats view preference survives actual file reload")
 var dmg=game.spawn_pickup({"id":"crystal","position":Vector2(480,274),"collected":false})
 check(dmg.claim() and hud.stats_labels.damage.text=="1.35" and hud.compact_labels.damage.text=="1.35","Relic updates both stats panels immediately")
 check(hud.change_labels.damage.text=="+0.35" and hud.stats_labels.damage.get_theme_color("font_color").g>0.7,"Positive change is shown numerically and highlighted")
 game.player.stats.speed*=0.7
 hud.refresh_stats(game.player.stats)
 check(hud.stats_labels.speed.text=="129.5px/s" and hud.change_labels.speed.text.begins_with("-"),"Temporary negative modifiers update real numbers and delta")
 check(hud.stats_labels.speed.get_theme_color("font_color").r>hud.stats_labels.speed.get_theme_color("font_color").g,"Negative change highlighted red")
 hud.refresh_stats(game.player.stats,3.0)
 check(hud.change_labels.damage.text=="" and hud.change_labels.speed.text=="","Change indicators expire with bounded lifetime")
 game.position_notice()
 await process_frame
 check(not hud.detail.get_global_rect().intersects(game.toast.get_global_rect()),"Item notification does not overlap expanded stats")
 tap(hud.stats_button)
 check(hud.view==2 and not hud.compact.visible and not hud.detail.visible,"Stats can be hidden completely")
 tap(hud.stats_button)
 check(hud.view==0 and hud.compact.visible and not hud.detail.visible,"Stats button restores three-field view")
 # Settings write failure must not pretend to have saved the preference.
 var before: int=hud.view
 var errors: Array[bool]=[]
 hud.preference_failed.connect(func(): errors.append(true))
 DirAccess.make_dir_absolute(settings.PATH+".tmp")
 hud.cycle_view()
 check(hud.view==before and settings.values.stats_view==before and errors==[true],"Failed write rolls back view and reports failure")
 DirAccess.remove_absolute(settings.PATH+".tmp")
 # Resource updates remain connected to actual interactions.
 var key=game.spawn_pickup({"id":"crystal","position":Vector2(480,274),"reward_kind":"key","collected":false})
 check(key.claim() and hud.keys_label.text=="4","Collected key updates dedicated counter")
 var chest=game.spawn_pickup({"id":"ice","position":Vector2(480,274),"chest":true,"locked":true,"collected":false})
 game.player.position=chest.position+Vector2(65,0)
 chest.cooldown=0
 check(game.interact_with_pickup(chest) and hud.keys_label.text=="3","Opening locked chest deducts displayed keys exactly once")
 game.layout.current=8
 game.start_game(true)
 game.coins=100
 game.update_counts()
 var product: RelicPickup=game.pickups[0]
 var price: int=product.data.price
 check(game.purchase_pickup(product) and hud.coins_label.text==str(100-price),"Shop purchase immediately updates actual displayed money")
 # Every layout stays between physical doors and away from touch controls/map.
 for dimensions in [Vector2i(960,540),Vector2i(1280,540),Vector2i(960,600)]:
  root.size=dimensions
  await process_frame
  hud.layout_hud(1.25)
  if hud.view!=1: hud.view=1; hud.apply_view()
  await process_frame
  var rectangles: Array[Rect2]=[]
  for button: Button in [hud.pause_button,hud.stats_button,hud.doors_button]:
   var rect:=button.get_global_rect()
   check(rect.size.x>=44 and rect.size.y>=44 and rect.position.x>=0 and rect.end.x<game.dungeon_map.position.x,"HUD touch targets are large and avoid minimap")
   for previous: Rect2 in rectangles: check(not rect.intersects(previous),"HUD buttons do not overlap")
   rectangles.append(rect)
  var room_origin: Vector2=game.world.position
  for door: Vector2 in [Vector2(480,89),Vector2(890,274),Vector2(480,459),Vector2(70,274)]:
   check(not hud.detail.get_global_rect().intersects(Rect2(room_origin+door-Vector2(20,30),Vector2(40,50))),"Expanded panel leaves each physical door visible")
  check(hud.detail.get_global_rect().end.y<game.controls.joystick_center().y-65*1.25,"Expanded panel avoids largest touch controls")
 root.size=Vector2i(960,540)
 await process_frame
 tap(hud.pause_button)
 check(game.state=="paused" and not hud.detail.visible and not game.controls.enabled,"New pause icon preserves pause and hides statistics overlay")
 game.resume_game()
 check(hud.detail.visible and game.controls.enabled,"Resume restores chosen stats view and controls")
 tap(hud.doors_button)
 check(game.state=="doors","Door icon opens existing exploration interface")
 game.resume_game()
 game.show_main_menu()
 game.start_game()
 check(hud.change_labels.damage.text=="" and hud.stats_labels.damage.text=="1.00","New run resets upgrade indicators and real base stats")
 game.start_game()
 check(hud.enemies_label.text==str(game.enemies.size()),"Enemy icon counts actual enemies")
 var enemy: AbyssEnemy=game.enemies[0]
 enemy.take_damage(999)
 check(hud.enemies_label.text==str(game.enemies.size()),"Enemy count updates on death")
 game.expedition=true
 game.wave=2
 game.update_counts()
 check(hud.wave_cell.visible and hud.wave_label.text=="3/5","Expedition wave indicator is retained separately from enemy count")
 game.show_main_menu()
 check(not hud.visible,"Returning to menu hides gameplay panels")
 game.queue_free()
 await process_frame
 settings.values=original
 if existed:
  var file:=FileAccess.open(settings.PATH,FileAccess.WRITE)
  file.store_string(contents)
  file.close()
 else: DirAccess.remove_absolute(settings.PATH)
 print("HUD RESULT: %d checks, %d failures" % [checks,failures])
 await AudioTestCleanup.drain(self)
 quit(1 if failures else 0)
