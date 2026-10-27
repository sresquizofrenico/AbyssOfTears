extends SceneTree
var checks:=0
var failures:=0
var game
func _initialize() -> void: run.call_deferred()
func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func tap(button: Button, index: int=82) -> void:
 for down in [true,false]:
  var event:=InputEventScreenTouch.new()
  event.index=index
  event.position=button.get_global_rect().get_center()
  event.pressed=down
  root.push_input(event,true)
func buttons(node: Node, output: Array) -> void:
 if node is Button: output.append(node)
 for child in node.get_children(): buttons(child,output)
func named_button(text: String) -> Button:
 var all: Array=[]
 buttons(game.panel,all)
 for button: Button in all:
  if button.text==text: return button
 return null
func clear_enemies() -> void:
 for attempt in range(8):
  for enemy in game.enemies.duplicate():
   if is_instance_valid(enemy): enemy.take_damage(10000)
  if game.enemies.is_empty(): break
 for hazard in game.hazards:
  if is_instance_valid(hazard) and hazard.kind=="explosion": hazard._physics_process(2.0)
func resources() -> void:
 for pickup in game.pickups.duplicate():
  if is_instance_valid(pickup) and pickup is BondPickup: check(pickup.claim(),"Physical bond resource accepted exactly once")
func run() -> void:
 root.size=Vector2i(960,540)
 var progress=root.get_node("Progress")
 var old: Dictionary=progress.data.duplicate(true)
 var old_path: String=progress.storage_path
 progress.storage_path="user://nine-bonds-test.json"
 progress.data=progress.fresh()
 check(CharacterCatalog.DATA.size()==20 and BondCatalog.DATA.size()==9,"Twenty functional character definitions, nine additions")
 var ids: Dictionary={}
 var textures: Dictionary={}
 for entry: Dictionary in CharacterCatalog.DATA:
  check(not ids.has(entry.id),"Unique character ID")
  ids[entry.id]=true
  var stats:=CharacterCatalog.preview_stats(entry.id)
  check(stats!=null and stats.damage>0 and stats.attack_interval>0 and stats.health>0,"Usable stats for "+str(entry.id))
  if entry.id in BondCatalog.IDS:
   check(ResourceLoader.exists(entry.sprite) and ResourceLoader.exists(entry.icon),"Real original sprite and skill icon")
   check(not textures.has(entry.sprite),"New heroes have distinct silhouettes/resources")
   textures[entry.sprite]=true
   check(not progress.is_unlocked(entry.id),"New hero initially locked by real objectives")
 var original: Dictionary=progress.data.duplicate(true)
 check(progress.redeem("not-a-code")=="Código no reconocido" and progress.data==original,"Invalid code changes nothing")
 check(progress.redeem("  abismo-total ").begins_with("Acceso completo activado"),"Documented code redeems case-insensitively")
 for entry: Dictionary in CharacterCatalog.DATA: check(CharacterCatalog.playable(entry.id),"Code unlocks playable "+str(entry.id))
 for entry: Dictionary in RelicCatalog.DATA: check(RelicCatalog.available(entry.id),"Code unlocks relic eligibility")
 check(not progress.is_unlocked("not_real"),"Code cannot fabricate nonexistent characters")
 check(progress.data.counters==original.counters and progress.data.journal==original.journal and not progress.data.bonds.future_final,"Code never fabricates achievements or discoveries")
 original=progress.data.duplicate(true)
 check(progress.redeem("ABISMO-TOTAL").contains("ya está") and progress.data==original,"Repeated code is idempotent")
 progress.load_progress()
 check(progress.data.bonds.universal,"Code survives actual disk reload")
 var code: String=progress.export_code()
 check(code.begins_with("AOT4."),"Versioned portable backup contains code and bonds")
 progress.data=progress.fresh()
 check(progress.import_code(code) and progress.data.bonds.universal,"Code survives portable restore")
 original=progress.data.duplicate(true)
 progress.data=progress.fresh()
 var path: String=progress.storage_path
 progress.storage_path="user://missing-code-folder/progress.json"
 check(progress.redeem("ABISMO-TOTAL").begins_with("No se pudo") and not progress.data.bonds.universal,"Failed code save rolls back the unlock")
 progress.storage_path=path
 for version in [1,2,3]:
  var legacy: Dictionary=progress.fresh()
  legacy.version=version
  legacy.erase("bonds")
  legacy.unlocked=["neris","mira"]
  var restored: Dictionary=progress.validate(JSON.parse_string(JSON.stringify(legacy)))
  check(restored.version==4 and restored.unlocked.has("mira") and not restored.bonds.universal,"Old save migration preserves earned characters without granting cheat access")
 # Compound objective unlocks; no generic kill-total shortcuts.
 progress.data=progress.fresh()
 progress.data.counters.enemies=99999
 progress.evaluate()
 for id in BondCatalog.IDS: check(not progress.is_unlocked(id),"Kills alone do not unlock "+str(id))
 progress.discover({"maps":AbyssJournal.FLOOR_IDS,"secrets":["salt_crypt:1:0:1","salt_crypt:2:0:1","salt_crypt:3:0:1","salt_crypt:4:0:1","salt_crypt:5:0:1"]})
 var artifacts: Array=[]
 for i in range(10): artifacts.append(ArchaeologyCatalog.entries()[i].id)
 progress.discover({"artifacts":artifacts})
 check(progress.is_unlocked("lyra"),"Lyra requires maps, distinct secret routes and archaeology")
 progress.data=progress.fresh()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 var menu: AnimatedMainMenu=game.panel
 menu.skip_intro()
 menu.guard_time=0
 check(menu.buttons.has("codes"),"Codes is a visible main-menu action")
 tap(menu.buttons.codes)
 menu._process(0.3)
 check(game.state=="codes","Real touch opens the code screen")
 await process_frame
 await process_frame
 var input: LineEdit=game.panel.find_child("CodeInput",true,false)
 input.text="ABISMO-TOTAL"
 var submit:=named_button("APLICAR CÓDIGO")
 check(submit!=null and submit.size.y>=44,"Large touch redemption button")
 tap(submit)
 check(progress.data.bonds.universal,"Code button actually grants access")
 for dimensions in [Vector2i(960,540),Vector2i(1280,540),Vector2i(960,600)]:
  root.size=dimensions
  await process_frame
  check(game.panel.get_global_rect().position.y>=0 and game.panel.get_global_rect().end.y<=dimensions.y,"Code screen fits landscape displays")
 root.size=Vector2i(960,540)
 # Real abilities in the existing campaign, using the actual combat statistics.
 for id in BondCatalog.IDS:
  game.selected_character=id
  game.start_dungeon(1200)
  var p: AbyssPlayer=game.player
  check(game.use_character_ability() and not game.use_character_ability(),"Ability/cooldown executes for "+id)
  check(p.body_texture==CharacterCatalog.texture(id),"New sprite appears during gameplay")
  match id:
   "lyra":
    check(p.ability_active==8 and game.layout.room_hidden(game.layout.secret_room),"Lyra hints are temporary and never unlock all secrets")
    NineBonds.new_room(p)
    check(p.stats.speed>p.stats._speed,"Cartographic exploration grants a bounded mobility bonus")
   "kairon":
    game.spawn_enemy(0,p.position+p.facing*100)
    var target=game.enemies.back()
    var hp: float=target.health
    p.tick_ability(0.5)
    game.bonds.tick(0.016)
    check(target.health<hp and not p.character_state.beam_pending,"Prepared ray deals actual line damage")
    p.immunity=0
    p.take_damage(1,"acid")
    var hp_before: float=p.stats.health
    p.immunity=0
    p.take_damage(1,"acid")
    check(hp_before-p.stats.health<0.7,"Adaptive resistance reduces repeated elemental exposure")
   "nami":
    game.spawn_enemy(0,p.skill_origin+Vector2(30,0))
    game.bonds.tick(0.016)
    check(game.enemies.back().slowed>0,"Spore garden slows a real enemy")
    p.immunity=0
    var hp: float=p.stats.health
    p.take_damage(1)
    check(hp-p.stats.health<0.8 and p.character_state.bond_shield==0,"Garden protection has a consumed budget")
   "yura":
    p.velocity=Vector2(300,0)
    for i in range(3):
     game.spawn_enemy_bullet(p.position+Vector2(20,0),Vector2.LEFT)
     var bullet: AbyssProjectile=game.bullets.back()
     NineBonds.near_miss(p,bullet,20)
     NineBonds.near_miss(p,bullet,20)
    check(p.character_state.precision_charge,"Three different verified near misses charge Plan Perfecto")
    var before: int=game.bullets.size()
    game.spawn_player_bullet(p.position,Vector2.UP,p.stats)
    check(game.bullets.size()>before and not p.character_state.precision_charge,"Charged attack is consumed once")
   "aria":
    var origin: Vector2=p.skill_origin
    p.position+=Vector2(60,0)
    check(p.pursuit_point()==origin,"Aria's illusion changes the enemy's real pursuit target")
    NineBonds.room(p,true)
    check(p.stats.attack_interval<p.stats._attack_interval,"Clean-room leadership modifies actual fire rate")
   "beren":
    game.bonds.tick(0.016)
    check(not game.bonds.fields.is_empty(),"Beren leaves actual bounded flame fields")
    game.spawn_enemy(0,game.bonds.fields[0].point)
    game.bonds.tick(0.5)
    check(game.enemies.back().burning>0,"Flame trail applies real burn")
   "celine":
    game.spawn_enemy(1,p.position+Vector2(0,-100))
    var target=game.enemies.back()
    p.ability_remaining=0
    game.use_character_ability()
    check(target.marked>0,"Crystal Strategy marks actual enemies")
    for second in [1.0,2.0,3.0]:
     target.clock=second
     NineBonds.observed(p,target)
    check(NineBonds.hit_multiplier(p,target)>1,"Repeated observed attacks enable Tactical Memory")
   "dalia":
    p.tick_ability(0.4)
    game.bonds.tick(0.016)
    check(game.bonds.fields.size()==1 and p.character_state.ward_near,"Dalia creates one protective zone after displacement")
    p.immunity=0
    var hp: float=p.stats.health
    p.take_damage(2)
    check(hp-p.stats.health<2 and p.character_state.field_budget==0,"Protective zone cannot block unlimited damage")
    game.bonds.tick(5)
    game.bonds.tick(5)
    check(game.bonds.fields.is_empty(),"Expired zone does not regenerate endlessly")
   "elora":
    game.spawn_enemy(0,p.position+Vector2(30,0))
    var target=game.enemies.back()
    p.take_damage(2)
    check(p.character_state.blocked==2,"Protective oath records bounded blocked damage")
    var hp: float=target.health
    p.tick_ability(5)
    game.bonds.tick(0.016)
    check(target.health<hp and not p.character_state.counter_pending,"Oath releases a real single counterattack")
 # Engineering: collect six actual component types and repair four machines.
 progress.data=progress.fresh()
 game.selected_character="neris"
 check(game.start_bond_challenge("engineering"),"All characters can enter engineering")
 resources()
 check(progress.data.bonds.sets.components.size()==6,"Actual pickups register six different components")
 for station in game.bonds.stations:
  game.player.position=station.point
  game.bonds.refresh_panel()
  tap(game.bonds.action)
 check(progress.data.bonds.sets.machines.size()==4 and not progress.is_unlocked("kairon"),"Four repairs do not bypass the room-completion objective")
 game.clear_wave()
 check(game.state=="victory" and progress.is_unlocked("kairon"),"Completing the actual engineering room unlocks Kairon")
 check(not game.start_bond_challenge("ecology",4),"Invalid challenge variants are safely rejected")
 # Ecology: real materials, crafting, consumption, protection and clean variants.
 for attempt in range(5):
  game.start_bond_challenge("ecology",attempt%3)
  resources()
  game.player.position=game.bonds.stations[0].point
  game.bonds.refresh_panel()
  game.bonds.interact()
  check(game.player.character_state.antidotes==1,"Crafting consumes gathered biomass")
  game.bonds.interact()
  var hp: float=game.player.stats.health
  game.player.take_damage(1,"acid")
  check(game.player.stats.health==hp and game.player.character_state.antidotes==0,"Consumed antidote actually prevents environmental damage")
  game.bonds.timer=0
  clear_enemies()
  game.clear_wave()
  check(game.state=="victory","Contamination encounter is completable")
 check(progress.data.bonds.antidotes==5 and progress.data.bonds.sets.clean_contaminated.size()==3,"Five genuine crafts and three clean variants persist")
 # Three memory theaters, three timed races, five circuits and five tactical rooms.
 for kind in ["theater","race","circuit","tactics","endurance"]:
  var count:=3 if kind in ["theater","race"] else 5
  for variant in range(count):
   game.start_bond_challenge(kind,variant)
   if kind in ["theater","tactics"]:
    game.bonds.show_puzzle()
    game.bonds.answer_puzzle(false)
    check(not game.bonds.solved,"Incorrect puzzle answer grants no completion")
    game.bonds.show_puzzle()
    game.bonds.answer_puzzle(true)
   if kind in ["race","circuit"]:
    for point: Vector2 in game.bonds.checkpoints:
     game.player.position=point
     game.bonds.tick(0.01)
   if kind=="tactics":
    for enemy in game.enemies:
     if not enemy is TideWarden: progress.record_bond("weaknesses",enemy.definition.id)
   if kind=="theater" and variant==1:
    for pickup in game.pickups:
     if not pickup is BondPickup:
      pickup.data.chest=false
      pickup.claim()
   if kind=="theater" and variant==2: game.player.position=Vector2(260,190)
   if kind=="endurance": game.bonds.timer=0
   clear_enemies()
   game.clear_wave()
   check(game.state=="victory","Completable challenge: %s %d" % [kind,variant])
 check(progress.is_unlocked("aria") and progress.is_unlocked("beren") and progress.is_unlocked("dalia") and progress.is_unlocked("elora") and progress.is_unlocked("celine"),"Sister unlocks follow their separate mechanics")
 # Future Fractured: fragments, real puzzles, four clean encounters and special boss.
 game.start_bond_challenge("future")
 for stage in range(5):
  check(game.bonds.stage==stage,"Temporal chain progresses exactly once")
  resources()
  if stage!=3:
   game.bonds.show_puzzle()
   game.bonds.answer_puzzle(true)
  clear_enemies()
  game.clear_wave()
 check(game.state=="victory" and progress.is_unlocked("yura"),"Complete five-stage future challenge unlocks Yura naturally")
 check(progress.data.bonds.sets.fragments.size()==5 and progress.data.bonds.sets.future_clean.size()==4,"Temporal achievements reflect distinct actual stages")
 check(game.start_bond_challenge("family"),"Five unlocked sisters open single-player constellation")
 game.bonds.tick(1.6)
 check(game.bullets.size()<=game.MAX_BULLETS,"Friendly constellation fire respects global projectile budget")
 clear_enemies()
 game.clear_wave()
 check(progress.data.bonds.family_done,"Family challenge gives its permanent exclusive reward")
 game.selected_character="aria"
 game.start_dungeon(1201)
 check(game.player.character_state.family_ward==1,"Constellation reward gives one bounded starting barrier")
 game.player.relics.add("boots",game.player.stats)
 game.player.relics.add("mirror",game.player.stats)
 game.player.ability_remaining=0
 check(game.use_character_ability() and game.player.ability_active>4,"Sister resonance changes actual ability duration")
 # Field integration remains optional and does not change campaign topology.
 game.layout.current=9
 game.start_game(true)
 check(game.bonds.mode=="field" and not game.bonds.stations.is_empty(),"Actual campaign special room contains exploration workshops")
 check(game.layout.rooms.size()==12 and FloorLayout.BIOMES.size()==3,"Existing campaign preserved")
 game.show_main_menu()
 game.show_bond_hub()
 await process_frame
 check(game.panel.get_global_rect().end.y<=540,"Challenge hub fits Android landscape")
 game.queue_free()
 await process_frame
 await preload("res://tests/audio_test_cleanup.gd").drain(self)
 progress.data=old
 progress.storage_path=old_path
 print("NINE BONDS RESULT: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
