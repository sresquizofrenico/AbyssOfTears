extends Node

const GUARDIAN = preload("res://scenes/bosses/tide_warden.tscn")
var props: Array[RoomProp] = []
var keys := 0
var door_cooldown := 0.0
var boss_panel: VBoxContainer
var boss_name: Label
var boss_bar: ProgressBar

const MAIN_MENU = preload("res://scenes/ui/main_menu.tscn")
var menu_intro_seen := false
var trial_kind: String=""
var trial_stage:=0
var lab_page:=0
var lab_mode:=false
var selected_character := "neris"
const CHARACTER_SELECTION = preload("res://scenes/ui/character_selection.tscn")

const PLAYER = preload("res://scenes/player/player.tscn")
const ENEMY = preload("res://scenes/enemies/enemy.tscn")
const CHAMBER = preload("res://scenes/rooms/chamber.tscn")
const BULLET = preload("res://scripts/combat/projectile.gd")
const DOOR_ART = preload("res://assets/illustrated/door.svg")
const MAX_BULLETS := 96
const MAX_ENEMIES := 16
const MAX_HAZARDS := 10
var dungeon_mode := false
var layout := FloorLayout.new()
var dungeon_seed := 0
var loot_rng:=RandomNumberGenerator.new()
var transitioning := false
var dungeon_map: DungeonMap
var floor_label: Label
var navigation: Button
var expedition := false
var wave := 0
var state := "menu"
var world: Node2D
var chamber: Node2D
var player: AbyssPlayer
var enemies: Array[AbyssEnemy] = []
var bullets: Array[AbyssProjectile] = []
var controls: TouchControls
var ui: Control
var panel: PanelContainer
var hud: CompactHUD
var health_label: Label
var health_bar: ProgressBar
var coins_label: Label
var enemies_label: Label
var coins := 0
var hazards: Array[EnemyHazard] = []
var pickups: Array[RelicPickup] = []
var room_pickups: Array = []
var backdrop: MenuBackdrop
var toast: HBoxContainer
var toast_label: Label
var toast_icon: TextureRect
var toast_timer := 0.0
var diagnostics: Label
var diagnostic_timer := 0.0
var sparks: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var effect_layer: Node2D
var options_return := "menu"
var controls_return: String="menu"
var progress: Node
var character_audio: AudioStreamPlayer
var pickup_interaction: PickupInteraction
var diary_return: String="archive"
var journal_queued:=false
var bonds: BondsArena

func _ready() -> void:
 get_tree().quit_on_go_back = false
 progress=CharacterCatalog.progress_node()
 character_audio=AudioStreamPlayer.new()
 character_audio.bus="AbyssSFX"
 character_audio.volume_db=-14
 add_child(character_audio)
 progress.character_unlocked.connect(func(id: String):
  character_audio.stop()
  character_audio.stream=CharacterSounds.unlock_sound()
  character_audio.play()
  if is_instance_valid(toast): show_notice("Nuevo viajero: "+str(CharacterCatalog.definition(id).name),preload("res://assets/ui/stats.svg")))
 progress.save_failed.connect(func(_error: Error):
  if is_instance_valid(toast): show_notice("No se pudo guardar el progreso",preload("res://assets/ui/stats.svg")))
 backdrop = MenuBackdrop.new()
 add_child(backdrop)
 var canvas := CanvasLayer.new()
 add_child(canvas)
 ui = Control.new()
 ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
 canvas.add_child(ui)
 controls = TouchControls.new()
 controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 controls.ability_requested.connect(use_character_ability)
 controls.item_requested.connect(use_active_item)
 controls.awaken_requested.connect(use_shader_awaken)
 ui.add_child(controls)
 get_viewport().size_changed.connect(resize_world)
 build_hud()
 dungeon_map = DungeonMap.new()
 dungeon_map.size = Vector2(150,110)
 dungeon_map.set_anchors_preset(Control.PRESET_TOP_RIGHT)
 dungeon_map.position = Vector2(ui.size.x-160,6)
 ui.add_child(dungeon_map)
 floor_label = label("",12)
 floor_label.position = Vector2(548,12)
 floor_label.size = Vector2(240,22)
 floor_label.clip_text=true
 floor_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 floor_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui.add_child(floor_label)
 navigation=hud.doors_button
 build_relic_ui()
 pickup_interaction=PickupInteraction.new()
 ui.add_child(pickup_interaction)
 pickup_interaction.interact_requested.connect(interact_with_pickup)
 boss_panel=VBoxContainer.new()
 boss_panel.position=Vector2(330,76)
 boss_name=label("Custodio de la Marea",16)
 boss_bar=ProgressBar.new()
 boss_bar.custom_minimum_size=Vector2(300,12)
 boss_bar.show_percentage=false
 var boss_fill:=StyleBoxFlat.new()
 boss_fill.bg_color=Color("a9a4df")
 boss_fill.set_corner_radius_all(4)
 boss_bar.add_theme_stylebox_override("fill",boss_fill)
 boss_panel.add_child(boss_name)
 boss_panel.add_child(boss_bar)
 ui.add_child(boss_panel)
 boss_panel.hide()
 show_main_menu()

func resize_world() -> void:
 if is_instance_valid(hud): hud.layout_hud()
 if is_instance_valid(pickup_interaction): position_pickup_interaction()
 if is_instance_valid(dungeon_map): dungeon_map.position.x = get_viewport().get_visible_rect().size.x-160
 if is_instance_valid(world):
  world.position = (get_viewport().get_visible_rect().size - Vector2(960,540)) * 0.5

func build_hud() -> void:
 hud=CompactHUD.new()
 ui.add_child(hud)
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud.pause_requested.connect(pause_game)
 hud.doors_requested.connect(show_doors)
 hud.preference_failed.connect(func(): show_notice("No se pudo guardar la vista de estadísticas",preload("res://assets/ui/stats.svg")))
 health_label=hud.health_label
 health_bar=hud.health_bar
 coins_label=hud.coins_label
 enemies_label=hud.enemies_label
 hud.hide()

func label(text: String, font_size: int = 20) -> Label:
 var node := Label.new()
 node.text = text
 node.add_theme_font_size_override("font_size", font_size)
 node.add_theme_color_override("font_color", Color("d5f6ee"))
 return node

func button(text: String, action: Callable) -> Button:
 var node := AbyssTouchButton.new()
 node.text = text
 node.custom_minimum_size = Vector2(260, 46)
 node.add_theme_font_size_override("font_size", 20)
 for variation in ["normal","hover","pressed"]:
  var style := StyleBoxFlat.new()
  style.bg_color = Color("223c4c") if variation == "pressed" else Color("1b3244") if variation == "hover" else Color("182c3b")
  style.border_color = Color("7aada8") if variation == "pressed" else Color("365765")
  style.set_border_width_all(1)
  style.set_corner_radius_all(7)
  node.add_theme_stylebox_override(variation,style)
 node.pressed.connect(func(): Soundscape.play_effect("ui"))
 node.pressed.connect(action)
 return node

func clear_panel() -> void:
 if is_instance_valid(panel):
  if panel is AnimatedMainMenu: panel.deactivate()
  ui.remove_child(panel)
  panel.queue_free()
 panel = null

func menu(title: String, subtitle: String) -> VBoxContainer:
 clear_panel()
 panel = PanelContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
 panel.grow_vertical = Control.GROW_DIRECTION_BOTH
 var style := StyleBoxFlat.new()
 style.bg_color = Color("142639")
 style.border_color = Color("527c83")
 style.set_border_width_all(2)
 style.set_corner_radius_all(18)
 style.content_margin_left = 30
 style.content_margin_right = 30
 style.content_margin_top = 18
 style.content_margin_bottom = 18
 panel.add_theme_stylebox_override("panel", style)
 ui.add_child(panel)
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation", 10)
 panel.add_child(box)
 var heading := label(title, 30)
 heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 box.add_child(heading)
 var caption := label(subtitle, 16)
 caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 box.add_child(caption)
 return box

func show_main_menu() -> void:
 backdrop.show()
 state = "menu"
 trial_kind=""
 lab_mode=false
 expedition = false
 dungeon_mode = false
 dungeon_map.hide()
 floor_label.hide()
 navigation.hide()
 if is_instance_valid(toast): toast.hide()
 if is_instance_valid(diagnostics): diagnostics.hide()
 boss_panel.hide()
 controls.set_enabled(false)
 hud.set_playing(false)
 hud.hide()
 dispose_world()
 clear_panel()
 var main_menu: AnimatedMainMenu = MAIN_MENU.instantiate()
 main_menu.stage = backdrop
 main_menu.play_intro = not menu_intro_seen
 menu_intro_seen = true
 panel = main_menu
 ui.add_child(main_menu)
 main_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 main_menu.action_requested.connect(on_menu_action)

func on_menu_action(action: String) -> void:
 if state != "menu": return
 Soundscape.play_effect("ui")
 match action:
  "new_game": show_character_selection()
  "options": show_options("menu")
  "codes": show_codes()
  "credits": show_credits()
  "modes": show_modes()
  "exit": quit_game()

func quit_game() -> void:
 if state=="closing": return
 state="closing"
 controls.set_enabled(false)
 Soundscape.stop_all()
 character_audio.stop()
 character_audio.stream=null
 # Let the audio server release stopped decoder buffers before engine teardown.
 await get_tree().create_timer(0.25).timeout
 get_tree().quit()

func show_character_selection() -> void:
 state = "character_selection"
 clear_panel()
 backdrop.hide()
 var selection: CharacterSelection = CHARACTER_SELECTION.instantiate()
 panel = selection
 ui.add_child(selection)
 selection.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 selection.back_requested.connect(show_main_menu)
 selection.begin_requested.connect(begin_character_run)
 selection.trial_requested.connect(func(): start_trial("shader"))

func begin_character_run(id: String) -> bool:
 if state != "character_selection" or not CharacterCatalog.playable(id): return false
 selected_character = id
 return start_dungeon()

func show_modes() -> void:
 state = "modes"
 var box := menu("Otros caminos", "Modos, pruebas y desafíos de los viajeros")
 var scroll:=ScrollContainer.new()
 scroll.custom_minimum_size=Vector2(570,280)
 box.add_child(scroll)
 var list:=VBoxContainer.new()
 list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 list.add_theme_constant_override("separation",8)
 scroll.add_child(list)
 list.add_child(button("Mazmorra · 3 pisos",start_dungeon))
 list.add_child(button("Vínculos del Abismo",show_bond_hub))
 list.add_child(button("Elegir semilla",show_seed_menu))
 list.add_child(button("Incursión de enemigos",func(): expedition=true; wave=0; start_game()))
 list.add_child(button("Prueba de reliquias",start_relic_room))
 list.add_child(button("Muestra ilustrada",start_art_sample))
 list.add_child(button("Prueba de Ilusiones",func(): start_trial("illusion")))
 box.add_child(button("Volver",show_main_menu))

func start_art_sample() -> void:
 dungeon_mode=false
 expedition=false
 start_game()
 for enemy: AbyssEnemy in enemies:
  enemy.set_physics_process(false)
  enemy.queue_free()
 enemies.clear()
 spawn_enemy(0,Vector2(720,170))
 spawn_pickup({"id":"shield","position":Vector2(600,290),"collected":false,"chest":true})
 floor_label.text="Muestra ilustrada · Recoge el cristal y prueba el combate"
 floor_label.show()
 update_counts()

func dispose_world() -> void:
 if is_instance_valid(pickup_interaction):
  pickup_interaction.hide()
  pickup_interaction.target=null
 if is_instance_valid(world):
  remove_child(world)
  world.queue_free()
 world = null
 effect_layer = null
 enemies.clear()
 bullets.clear()
 effects.clear()
 sparks.clear()
 pickups.clear()
 room_pickups = []
 hazards.clear()
 props.clear()
 if is_instance_valid(boss_panel): boss_panel.hide()

func start_game(keep_progress: bool = false) -> void:
 if keep_progress: Soundscape.play_effect("door")
 backdrop.hide()
 var carried_ability: Dictionary = player.ability_snapshot() if keep_progress and is_instance_valid(player) else {}
 var carried_relics: RelicInventory = player.relics if keep_progress and is_instance_valid(player) else null
 var carried: ActorStats = player.stats if keep_progress and is_instance_valid(player) else null
 if is_instance_valid(toast): toast.hide()
 toast_timer=0.0
 var carried_coins := coins if keep_progress else 0
 var carried_keys := keys if keep_progress else 0
 clear_panel()
 dispose_world()
 state = "playing"
 if not keep_progress: loot_rng.seed=dungeon_seed+45271 if dungeon_mode else 45271
 coins = carried_coins
 keys = carried_keys
 door_cooldown = 0.0
 wave = 0
 world = Node2D.new()
 add_child(world)
 resize_world()
 chamber = CHAMBER.instantiate()
 chamber.quality = Settings.values.quality
 chamber.biome = layout.floor_index if dungeon_mode else 0
 if dungeon_mode: chamber.blueprint=RoomBlueprint.create(dungeon_seed,layout.floor_index,layout.current,layout.rooms[layout.current].kind)
 world.add_child(chamber)
 player = PLAYER.instantiate()
 if carried != null: player.stats = carried
 else: player.stats = CharacterCatalog.initial_stats(selected_character)
 player.configure_character(selected_character)
 controls.ability_icon=CharacterCatalog.ability_icon(selected_character)
 controls.ability_name=CharacterCatalog.definition(selected_character).ability
 if not carried_ability.is_empty(): player.restore_ability(carried_ability)
 player.character_state.near_ids.clear()
 player.character_state.observation_time.clear()
 if dungeon_mode and player.character_state.memory_floor!=layout.floor_index:
  player.character_state.observed.clear()
  player.character_state.memory_floor=layout.floor_index
 if carried_relics != null: player.relics = carried_relics
 else: player.relics.effects.rng.seed=dungeon_seed+7927
 player.position = Vector2(480, 390)
 player.controls = controls
 player.shot.connect(spawn_player_bullet)
 player.health_changed.connect(update_health)
 player.damaged.connect(func():
  Soundscape.play_effect("hurt")
  if is_instance_valid(bonds): bonds.note_damage(player.latest_hit_source)
  if dungeon_mode: layout.rooms[layout.current].damaged=true
  player.relics.effects.event("hurt",player,self))
 player.died.connect(func(): finish(false))
 world.add_child(player)
 bonds=BondsArena.new()
 bonds.game=self
 world.add_child(bonds)
 player.bond_arena=bonds
 bonds.antidote_time=float(player.character_state.antidote_time)
 if dungeon_mode:
  RoomContent.prepare(layout,player.relics.owned,progress.data.journal.artifacts)
  populate_room()
 elif trial_kind!="":
  spawn_trial_stage()
 elif expedition:
  spawn_wave()
 else:
  for entry in [[0, Vector2(150,140)], [0, Vector2(800,140)], [1, Vector2(480,120)], [1, Vector2(820,300)], [2, Vector2(140,330)], [2, Vector2(480,250)]]:
   spawn_enemy(entry[0],entry[1])
 effect_layer = Node2D.new()
 world.add_child(effect_layer)
 effect_layer.draw.connect(draw_effects)
 apply_controls()
 sync_control_state()
 controls.set_enabled(true)
 hud.show()
 hud.bind_stats(player.stats)
 hud.set_playing(true)
 hud.layout_hud(Settings.values.control_scale)
 update_health(player.stats.health, player.stats.max_health)
 update_counts()
 if dungeon_mode:
  chamber.modulate = Color.WHITE
  dungeon_map.layout = layout
  dungeon_map.show()
  dungeon_map.queue_redraw()
  floor_label.text = "P%d/3 · %s" % [layout.floor_index+1,FloorLayout.BIOMES[layout.floor_index]]
  floor_label.show()
  navigation.show()
  reward_room()
 if dungeon_mode:
  room_pickups = layout.rooms[layout.current].get("pickups",[])
  layout.rooms[layout.current].pickups = room_pickups
 else:
  room_pickups = []
 if dungeon_mode and layout.expanded: build_room_features()
 for data: Dictionary in room_pickups:
  if not data.get("collected",false): spawn_pickup(data)
 if not dungeon_mode and not expedition and trial_kind=="":
  spawn_pickup({"id":"crystal","position":Vector2(480,330),"collected":false,"chest":false})
 if dungeon_mode and layout.expanded:
  var kind: String=layout.rooms[layout.current].kind
  floor_label.text += {"shop":" · Tienda","special":" · Palanca y fuente","secret":" · Cámara secreta","boss":" · Custodio"}.get(kind,"")
  if kind=="start": show_notice("Una llave espera en el pedestal",RelicPickup.KEY)
 update_keys()
 transitioning = false
 if dungeon_mode:
  bonds.setup_field()
  if not carried_ability.is_empty():
   if not layout.rooms[layout.current].get("bond_visited",false): NineBonds.new_room(player)
  layout.rooms[layout.current].bond_visited=true
 observe_journal_room()

func observe_journal_room() -> void:
 journal_queued=false
 if not dungeon_mode or lab_mode or state!="playing" or not is_instance_valid(world) or layout.rooms.is_empty(): return
 layout.rooms[layout.current].visited=true
 progress.discover(AbyssJournal.room_observations(layout,enemies))

func queue_journal_observation() -> void:
 if journal_queued or not dungeon_mode or lab_mode: return
 journal_queued=true
 observe_journal_room.call_deferred()

func apply_controls() -> void:
 if is_instance_valid(player): player.quality=Settings.values.quality
 controls.configure(Settings.values)
 hud.left_handed=controls.left_handed
 hud.layout_hud(Settings.values.control_scale)
 sync_control_exclusions()

func update_health(current: float, maximum: float) -> void:
 if is_instance_valid(bonds): bonds.note_health(current)
 hud.set_health(current,maximum)
 if is_instance_valid(player): hud.refresh_stats(player.stats)

func update_counts() -> void:
 hud.set_counts(coins,keys,enemies.size(),wave if expedition else -1)
 if is_instance_valid(player): hud.refresh_stats(player.stats)

func spawn_player_bullet(origin: Vector2, direction: Vector2, stats: ActorStats) -> void:
 Soundscape.play_effect("shoot")
 var precision_power:=1.25 if player.character_state.precision_charge else 1.0
 player.character_state.precision_charge=false
 var inventory := player.relics
 var packet:=inventory.effects.packet(player)
 var directions: Array[Vector2] = [direction]
 if inventory.has("crown") or int(packet.fan)>0:
  directions.append(direction.rotated(-0.25))
  directions.append(direction.rotated(0.25))
 var origins: Array[Vector2] = [origin]
 if inventory.has("double"): origins = [origin-direction.orthogonal()*7,origin+direction.orthogonal()*7]
 for extra in range(int(packet.extra)): origins.append(origin+direction.orthogonal()*(14+extra*8))
 var echoes: Array[Vector2] = [Vector2.ZERO]
 if inventory.mirror_active() or inventory.effects.echo_time>0 or (player.character_id=="mira" and player.ability_active>0): echoes.append(Vector2(40,0))
 var shot_budget:=12
 for echo in echoes:
  for at in origins:
   for aim in directions:
    if shot_budget<=0: return
    shot_budget-=1
    var before := bullets.size()
    var echo_power:=1.0 if echo==Vector2.ZERO or inventory.mirror_active() else maxf(inventory.effects.echo_power,0.45)
    var extra_power:=0.8 if int(packet.extra)>0 else 1.0
    spawn_bullet(at+echo,aim,stats.projectile_speed*clampf(float(packet.velocity),0.5,1.5),stats.damage*float(packet.power)*echo_power*extra_power*precision_power,stats.attack_range+float(packet.reach),false)
    if bullets.size() > before:
     var bullet: AbyssProjectile = bullets.back()
     bullet.pierce = mini(4,(1 if inventory.has("pierce") else 0)+int(packet.pierce)+(1 if player.awakened>0 else 0))
     bullet.bounces = mini(2,(1 if inventory.has("bounce") else 0)+int(packet.bounce))
     bullet.homing=packet.homing>0
     bullet.returning=packet["return"]>0
     bullet.split=int(packet.split)
     bullet.explosion=float(packet.explode)
     bullet.push=float(packet.push)
     bullet.marking=packet.mark>0
     bullet.far_bonus=float(packet.far)
     bullet.critical=packet.critical
     for element: String in packet.elements:
      if not bullet.elements.has(element): bullet.elements.append(element)
     for element in ["fire","ice","electric","poison"]:
      if (inventory.has(element) or (player.character_id=="solen" and element=="fire" and player.relics.effects.rng.randf()<0.35) or (player.character_id=="vex" and player.ability_active>0 and element==["fire","ice","electric","poison"][player.mixture])) and not bullet.elements.has(element): bullet.elements.append(element)

func spawn_enemy_bullet(origin: Vector2, direction: Vector2) -> void:
 spawn_bullet(origin, direction, 190.0, 1.0, 720.0, true)

func spawn_bullet(origin: Vector2, direction: Vector2, speed: float, damage: float, distance: float, hostile: bool) -> void:
 if state != "playing" or bullets.size() >= MAX_BULLETS: return
 var bullet := BULLET.new()
 bullet.position = origin
 bullet.direction = direction.normalized()
 bullet.speed = speed
 bullet.damage = damage
 bullet.remaining = distance
 bullet.hostile = hostile
 world.add_child(bullet)
 bullets.append(bullet)

func _physics_process(delta: float) -> void:
 if state != "playing": return
 if player.character_state.windup>0:
  player.character_state.windup=maxf(0,float(player.character_state.windup)-delta)
  if player.character_state.windup<=0: spawn_rupture()
 if is_instance_valid(bonds): bonds.tick(delta)
 sync_control_state()
 controls.queue_redraw()
 door_cooldown=maxf(0,door_cooldown-delta)
 hud.refresh_stats(player.stats,delta)
 position_notice()
 update_relic_ui(delta)
 update_pickup_interaction()
 for i in range(hazards.size()-1,-1,-1):
  if not is_instance_valid(hazards[i]): hazards.remove_at(i)
 var targets := enemies.duplicate()
 var has_props := not props.is_empty()
 for i in range(bullets.size()-1, -1, -1):
  var bullet := bullets[i]
  if not is_instance_valid(bullet) or bullet.expired:
   bullets.remove_at(i)
   continue
  var old := bullet.position
  if bullet.homing and not bullet.hostile:
   var closest: AbyssEnemy
   var distance:=300.0
   for enemy: AbyssEnemy in targets:
    if is_instance_valid(enemy) and not enemy.dead and bullet.position.distance_to(enemy.position)<distance:
     closest=enemy
     distance=bullet.position.distance_to(enemy.position)
   if closest: bullet.direction=bullet.direction.lerp((closest.position-bullet.position).normalized(),minf(0.2,delta*2.0)).normalized()
  bullet.advance(delta*(player.relics.effects.hostile_scale if bullet.hostile and player.relics.effects.hostile_time>0 else 1.0))
  # Sample travel at <= 5 px so fast bullets cannot pass through pillars/walls.
  var steps := maxi(1, ceili(old.distance_to(bullet.position) / 5.0))
  for step in range(1, steps + 1):
   var point := old.lerp(bullet.position, float(step) / steps)
   if has_props and strike_prop(point,bullet): break
   if projectile_blocked(point):
    if not bullet.hostile: reveal_secret_wall(point)
    if bullet.bounces>0:
     bullet.bounces -= 1
     var x_blocked := projectile_blocked(Vector2(point.x,old.y))
     var y_blocked := projectile_blocked(Vector2(old.x,point.y))
     if x_blocked: bullet.direction.x *= -1
     if y_blocked: bullet.direction.y *= -1
     if not x_blocked and not y_blocked: bullet.direction *= -1
     bullet.position = old
    else: bullet.expire()
    break
   if bullet.hostile:
    if player.relics.has("orbital") and point.distance_to(player.relics.orbital_point(player.position))<14:
     bullet.expire()
     break
    CharacterRules.near_miss(player,point.distance_to(player.position))
    NineBonds.near_miss(player,bullet,point.distance_to(player.position))
    if point.distance_to(player.position) < 18:
     player.take_damage(bullet.damage)
     bullet.expire()
     break
   else:
    for enemy in targets:
     if is_instance_valid(enemy) and not enemy.dead and not bullet.hits.has(enemy.get_instance_id()) and point.distance_to(enemy.position) < enemy.hit_radius:
      bullet.hits[enemy.get_instance_id()] = true
      apply_relic_hit(bullet,enemy)
      if bullet.pierce>0: bullet.pierce -= 1
      else: bullet.expire()
      break
   if bullet.expired or state != "playing": break
  if bullet.expired:
   bullets.remove_at(i)
  if state != "playing": return
 for i in range(effects.size()-1, -1, -1):
  effects[i].life -= delta
  if effects[i].life <= 0: effects.remove_at(i)
 if is_instance_valid(effect_layer): effect_layer.queue_redraw()
 if enemies.is_empty(): clear_wave()
 if dungeon_mode and not transitioning and layout.rooms[layout.current].cleared:
  check_doors()

func on_enemy_defeated(enemy: AbyssEnemy, point: Vector2, _reward: int) -> void:
 if state!="playing" or not is_instance_valid(enemy) or not enemies.has(enemy) or not enemy.dead: return
 enemies.erase(enemy) # Membership is consumed before any reentrant reward callback.
 Soundscape.play_effect("enemy")
 player.relics.effects.event("kill",player,self)
 CharacterRules.killed(player)
 NineBonds.killed(player,enemy)
 if dungeon_mode and enemy.rank=="miniboss" and not layout.rooms[layout.current].get("miniboss_rewarded",false):
  layout.rooms[layout.current].miniboss_rewarded=true
  var reward: Dictionary={"id":RelicCatalog.roll(loot_rng,layout.floor_index,"boss"),"position":point,"collected":false,"chest":false}
  room_pickups.append(reward)
  spawn_pickup(reward)
 if dungeon_mode and not enemy.weak:
  record_progress("enemy",str(enemy.get_instance_id()))
  if enemy is TideWarden:
   var elemental:=player.relics.has("fire") or player.relics.has("ice") or player.relics.has("electric")
   record_progress("boss","guardian",{"elemental":elemental,"boss_id":enemy.definition.id})
   player.add_determination(25)
  elif enemy.rank=="elite":
   record_progress("elite",str(enemy.get_instance_id()))
   player.add_determination(8)
  elif enemy.rank=="miniboss":
   record_progress("miniboss",str(enemy.get_instance_id()))
   player.add_determination(12)
 if not enemy is TideWarden:
  var amount:=Economy.enemy_coin(loot_rng,enemy.kind,enemy.weak,enemy.rank in ["elite","miniboss"])
  if amount>0:
   var data:=Economy.coin_data(amount,point)
   room_pickups.append(data)
   spawn_pickup(data)
 if Settings.values.quality > 0 and effects.size() < 16:
  effects.append({"point": point, "life": 0.45, "kind":enemy.kind})
 update_counts()
 if enemies.is_empty() and state == "playing":
  # Defer so damage and projectile cleanup can finish safely.
  clear_wave.call_deferred()

func draw_effects() -> void:
 for spark in sparks:
  effect_layer.draw_line(spark.from,spark.to,Color(0.8,0.75,1,spark.life/0.18),2)
 if dungeon_mode:
  var room: Dictionary = layout.rooms[layout.current]
  if room.kind in ["treasure","descent"]:
   var color := Color("f2d39a") if room.kind == "treasure" else Color("bca9e6")
   effect_layer.draw_arc(Vector2(480,274),32,0,TAU,32,color,3)
   if room.kind == "descent":
    for i in range(3): effect_layer.draw_line(Vector2(460,260+i*12),Vector2(500,260+i*12),color,3)
   else: effect_layer.draw_colored_polygon(PackedVector2Array([Vector2(480,250),Vector2(498,274),Vector2(480,298),Vector2(462,274)]),Color(color,0.4))
  for neighbor: int in layout.rooms[layout.current].links:
   if layout.room_hidden(neighbor):
    var crack := door_point(neighbor)
    effect_layer.draw_line(crack-Vector2(4,10),crack+Vector2(4,10),Color("53616b"),2)
    continue
   var point := door_point(neighbor)
   var open: bool = layout.rooms[layout.current].cleared
   effect_layer.draw_texture_rect(DOOR_ART,Rect2(point-Vector2(20,30),Vector2(40,50)),false,Color.WHITE if open else Color(0.7,0.5,0.6))
   if layout.rooms[neighbor].get("locked",false): effect_layer.draw_texture_rect(RelicPickup.KEY,Rect2(point-Vector2(10,10),Vector2(20,20)),false)
   if not open: effect_layer.draw_line(point-Vector2(15,0),point+Vector2(15,0),Color("ba8b8e"),4)
 for effect in effects:
  var t: float = 1.0 - effect.life / 0.45
  if effect.has("kind"):
   effect_layer.draw_texture_rect(EnemyArt.TEXTURES[int(effect.kind)],Rect2(effect.point-Vector2(27,32+t*16),Vector2(54,54)),false,Color(1,1,1,(1-t)*0.6))
  var count := 6 if Settings.values.quality == 1 else 12
  for i in range(count):
   var offset := Vector2.from_angle(float(i) * TAU / count) * t * 35
   effect_layer.draw_circle(effect.point + offset, 3 * (1-t), Color(0.6,0.95,0.87,1-t))

func set_world_active(active: bool) -> void:
 hud.set_playing(active)
 if not active and is_instance_valid(bonds) and is_instance_valid(bonds.panel): bonds.panel.hide()
 if not active and is_instance_valid(pickup_interaction): pickup_interaction.hide()
 if is_instance_valid(world):
  world.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
 controls.set_enabled(active)

func pause_game() -> void:
 if state != "playing": return
 state = "paused"
 set_world_active(false)
 var box := menu("Mareas en calma", "Semilla %d · Piso %d/3" % [dungeon_seed,layout.floor_index+1] if dungeon_mode else "Partida en pausa")
 box.add_child(button("Continuar", resume_game))
 box.add_child(button("Reliquias",show_inventory))
 box.add_child(button("Diario del Abismo",func(): show_diary("paused")))
 if lab_mode: box.add_child(button("Reliquias: página %d/8 →" % (lab_page+1),func(): start_relic_room((lab_page+1)%8)))
 box.add_child(button("Prueba de carga (nueva)",start_benchmark))
 box.add_child(button("Opciones", func(): show_options("paused")))
 box.add_child(button("Menú principal", show_main_menu))

func resume_game() -> void:
 clear_panel()
 state = "playing"
 set_world_active(true)

func finish(won: bool) -> void:
 if state != "playing": return
 if won and dungeon_mode and layout.floor_index==2 and layout.boss_defeated():
  record_progress("floor","completed",{"character":selected_character})
  record_progress("ending","main")
 state = "victory" if won else "defeat"
 boss_panel.hide()
 player.process_mode = Node.PROCESS_MODE_ALWAYS
 player.expression = "victory" if won else "defeat"
 player.queue_redraw()
 player.active = false
 set_world_active(false)
 var box := menu("SELLO PURIFICADO" if won else "EL ABISMO TE RECLAMA", "Óbolos recuperados: %d" % coins)
 box.add_child(button("Jugar otra vez", restart_game))
 box.add_child(button("Menú principal", show_main_menu))

func show_options(previous: String) -> void:
 options_return = previous
 state = "options"
 var box := menu("Opciones", "Se guardan en este dispositivo")
 var quality := OptionButton.new()
 for text in ["Gráficos: Bajo", "Gráficos: Medio", "Gráficos: Alto"]: quality.add_item(text)
 quality.selected = Settings.values.quality
 quality.custom_minimum_size.y = 44
 quality.add_theme_font_size_override("font_size", 20)
 quality.item_selected.connect(func(value: int):
  Settings.values.quality = value
  if is_instance_valid(chamber):
   chamber.quality = value
   chamber.queue_redraw())
 box.add_child(quality)
 box.add_child(button("Controles táctiles",func(): show_control_options(previous)))
 var fps_toggle := CheckButton.new()
 fps_toggle.text = "Diagnóstico FPS"
 fps_toggle.button_pressed = Settings.values.get("diagnostics",false)
 fps_toggle.toggled.connect(func(value: bool): Settings.values.diagnostics = value)
 box.add_child(fps_toggle)
 box.add_child(button("Música y efectos",show_audio_options))
 if previous == "menu":
  var extras := HBoxContainer.new()
  extras.add_theme_constant_override("separation",12)
  box.add_child(extras)
  var modes_button := button("Modos y pruebas",func(): Settings.save_settings(); show_modes())
  var credits_button := button("Diario y créditos",func(): Settings.save_settings(); show_archive())
  modes_button.custom_minimum_size.x = 190
  credits_button.custom_minimum_size.x = 210
  extras.add_child(modes_button)
  extras.add_child(credits_button)
  extras.add_child(button("Progreso",func(): Settings.save_settings(); show_progress_backup()))
 var status := label("",14)
 box.add_child(status)
 box.add_child(button("Guardar y volver", func():
  var error := Settings.save_settings()
  if error != OK:
   status.text = "No se pudo guardar. Inténtalo de nuevo."
   return
  apply_controls()
  if options_return == "paused":
   state = "playing"
   pause_game()
  else: show_main_menu()))

func add_slider(box: VBoxContainer, text: String, key: String, low: float, high: float) -> void:
 box.add_child(label(text,16))
 var slider := HSlider.new()
 slider.min_value = low
 slider.max_value = high
 slider.step = 0.05
 slider.value = Settings.values[key]
 slider.custom_minimum_size = Vector2(360, 32)
 slider.value_changed.connect(func(value: float): Settings.values[key] = value)
 box.add_child(slider)

func show_audio_options() -> void:
 state="audio_options"
 var box:=menu("Sonidos del abismo","Música original · ajustes independientes")
 for entry in [["Música","music_volume"],["Efectos y habilidades","sfx_volume"]]:
  var key: String=entry[1]
  var caption:=label("%s · %d%%" % [entry[0],roundi(float(Settings.values[key])*100)],18)
  box.add_child(caption)
  var slider:=HSlider.new()
  slider.name=key
  slider.min_value=0
  slider.max_value=1
  slider.step=0.01
  slider.value=Settings.values[key]
  slider.custom_minimum_size=Vector2(490,48)
  slider.value_changed.connect(func(value: float):
   Settings.values[key]=value
   caption.text="%s · %d%%" % [entry[0],roundi(value*100)]
   Soundscape.apply_settings())
  box.add_child(slider)
 box.add_child(button("Probar efecto",func(): Soundscape.play_effect("relic")))
 box.add_child(label("0% silencia el canal. La música continúa al pausar.",14))
 var status:=label("",14)
 box.add_child(status)
 box.add_child(button("Guardar y volver",func():
  if Settings.save_settings()!=OK:
   status.text="No se pudo guardar. Inténtalo de nuevo."
   return
  show_options(options_return)))

func _process(_delta: float) -> void:
 if state=="closing": return
 # The director compares IDs before loading. No file I/O or tree searches per frame.
 var held:=is_instance_valid(world) and state in ["paused","inventory","doors","shop","options","control_options","control_preview","audio_options","diary","bond_puzzle","bond_analysis"]
 var kind: String=layout.rooms[layout.current].kind if dungeon_mode and not layout.rooms.is_empty() else "trial" if trial_kind!="" else "combat"
 var playing_score: String=Soundscape.current_track if held else ""
 var score:=AbyssAudioCatalog.route(state,dungeon_mode,layout.floor_index,kind,not enemies.is_empty(),playing_score)
 Soundscape.set_context(score,held)

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
  if is_instance_valid(character_audio): character_audio.stop(); character_audio.stream=null
  if is_instance_valid(controls): controls.release_all()
  pause_game()
 if what == NOTIFICATION_WM_GO_BACK_REQUEST:
  if state == "menu" and panel is AnimatedMainMenu: panel.skip_intro()
  elif state in ["modes","credits","character_selection","progress_backup"]: show_main_menu()
  elif state=="seed": show_modes()
  elif state=="control_options": show_options(controls_return)
  elif state=="control_preview": show_control_options(controls_return)
  elif state=="audio_options": show_options(options_return)
  elif state=="archive": show_options("menu")
  elif state=="diary": close_diary()
  elif state=="codes": show_main_menu()
  elif state in ["bond_hub","bond_variants"]: show_bond_hub()
  elif state in ["bond_puzzle","bond_analysis"]: resume_game()
  elif state == "playing": pause_game()
  elif state == "paused": resume_game()

func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
  if state == "playing": pause_game()
  elif state == "paused": resume_game()
  elif state in ["character_selection","progress_backup"]: show_main_menu()
  elif state=="control_options": show_options(controls_return)
  elif state=="control_preview": show_control_options(controls_return)
  elif state=="audio_options": show_options(options_return)
  elif state=="archive": show_options("menu")
  elif state=="diary": close_diary()
  elif state=="codes": show_main_menu()
  elif state in ["bond_hub","bond_variants"]: show_bond_hub()
  elif state in ["bond_puzzle","bond_analysis"]: resume_game()

func show_archive() -> void:
 state="archive"
 var box:=menu("Archivo del faro","Tus hallazgos permanecen entre expediciones")
 box.add_child(button("Diario del Abismo",func(): show_diary("archive")))
 box.add_child(button("Créditos",show_credits))
 box.add_child(button("Volver",func(): show_options("menu")))

func show_diary(previous: String="archive") -> void:
 diary_return=previous
 if is_instance_valid(world): set_world_active(false)
 state="diary"
 clear_panel()
 var diary:=AbyssDiary.new()
 diary.snapshot=progress.data.duplicate(true)
 panel=diary
 ui.add_child(diary)
 diary.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 diary.close_requested.connect(close_diary)

func close_diary() -> void:
 if diary_return=="paused" and is_instance_valid(world):
  state="playing"
  pause_game()
 else: show_archive()

func show_credits() -> void:
 state = "credits"
 var box := menu("Créditos", "Abyss of Tears · Código y arte originales · MIT")
 var scroll := ScrollContainer.new()
 scroll.custom_minimum_size = Vector2(440, 220)
 box.add_child(scroll)
 var text := label("Motor: Godot 4.6.3 (MIT).\n\nMúsica y efectos originales: composición y síntesis del proyecto (MIT).\n13 piezas para los tres pisos actuales; banda sonora de la campaña ampliada pendiente.\n\n" + FileAccess.get_file_as_string("res://assets/licenses/GODOT_LICENSE.txt") + "\n\nComponentes del motor:\n" + FileAccess.get_file_as_string("res://assets/licenses/GODOT_COPYRIGHT.txt"), 14)
 text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(text)
 box.add_child(button("Volver", show_main_menu))

func spawn_enemy(kind_id: int, point: Vector2, weak: bool = false, rank: String="normal") -> void:
 if state != "playing" or enemies.size() >= MAX_ENEMIES: return
 var enemy: AbyssEnemy = ENEMY.instantiate()
 enemy.kind = clampi(kind_id,0,19)
 enemy.rank=rank if rank in ["normal","elite","miniboss"] else "normal"
 enemy.weak = weak
 enemy.once = weak
 enemy.position = safe_point(point)
 enemy.target = player
 enemy.peers = enemies
 enemy.shot.connect(func(origin: Vector2, direction: Vector2):
  NineBonds.observed(player,enemy)
  spawn_enemy_bullet(origin,direction))
 enemy.summon.connect(func(id: int, location: Vector2, small: bool): spawn_enemy(id, location, small))
 enemy.hazard.connect(spawn_hazard)
 enemy.defeated.connect(func(location: Vector2, reward: int): on_enemy_defeated(enemy, location, reward))
 world.add_child(enemy)
 enemies.append(enemy)
 queue_journal_observation()
 update_counts()

func safe_point(point: Vector2) -> Vector2:
 if not chamber.blueprint.is_empty(): return RoomBlueprint.safe_point(chamber.blueprint,point)
 point = point.clamp(Vector2(70,100),Vector2(890,450))
 for pillar: Vector2 in chamber.PILLARS:
  if point.distance_to(pillar) < 55: point = pillar + Vector2(0,60)
 return point

func spawn_hazard(point: Vector2, type: String) -> void:
 var count := 0
 for node in world.get_children():
  if node is EnemyHazard:
   count += 1
   # Only one timed stat modifier at a time; restoration remains deterministic.
   if type == "curse" and node.kind == "curse": return
 if count >= MAX_HAZARDS: return
 point = safe_point(point)
 if type == "wall":
  if point.distance_to(player.position)<65: return
  var needs_relocation:=false
  for pickup: RelicPickup in pickups:
   if is_instance_valid(pickup) and not pickup.taking and point.distance_to(pickup.position)<65: needs_relocation=true; break
  if needs_relocation:
   var found:=false
   for direction in range(16):
    var candidate:=safe_point(point+Vector2.from_angle(direction*TAU/16.0)*100)
    if chamber.blocks(candidate,24) or candidate.distance_to(player.position)<65: continue
    var available:=true
    for pickup: RelicPickup in pickups:
     if is_instance_valid(pickup) and not pickup.taking and candidate.distance_to(pickup.position)<65: available=false; break
    if available: point=candidate; found=true; break
   if not found: return
 var hazard := EnemyHazard.new()
 hazard.kind = type
 hazard.player = player
 hazard.position = point
 world.add_child(hazard)
 hazards.append(hazard)

func spawn_wave() -> void:
 var points := [Vector2(150,140),Vector2(800,140),Vector2(480,120),Vector2(820,300)]
 for i in range(4): spawn_enemy(wave * 4 + i,points[i])
 update_counts()

func clear_wave() -> void:
 if state != "playing" or not enemies.is_empty(): return
 if trial_kind.begins_with("bonds:"):
  if is_instance_valid(bonds): bonds.resolve()
  return
 if trial_kind!="":
  if trial_stage<2:
   trial_stage+=1
   player.stats.health=minf(player.stats.max_health,player.stats.health+1)
   update_health(player.stats.health,player.stats.max_health)
   spawn_trial_stage()
  else:
   progress.record("shader_trial" if trial_kind=="shader" else "illusion_trial","trial:"+str(progress.data.serial))
   finish(true)
  return
 # Resolve announced death explosions before allowing victory or the next wave.
 for node in world.get_children():
  if node is EnemyHazard and node.kind == "explosion":
   return
 if dungeon_mode:
  if not layout.rooms[layout.current].cleared:
   player.relics.effects.event("room",player,self)
   var hard: bool=layout.rooms[layout.current].get("hard",false)
   var clean: bool=not layout.rooms[layout.current].get("damaged",false)
   NineBonds.room(player,clean)
   record_progress("room","clear",{"clean":clean,"hard":hard})
   if hard:
    player.add_determination(10+(10 if clean else 0))
    player.relics.effects.event("challenge",player,self)
   layout.rooms[layout.current].cleared = true
   if layout.rooms[layout.current].kind in ["special","secret","treasure","shop"]: CharacterRules.special_room(player,layout.floor_index)
   reward_room()
   dungeon_map.queue_redraw()
  return
 if expedition and wave < 4:
  wave += 1
  for node in world.get_children():
   if node is EnemyHazard: node.queue_free()
  for bullet in bullets:
   if is_instance_valid(bullet): bullet.expire()
  bullets.clear()
  player.stats.health = minf(player.stats.max_health,player.stats.health + 1)
  update_health(player.stats.health,player.stats.max_health)
  spawn_wave()
 else: finish(true)

func projectile_blocked(point: Vector2) -> bool:
 if is_instance_valid(bonds) and bonds.blocks(point): return true
 if chamber.blocks(point): return true
 for node in hazards:
  if is_instance_valid(node) and node.kind == "wall" and point.distance_to(node.position) < 27: return true
 return false

func start_dungeon(chosen_seed: int = -1) -> bool:
 if not CharacterCatalog.playable(selected_character): selected_character="neris"
 if not progress.begin_run():
  show_main_menu()
  return false
 trial_kind=""
 lab_mode=false
 dungeon_mode = true
 expedition = false
 dungeon_seed = (int(randi()) & 2147483647) if chosen_seed<0 else chosen_seed
 layout.generate(dungeon_seed,0,true)
 start_game()
 return true

func populate_room() -> void:
 var room: Dictionary = layout.rooms[layout.current]
 if room.kind=="special" and layout.floor_index>0 and not room.get("miniboss_done",false):
  room.cleared=false
  room.hard=true
  spawn_enemy(18,Vector2(480,180),false,"miniboss")
  room.miniboss_done=true
  return
 if room.cleared: return
 if room.kind=="boss":
  room.hard=true
  spawn_guardian()
  return
 var rng := RandomNumberGenerator.new()
 rng.seed = dungeon_seed + layout.floor_index * 1000 + layout.current * 71
 var count := 3 + layout.floor_index
 if room.kind == "descent": count += 1
 var points := [Vector2(150,140),Vector2(800,140),Vector2(480,120),Vector2(820,300),Vector2(140,330),Vector2(480,250)]
 for i in range(count):
  var kind := rng.randi_range(0,[7,13,19][layout.floor_index])
  var elite: bool=layout.floor_index>0 and i==0 and layout.current%2==0
  if elite or count>=5: room.hard=true
  spawn_enemy(kind,points[i],false,"elite" if elite else "normal")
  enemies.back().health *= 1 + layout.floor_index * 0.3
  enemies.back().max_health = enemies.back().health

func reward_room() -> void:
 var room: Dictionary = layout.rooms[layout.current]
 if not room.cleared or room.rewarded or room.kind in ["start","shop","special","secret"]: return
 room.rewarded = true
 var rng := RandomNumberGenerator.new()
 rng.seed = dungeon_seed + layout.floor_index * 101 + layout.current
 if room.kind == "descent": floor_label.text += " · Salida abierta: Puertas / Piso"
 if not room.has("pickups"): room.pickups=[]
 for data: Dictionary in Economy.room_rewards(rng,layout.floor_index,room.kind):
  room.pickups.append(data)
  if is_instance_valid(effect_layer) and room_pickups==room.pickups: spawn_pickup(data)
 update_counts()

func door_point(neighbor: int) -> Vector2:
 var direction: Vector2i = layout.rooms[neighbor].cell-layout.rooms[layout.current].cell
 return Vector2(480,274)+Vector2(direction)*Vector2(410,185)

func check_doors() -> void:
 if door_cooldown>0: return
 for neighbor: int in layout.rooms[layout.current].links:
  if layout.door_visible(neighbor) and player.position.distance_to(door_point(neighbor)) < 35:
   transitioning = true
   travel_to.call_deferred(neighbor)
   return

func travel_to(neighbor: int) -> void:
 if not dungeon_mode or state not in ["playing","doors"] or not layout.door_visible(neighbor):
  transitioning=false
  return
 if layout.rooms[neighbor].get("locked",false):
  if layout.unlock(neighbor,keys):
   keys-=1
   update_keys()
  else:
   door_cooldown=0.8
   show_notice("Necesitas una llave",RelicPickup.KEY)
   transitioning=false
   return
 if not layout.enter(neighbor):
  transitioning=false
  return
 if layout.rooms[neighbor].kind=="secret": record_progress("secret","discovered")
 start_game(true)
 if layout.rooms[neighbor].cleared and layout.rooms[neighbor].kind in ["secret","treasure","special","shop"]: CharacterRules.special_room(player,layout.floor_index)

func show_doors() -> void:
 if not dungeon_mode or state != "playing": return
 state = "doors"
 set_world_active(false)
 var room: Dictionary = layout.rooms[layout.current]
 var box := menu("Piso %d · %s" % [layout.floor_index+1,FloorLayout.BIOMES[layout.floor_index]],"Semilla %d\n" % dungeon_seed + ("Limpia la habitación para abrir las puertas" if not room.cleared else "Elige una puerta o acércate a ella"))
 if room.cleared:
  for neighbor: int in room.links:
   if not layout.door_visible(neighbor): continue
   var difference: Vector2i = layout.rooms[neighbor].cell-room.cell
   var direction := "Norte" if difference.y < 0 else "Sur" if difference.y > 0 else "Este" if difference.x > 0 else "Oeste"
   var caption := "Puerta " + direction + (" · 1 llave" if layout.rooms[neighbor].get("locked",false) else "")
   var entry := button(caption,func(): travel_to(neighbor))
   entry.disabled=layout.rooms[neighbor].get("locked",false) and keys<1
   box.add_child(entry)
  if room.kind=="shop": box.add_child(button("Ver tienda",show_shop))
  if room.kind == "descent":
   var exit_button := button(("Descender" if layout.floor_index<2 else "Salir del abismo") if layout.boss_defeated() else "Derrota primero al Custodio",descend)
   exit_button.disabled=not layout.boss_defeated()
   box.add_child(exit_button)
 box.add_child(button("Volver",resume_game))

func descend() -> void:
 if not dungeon_mode or state != "doors" or not layout.rooms[layout.current].cleared or layout.rooms[layout.current].kind != "descent" or not layout.boss_defeated(): return
 if layout.floor_index == 2:
  state = "playing"
  finish(true)
  return
 record_progress("floor","completed",{"character":selected_character})
 layout.generate(dungeon_seed,layout.floor_index+1,true)
 start_game(true)

func restart_game() -> void:
 if dungeon_mode: start_dungeon()
 else: start_game()

func build_relic_ui() -> void:
 toast = HBoxContainer.new()
 toast.position = Vector2(285,110)
 toast.custom_minimum_size.x=380
 toast.add_theme_constant_override("separation",10)
 ui.add_child(toast)
 toast_icon = TextureRect.new()
 toast_icon.custom_minimum_size = Vector2(42,42)
 toast_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 toast_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 toast.add_child(toast_icon)
 toast_label = label("",16)
 toast_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 toast_label.custom_minimum_size.x=330
 toast.add_child(toast_label)
 toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
 diagnostics = label("",14)
 diagnostics.position = Vector2(240,515)
 ui.add_child(diagnostics)

func spawn_pickup(data: Dictionary) -> RelicPickup:
 var pickup: RelicPickup=BondPickup.new() if data.get("reward_kind","") in ["component","sample","fragment"] else ArchaeologyPickup.new() if data.get("reward_kind","")=="artifact" else RelicPickup.new()
 pickup.data = data
 pickup.player = player
 pickup.position = safe_pickup_point(data.get("position",Vector2(480,274)))
 data.position=pickup.position
 pickup.quality = Settings.values.quality
 pickup.accept_claim=collect_relic
 pickup.unlock_requested.connect(unlock_chest)
 pickup.opened.connect(func(): Soundscape.play_effect("chest"))
 pickup.claimed.connect(func(item: RelicPickup): Soundscape.play_effect("buy" if item.data.get("paid",false) else "coin" if item.data.get("reward_kind","")=="coins" else "relic"))
 world.add_child(pickup)
 pickups.append(pickup)
 return pickup

func collect_relic(pickup: RelicPickup) -> bool:
 if state not in ["playing","shop"] or not is_instance_valid(player) or not player.active or pickup.player!=player or pickup.get_parent()!=world or not pickup.data.get("claiming",false) or pickup.data.get("collected",false) or not pickup.valid_reward(): return false
 var kind: String = pickup.data.get("reward_kind","relic")
 if kind=="artifact": return collect_artifact(pickup)
 if kind in ["component","sample","fragment"]: return is_instance_valid(bonds) and bonds.collect(pickup)
 if kind in ["coins","heal","key"]:
  if kind=="heal" and player.stats.health>=player.stats.max_health: return false
  if kind=="key" and keys>=99: return false
  if kind=="key": keys=mini(99,keys+1); update_keys()
  elif kind=="coins": coins += Economy.amount(pickup.data)
  else: player.stats.health = minf(player.stats.max_health,player.stats.health+(1.0 if player.character_id=="nox" else 2.0))
  update_counts()
  update_health(player.stats.health,player.stats.max_health)
  toast_icon.texture = RelicPickup.KEY if kind=="key" else pickup.icon() if kind=="coins" else RelicPickup.HEAL
  toast_label.text = "Llave del faro · Abre cerraduras opcionales" if kind=="key" else pickup.display_name()+" · +%d monedas" % Economy.amount(pickup.data) if kind=="coins" else "Tónico de sal · Recupera hasta 2 de vida"
  toast_timer = 2.8
  toast.show()
  player.pickup_pose = 1.0
  return true
 var id: String = pickup.data.id
 var definition := RelicCatalog.definition(id)
 var added := player.relics.add(id,player.stats)
 if added:
  record_progress("item",id,{"id":id})
  if trial_kind.begins_with("bonds:") and not lab_mode: progress.record("item","bond:"+id,{"id":id})
  player.relics.effects.pickup(id,player,self)
 if not added: coins += int(Economy.config().duplicate_compensation)
 player.pickup_pose = 1.0
 player.queue_redraw()
 update_health(player.stats.health,player.stats.max_health)
 update_counts()
 toast_icon.texture = RelicCatalog.icon(id)
 toast_label.text = definition.name + " · " + RelicCatalog.RARITIES[definition.rarity] + "\n" + (definition.description if added else "Máximo alcanzado: +%d óbolo" % int(Economy.config().duplicate_compensation))
 toast_timer = 2.8
 toast.show()
 return true

func collect_artifact(pickup: RelicPickup) -> bool:
 if not dungeon_mode or lab_mode or state not in ["playing","shop"] or not pickup is ArchaeologyPickup or pickup.player!=player or pickup.get_parent()!=world or not pickup.data.get("claiming",false) or pickup.data.get("collected",false): return false
 var id: String=pickup.data.id
 var entry:=ArchaeologyCatalog.definition(id)
 if entry.is_empty(): return false
 var known: bool=progress.data.journal.artifacts.has(id)
 if not known and not progress.discover({"artifacts":[id]}): return false
 if not known:
  match entry.effect:
   "key": keys=mini(99,keys+1)
   "hint": layout.reveal_secret()
   "map":
    for neighbor: int in layout.rooms[layout.current].links:
     for nearby: int in layout.rooms[neighbor].links:
      if not layout.room_hidden(nearby): layout.rooms[nearby].mapped=true
  dungeon_map.queue_redraw()
  update_keys()
 player.pickup_pose=1.0
 show_notice(entry.name+(" · Ya registrado" if known else " · Diario actualizado"),pickup.icon())
 return true

func update_relic_ui(delta: float) -> void:
 toast_timer = maxf(0,toast_timer-delta)
 if toast_timer<=0: toast.hide()
 for i in range(pickups.size()-1,-1,-1):
  if not is_instance_valid(pickups[i]): pickups.remove_at(i)
 for i in range(sparks.size()-1,-1,-1):
  sparks[i].life -= delta
  if sparks[i].life <= 0: sparks.remove_at(i)
 diagnostic_timer -= delta
 diagnostics.visible = Settings.values.get("diagnostics",false)
 if diagnostic_timer<=0:
  diagnostic_timer = 0.5
  diagnostics.text = "FPS %d · enemigos %d · disparos %d · partículas %d · física %.2f ms" % [Engine.get_frames_per_second(),enemies.size(),bullets.size(),effects.size()*(6 if Settings.values.quality==1 else 12)+sparks.size(),Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000]

func apply_relic_hit(bullet: AbyssProjectile, enemy: AbyssEnemy) -> void:
 Soundscape.play_effect("hit")
 if "fire" in bullet.elements: enemy.burning = 3.0
 if "ice" in bullet.elements: enemy.slowed = 2.0
 var multiplier:=1.15 if enemy.marked>0 else 1.0
 if bullet.travelled>210: multiplier+=bullet.far_bonus
 enemy.take_damage(bullet.damage*multiplier*NineBonds.hit_multiplier(player,enemy),bullet.direction)
 if "poison" in bullet.elements: enemy.poisoned=3.0
 if bullet.marking: enemy.marked=maxf(enemy.marked,3.0)
 if bullet.push>0 and not enemy.dead: enemy.move_and_collide(bullet.direction*minf(30,bullet.push))
 player.relics.effects.hit(bullet,enemy,player,self)
 CharacterRules.hit(player,enemy,bullet,self)
 if "electric" in bullet.elements:
  player.relics.impacts += 1
  if player.relics.impacts % 3 == 0:
   for other in enemies.duplicate():
    if is_instance_valid(other) and other != enemy and not other.dead and other.position.distance_to(enemy.position)<150:
     other.take_damage(bullet.damage*0.6)
     if sparks.size()<8: sparks.append({"from":enemy.position,"to":other.position,"life":0.18})
     break

func show_inventory() -> void:
 if state != "paused": return
 state = "inventory"
 var box := menu("Reliquias", "Daño %.2f · velocidad %.0f · intervalo %.2f s" % [player.stats.damage,player.stats.speed,player.stats.attack_interval])
 var scroll := ScrollContainer.new()
 scroll.custom_minimum_size = Vector2(610,240)
 box.add_child(scroll)
 var entries := VBoxContainer.new()
 entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(entries)
 if player.relics.owned.is_empty(): entries.add_child(label("Todavía no has recogido reliquias.",18))
 for id: String in player.relics.owned:
  var definition := RelicCatalog.definition(id)
  var row := HBoxContainer.new()
  entries.add_child(row)
  var icon := TextureRect.new()
  icon.texture = RelicCatalog.icon(id)
  icon.custom_minimum_size = Vector2(44,44)
  icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  row.add_child(icon)
  var info:=label("%s ×%d · %s\n%s" % [definition.name,player.relics.owned[id],RelicCatalog.RARITIES[definition.rarity],definition.description],15)
  info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  info.custom_minimum_size.x=430
  info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  row.add_child(info)
  if definition.category=="activo":
   var equip_button:=button("Equipado" if player.relics.effects.active_id==id else "Equipar",func():
    player.relics.effects.equip(id,player.relics.owned)
    state="paused"
    show_inventory())
   equip_button.disabled=player.relics.effects.active_id==id
   row.add_child(equip_button)
 box.add_child(button("Volver",func(): state="playing"; pause_game()))

func start_relic_room(page: int=0) -> void:
 var keep: bool=lab_mode and is_instance_valid(player)
 lab_mode=true
 lab_page=clampi(page,0,7)
 trial_kind=""
 dungeon_mode = false
 expedition = false
 start_game(keep)
 for pickup in pickups: pickup.queue_free()
 pickups.clear()
 for enemy in enemies: enemy.queue_free()
 enemies.clear()
 # Keep victory pending until the player chooses to finish the laboratory.
 for i in range(mini(14,RelicCatalog.DATA.size()-lab_page*14)):
  var point := Vector2(150+(i%7)*105,180+(i/7)*150)
  spawn_pickup({"id":RelicCatalog.DATA[i+lab_page*14].id,"position":safe_point(point),"collected":false,"chest":i%3==0})
 state = "laboratory"
 # Laboratory uses the same physics and input as combat, with a harmless target.
 spawn_lab_target()

func spawn_lab_target() -> void:
 state = "playing"
 spawn_enemy(0,Vector2(780,280))
 enemies.back().health = 200
 enemies.back().max_health = 200
 enemies.back().speed = 0
 enemies.back().definition = enemies.back().definition.duplicate()
 enemies.back().definition.damage = 0

func start_benchmark() -> void:
 dungeon_mode = false
 expedition = false
 start_game()
 Settings.values.diagnostics = true
 for i in range(MAX_ENEMIES-enemies.size()):
  spawn_enemy(1,Vector2(120+(i%5)*140,130+(i/5)*85))
 for i in range(MAX_BULLETS):
  spawn_enemy_bullet(Vector2(480,220),Vector2.from_angle(float(i)*TAU/MAX_BULLETS))

func build_room_features() -> void:
 for data: Dictionary in layout.rooms[layout.current].get("props",[]):
  var prop := RoomProp.new()
  prop.data=data
  prop.player=player
  prop.position=safe_point(data.position)
  prop.activated.connect(activate_prop)
  world.add_child(prop)
  props.append(prop)

func activate_prop(prop: RoomProp) -> void:
 if state!="playing" or not is_instance_valid(prop) or prop.get_parent()!=world or not props.has(prop) or not prop.data.get("used",false) or prop.data.get("activation_handled",false): return
 prop.data.activation_handled=true
 match prop.data.kind:
  "switch":
   layout.reveal_secret()
   dungeon_map.queue_redraw()
   show_notice("Una pared secreta ha quedado al descubierto",RelicPickup.KEY)
  "fountain":
   player.stats.health=minf(player.stats.max_health,player.stats.health+(1.0 if player.character_id=="nox" else 2.0))
   update_health(player.stats.health,player.stats.max_health)
   show_notice("Fuente de sal · +2 de vida",RelicPickup.HEAL)
  "barrel":
   if prop.data.get("reward_delivered",false): return
   prop.data.reward_delivered=true
   var outcome:=int(prop.data.get("drop_type",2 if prop.data.get("drop_key",false) else 1))
   if outcome==0: return
   var data:=Economy.coin_data(int(prop.data.get("coin_amount",1)),prop.position)
   if outcome==2: data.reward_kind="key"
   room_pickups.append(data)
   spawn_pickup(data)

func strike_prop(point: Vector2, bullet: AbyssProjectile) -> bool:
 for prop in props:
  if is_instance_valid(prop) and prop.data.kind=="barrel" and not prop.data.get("used",false) and point.distance_to(prop.position)<20:
   if not bullet.hostile: prop.take_damage(bullet.damage)
   bullet.expire()
   return true
 return false

func reveal_secret_wall(point: Vector2) -> void:
 if not dungeon_mode or not layout.expanded or not layout.rooms[layout.current].cleared: return
 for neighbor: int in layout.rooms[layout.current].links:
  if layout.room_hidden(neighbor) and point.distance_to(door_point(neighbor))<38+player.relics.effects.value("secret_radius"):
   layout.reveal_secret()
   dungeon_map.queue_redraw()
   show_notice("¡Pared secreta descubierta!",RelicPickup.KEY)

func unlock_chest(pickup: RelicPickup) -> void:
 if state not in ["playing","shop"] or not pickup.data.get("locked",false) or not pickup.data.get("chest",false): return
 if keys>0:
  keys-=1
  pickup.data.locked=false
  update_keys()
 else: show_notice("Necesitas una llave para este cofre",RelicPickup.KEY)

func update_keys() -> void:
 if is_instance_valid(hud): hud.set_counts(coins,keys,enemies.size(),wave if expedition else -1)

func position_notice() -> void:
 if not is_instance_valid(toast): return
 var width:=get_viewport().get_visible_rect().size.x
 toast.position=Vector2((width-960)*0.5+(120 if controls.left_handed else 540),118) if hud.detail.visible else Vector2(width*0.5-195,110)

func show_notice(message: String, icon: Texture2D) -> void:
 position_notice()
 toast_icon.texture=icon
 toast_label.text=message
 toast_timer=2.8
 toast.show()

func spawn_guardian(variant: int=-1) -> void:
 if state!="playing" or enemies.size()>=MAX_ENEMIES: return
 var guardian: TideWarden=GUARDIAN.instantiate()
 guardian.floor_level=layout.floor_index if variant<0 else clampi(variant,0,2)
 guardian.position=Vector2(480,180)
 guardian.target=player
 guardian.peers=enemies
 guardian.shot.connect(spawn_enemy_bullet)
 guardian.summon.connect(func(id: int, location: Vector2, small: bool): spawn_enemy(id,location,small))
 guardian.hazard.connect(spawn_hazard)
 guardian.defeated.connect(func(point: Vector2, reward: int): on_enemy_defeated(guardian,point,reward))
 guardian.health_report.connect(func(current: float, maximum: float, phase: int):
  boss_bar.max_value=maximum
  boss_bar.value=current
  boss_name.text=(guardian.display_name if guardian.display_name!="" else TideWarden.BOSS_NAMES[guardian.floor_level])+" · Fase %d" % phase
  boss_panel.visible=current>0)
 world.add_child(guardian)
 enemies.append(guardian)
 queue_journal_observation()
 update_counts()

func show_shop() -> void:
 if not dungeon_mode or state not in ["doors","shop"] or layout.rooms[layout.current].kind!="shop": return
 state="shop"
 var box := menu("La tienda de sal", "%d óbolos · Cada compra se entrega al confirmar" % coins)
 for i in range(room_pickups.size()):
  var data: Dictionary=room_pickups[i]
  if data.get("collected",false): continue
  var name: String="Llave del faro" if data.get("reward_kind","")=="key" else RelicCatalog.definition(data.id).name
  var price: int=data.get("price",0)
  var entry := button(name+(" · %d óbolos" % price if price>0 else " · Pagado"),func(): buy_offer(i); show_shop())
  var capped: bool=data.get("reward_kind","relic")=="relic" and int(player.relics.owned.get(data.id,0))>=int(RelicCatalog.definition(data.id).max_stack)
  if capped: entry.text=name+" · Máximo alcanzado"
  entry.disabled=price<=0 or capped
  box.add_child(entry)
 box.add_child(button("Volver a la habitación",resume_game))

func buy_offer(index: int) -> bool:
 if not dungeon_mode or state not in ["playing","shop"] or layout.rooms[layout.current].kind!="shop" or index<0 or index>=room_pickups.size(): return false
 var data: Dictionary=room_pickups[index]
 for pickup: RelicPickup in pickups:
  if is_instance_valid(pickup) and is_same(pickup.data,data): return purchase_pickup(pickup)
 return false

func purchase_pickup(pickup: RelicPickup) -> bool:
 if state not in ["playing","shop"] or not dungeon_mode or layout.rooms[layout.current].kind!="shop" or not is_instance_valid(pickup) or pickup.get_parent()!=world or pickup.player!=player: return false
 var data: Dictionary=pickup.data
 var price:=int(data.get("price",0))
 if price<=0 or data.get("collected",false) or data.get("purchasing",false) or not pickup.valid_reward(): return false
 if coins<price:
  Soundscape.play_effect("error")
  show_notice("MONEDAS INSUFICIENTES",RelicPickup.COINS)
  return false
 if data.get("reward_kind","relic")=="relic" and int(player.relics.owned.get(data.id,0))>=int(RelicCatalog.definition(data.id).max_stack):
  show_notice("Máximo de este objeto alcanzado",pickup.icon())
  return false
 var was_paid: bool=data.get("paid",false)
 data.purchasing=true
 coins-=price
 data.price=0
 data.paid=true
 var delivered:=pickup.claim()
 data.erase("purchasing")
 if not delivered:
  coins+=price
  data.price=price
  data.paid=was_paid
  show_notice("No puedes recibir esta recompensa ahora",pickup.icon())
  return false
 update_counts()
 if is_instance_valid(pickup_interaction): pickup_interaction.hide()
 return true

func position_pickup_interaction() -> void:
 var viewport_size:=get_viewport().get_visible_rect().size
 var panel_height:=145.0 if pickup_interaction.action.visible else 92.0
 pickup_interaction.position=Vector2(viewport_size.x*0.5-215,viewport_size.y-panel_height-15)
 pickup_interaction.size=Vector2(430,panel_height)
 sync_control_exclusions()

func update_pickup_interaction() -> void:
 if is_instance_valid(bonds) and not bonds.selected_station.is_empty():
  pickup_interaction.hide()
  return
 var nearest: RelicPickup
 var distance:=RelicPickup.INTERACTION_RADIUS
 for pickup: RelicPickup in pickups:
  if not is_instance_valid(pickup) or pickup.taking or pickup.data.get("collected",false): continue
  var separation:=player.global_position.distance_to(pickup.global_position)
  if separation<=distance:
   nearest=pickup
   distance=separation
 if nearest==null:
  pickup_interaction.hide()
  pickup_interaction.target=null
  sync_control_exclusions()
 else:
  pickup_interaction.present(nearest)
  position_pickup_interaction()

func interact_with_pickup(pickup: RelicPickup) -> bool:
 if state!="playing" or not is_instance_valid(pickup) or pickup.get_parent()!=world or pickup.player!=player or not pickup.near_player(RelicPickup.INTERACTION_RADIUS): return false
 var success:=purchase_pickup(pickup) if int(pickup.data.get("price",0))>0 else pickup.open_chest()
 update_pickup_interaction()
 return success

func safe_pickup_point(origin: Vector2) -> Vector2:
 # Deterministic bounded search; use the same placement for every dynamic reward.
 var initial:=safe_point(origin)
 for ring in range(9):
  for direction in range(1 if ring==0 else 16):
   var candidate:=initial+Vector2.from_angle(direction*TAU/16.0)*ring*32.0
   if chamber.blocks(candidate,32): continue
   var obstructed:=false
   if dungeon_mode:
    for neighbor: int in layout.rooms[layout.current].links:
     if candidate.distance_to(door_point(neighbor))<65: obstructed=true; break
   if obstructed: continue
   for prop: RoomProp in props:
    if is_instance_valid(prop) and not (prop.data.kind=="barrel" and prop.data.get("used",false)) and candidate.distance_to(prop.position)<50: obstructed=true; break
   if obstructed: continue
   for hazard: EnemyHazard in hazards:
    if is_instance_valid(hazard) and hazard.kind=="wall" and candidate.distance_to(hazard.position)<58: obstructed=true; break
   if obstructed: continue
   for existing: RelicPickup in pickups:
    if is_instance_valid(existing) and not existing.taking and not existing.data.get("collected",false) and candidate.distance_to(existing.position)<56: obstructed=true; break
   if not obstructed: return candidate
 return initial

func show_seed_menu() -> void:
 state="seed"
 var box:=menu("Semilla del abismo","La misma semilla reproduce la mazmorra de esta versión")
 var field:=LineEdit.new()
 field.placeholder_text="Número de 0 a 2147483647"
 field.max_length=10
 field.custom_minimum_size=Vector2(400,44)
 field.add_theme_font_size_override("font_size",20)
 field.virtual_keyboard_type=2 # Numeric keyboard on Android.
 box.add_child(field)
 var status:=label("",16)
 box.add_child(status)
 var submit: Callable=func():
  if not start_seeded_run(field.text): status.text="Escribe un número entre 0 y 2147483647"
 field.text_submitted.connect(func(_text: String): submit.call())
 box.add_child(button("Entrar con esta semilla",submit))
 box.add_child(button("Volver",show_modes))

func start_seeded_run(text: String) -> bool:
 if state!="seed" or not text.is_valid_int(): return false
 var value:=int(text)
 if value<0 or value>2147483647: return false
 start_dungeon(value)
 return true

func record_progress(event: String, suffix: String, payload: Dictionary={}) -> bool:
 if not dungeon_mode or state not in ["playing","doors","shop"]: return false
 var token: String="%d:%d:%s" % [layout.floor_index,layout.current,suffix]
 # Floor completion has one token per floor, regardless of the exit room.
 if event=="floor": token="floor:%d" % layout.floor_index
 return progress.record(event,token,payload)

func use_character_ability() -> bool:
 if state!="playing" or not is_instance_valid(player): return false
 if player.character_id=="lumi" and player.character_state.healing_left<=0:
  show_notice("Luz Restauradora agotada en esta partida",RelicPickup.HEAL)
  return false
 if not player.activate_ability(): return false
 player.relics.effects.event("ability",player,self)
 character_audio.stop()
 character_audio.stream=CharacterSounds.ability_sound(player.character_id)
 character_audio.play()
 var id: String=player.character_id
 if id=="kael": pass # Windup is resolved once by the physics coordinator.
 elif id=="celine":
  for enemy in enemies:
   if not enemy.dead: enemy.marked=maxf(enemy.marked,player.ability_active)
 elif id in ["eira","solen"]:
  for enemy in enemies.duplicate():
   if not is_instance_valid(enemy) or enemy.dead or enemy.position.distance_to(player.position)>145: continue
   if id=="eira":
    enemy.apply_chill()
    if enemy.rank=="normal": enemy.frozen=maxf(enemy.frozen,0.35)
   else:
    enemy.burning=maxf(enemy.burning,3.0)
    enemy.take_damage(player.stats.damage*1.2)
  if effects.size()<16: effects.append({"point":player.position,"life":0.45,"kind":19 if id=="eira" else 14})
 return true

func show_progress_backup() -> void:
 state="progress_backup"
 var box:=menu("Recuerdos del abismo","Copia tus desbloqueos antes de reinstalar. No incluye una partida en curso.")
 var field:=TextEdit.new()
 field.custom_minimum_size=Vector2(610,135)
 field.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
 field.text=progress.export_code()
 field.add_theme_font_size_override("font_size",14)
 box.add_child(field)
 var message:=label("",14)
 message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 box.add_child(message)
 box.add_child(button("Copiar código",func():
  DisplayServer.clipboard_set(progress.export_code())
  message.text="Código copiado. Guárdalo en tus notas fuera del juego."))
 box.add_child(button("Restaurar código del cuadro",func():
  message.text="Recuerdos restaurados; se conservan los logros actuales." if progress.import_code(field.text) else "Código inválido o no se pudo guardar. No se ha reemplazado el progreso."))
 box.add_child(button("Volver",func(): show_options("menu")))

func _exit_tree() -> void:
 Soundscape.stop_all()
 if is_instance_valid(character_audio):
  character_audio.stop()
  character_audio.stream=null

func spawn_rupture() -> void:
 if state!="playing" or not is_instance_valid(player) or not player.active: return
 var before:=bullets.size()
 spawn_bullet(player.position+player.facing*22,player.facing,player.stats.projectile_speed,player.stats.damage*3,player.stats.attack_range,false)
 if bullets.size()>before:
  var empowered: AbyssProjectile=bullets.back()
  empowered.pierce=4
  empowered.bounces=1 if player.relics.has("bounce") else 0
  for element in ["fire","ice","electric","poison"]:
   if player.relics.has(element): empowered.elements.append(element)

func use_active_item() -> bool:
 if state!="playing" or not is_instance_valid(player) or not player.active: return false
 if player.relics.effects.activate(player,self): return true
 if not player.relics.effects.active_id.is_empty(): show_notice("Objeto agotado en esta partida" if player.relics.effects.active_exhausted() else "No se puede usar ahora",RelicCatalog.icon(player.relics.effects.active_id))
 return false

func use_shader_awaken() -> bool:
 if state!="playing" or not is_instance_valid(player) or not player.active or player.character_id!="shader" or player.determination<100 or player.awakened>0: return false
 player.determination=0
 player.awakened=8.0
 CharacterRules.update_shader(player)
 character_audio.stop()
 character_audio.stream=CharacterSounds.unlock_sound()
 character_audio.play()
 return true

func start_trial(kind: String) -> bool:
 if kind not in ["shader","illusion"] or (kind=="shader" and (not progress.shader_ready() or progress.is_unlocked("shader"))): return false
 if not progress.begin_run(): return false
 trial_kind=kind
 trial_stage=0
 dungeon_mode=false
 expedition=false
 lab_mode=false
 if not CharacterCatalog.playable(selected_character): selected_character="neris"
 start_game()
 floor_label.text="La Prueba de Shader" if kind=="shader" else "La Prueba de Ilusiones"
 floor_label.show()
 return true

func spawn_trial_stage() -> void:
 if trial_kind.begins_with("bonds:"):
  var parts:=trial_kind.split(":")
  bonds.setup(parts[1],int(parts[2]))
  return
 for bullet in bullets:
  if is_instance_valid(bullet): bullet.expire()
 bullets.clear()
 for node in hazards:
  if is_instance_valid(node): node.queue_free()
 hazards.clear()
 player.position=Vector2(480,390)
 player.immunity=maxf(player.immunity,1.0)
 show_notice("Encuentro %d / 3" % (trial_stage+1),preload("res://assets/characters/shader_skill.svg"))
 if trial_kind=="illusion":
  for i in range(2+trial_stage): spawn_enemy([9,13,15,1][i],Vector2(200+i*160,160))
 elif trial_stage==0:
  for i in range(3): spawn_enemy([0,2,4][i],Vector2(200+i*260,150))
 elif trial_stage==1:
  spawn_enemy(6,Vector2(300,170),false,"elite")
  spawn_enemy(11,Vector2(620,150))
  spawn_enemy(9,Vector2(740,250))
 else: spawn_guardian(2)
 update_counts()

func sync_control_exclusions() -> void:
 if not is_instance_valid(controls): return
 controls.excluded_regions.clear()
 if is_instance_valid(pickup_interaction) and pickup_interaction.visible: controls.excluded_regions.append(pickup_interaction.get_global_rect())
 if is_instance_valid(bonds) and is_instance_valid(bonds.panel) and bonds.panel.visible: controls.excluded_regions.append(bonds.panel.get_global_rect())
 if is_instance_valid(hud):
  for target: Button in [hud.pause_button,hud.stats_button,hud.doors_button]:
   if target.is_visible_in_tree(): controls.excluded_regions.append(target.get_global_rect())

func show_control_options(previous: String) -> void:
 controls_return=previous
 state="control_options"
 var box:=menu("Controles táctiles","Desliza para ver todos los ajustes y pruébalos")
 var scroll:=ScrollContainer.new()
 scroll.custom_minimum_size=Vector2(570,280)
 box.add_child(scroll)
 var rows:=VBoxContainer.new()
 rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 rows.add_theme_constant_override("separation",10)
 scroll.add_child(rows)
 add_slider(rows,"Tamaño","control_scale",0.8,1.25)
 add_slider(rows,"Opacidad","control_opacity",0.3,1.0)
 var deadzone_label:=label("Zona muerta: %d%% · Evita movimientos involuntarios" % roundi(Settings.values.move_deadzone*100),16)
 rows.add_child(deadzone_label)
 var deadzone:=HSlider.new()
 deadzone.min_value=0.08
 deadzone.max_value=0.28
 deadzone.step=0.01
 deadzone.value=Settings.values.move_deadzone
 deadzone.custom_minimum_size.y=40
 deadzone.value_changed.connect(func(value: float):
  Settings.values.move_deadzone=value
  deadzone_label.text="Zona muerta: %d%% · Evita movimientos involuntarios" % roundi(value*100))
 rows.add_child(deadzone)
 for key: String in ["floating_joystick","left_handed"]:
  var toggle:=CheckButton.new()
  toggle.text="Joystick flotante" if key=="floating_joystick" else "Modo zurdo: movimiento a la derecha"
  toggle.custom_minimum_size.y=44
  toggle.button_pressed=Settings.values[key]
  toggle.toggled.connect(func(value: bool): Settings.values[key]=value)
  rows.add_child(toggle)
 var fire:=OptionButton.new()
 fire.add_item("Disparo: cruceta continua")
 fire.add_item("Disparo: joystick en cuatro direcciones")
 fire.selected=int(Settings.values.fire_style)
 fire.custom_minimum_size.y=48
 fire.item_selected.connect(func(index: int): Settings.values.fire_style=index)
 rows.add_child(fire)
 var status:=label("",14)
 box.add_child(status)
 var actions:=HBoxContainer.new()
 actions.add_theme_constant_override("separation",10)
 box.add_child(actions)
 actions.add_child(button("Probar",func(): show_control_preview()))
 actions.add_child(button("Restablecer",func():
  for key: String in ["control_scale","control_opacity","move_deadzone","floating_joystick","left_handed","fire_style"]: Settings.values[key]=Settings.DEFAULTS[key]
  show_control_options(controls_return)))
 actions.add_child(button("Guardar",func():
  if Settings.save_settings()!=OK:
   status.text="No se pudo guardar. Inténtalo de nuevo."
   return
  apply_controls()
  show_options(controls_return)))

func show_control_preview() -> void:
 state="control_preview"
 clear_panel()
 panel=PanelContainer.new()
 ui.add_child(panel)
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var preview:=ControlPractice.new()
 panel.add_child(preview)
 preview.back_requested.connect(func(): show_control_options(controls_return))

func sync_control_state() -> void:
 if not is_instance_valid(player): return
 controls.item_visible=not player.relics.effects.active_id.is_empty()
 controls.item_cooldown=float(player.relics.effects.active_recharge.get(player.relics.effects.active_id,0))
 controls.awaken_visible=player.character_id=="shader"
 controls.determination=player.determination
 controls.ability_cooldown=player.ability_remaining

func show_codes() -> void:
 state="codes"
 var box:=menu("CÓDIGOS DEL ABISMO","Acceso libre sin borrar tus recuerdos ni inventar logros")
 var input:=LineEdit.new()
 input.name="CodeInput"
 input.placeholder_text="Escribe tu código"
 input.max_length=64
 input.custom_minimum_size=Vector2(530,52)
 input.add_theme_font_size_override("font_size",22)
 box.add_child(input)
 var status:=label("",17)
 status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 status.custom_minimum_size=Vector2(530,50)
 box.add_child(status)
 var submit:=func():
  status.text=progress.redeem(input.text)
  input.release_focus()

 box.add_child(button("APLICAR CÓDIGO",submit))
 input.text_submitted.connect(func(_text: String): submit.call())
 box.add_child(button("VOLVER",show_main_menu))

func show_bond_hub() -> void:
 state="bond_hub"
 var box:=menu("LOS VÍNCULOS DEL ABISMO","Desafíos independientes · cada intento inicia una partida nueva")
 var grid:=GridContainer.new()
 grid.columns=2
 grid.add_theme_constant_override("h_separation",12)
 grid.add_theme_constant_override("v_separation",6)
 box.add_child(grid)
 for entry in [["Ingeniería","engineering"],["Ecosistemas","ecology"],["Futuro Fracturado","future"],["Teatro de los Ecos","theater"],["Carreras","race"],["Circuitos","circuit"],["Pruebas tácticas","tactics"],["Resistencia","endurance"],["Constelación Familiar","family"]]:
  grid.add_child(button(entry[0],func(): show_bond_variants(entry[1])))
 box.add_child(button("Volver",show_main_menu))

func show_bond_variants(kind: String) -> void:
 state="bond_variants"
 if kind=="family":
  var all_sisters:=true
  var stars: String=""
  for id in BondCatalog.SISTERS:
   stars+="★ " if progress.is_unlocked(id) else "☆ "
   if not progress.is_unlocked(id): all_sisters=false
  var box:=menu("CONSTELACIÓN FAMILIAR",stars+" · Desbloquea a las cinco hermanas")
  if progress.data.bonds.family_done: box.add_child(label("Don obtenido: una barrera de 1 punto por partida",16))
  var begin:=button("Entrar al desafío",func(): start_bond_challenge(kind,0))
  begin.disabled=not all_sisters
  box.add_child(begin)
  box.add_child(button("Volver",show_bond_hub))
  return
 var count:=1 if kind in ["engineering","future"] else 5 if kind in ["circuit","tactics","endurance"] else 3
 var box:=menu("Pruebas del vínculo","Elige un recorrido. Puedes repetirlo sin duplicar sus logros.")
 for i in range(count): box.add_child(button("Prueba %d" % (i+1),func(): start_bond_challenge(kind,i)))
 box.add_child(button("Volver",show_bond_hub))

func start_bond_challenge(kind: String, variant: int=0) -> bool:
 if kind not in ["engineering","ecology","future","theater","race","circuit","tactics","endurance","family"]: return false
 var maximum:=0 if kind in ["engineering","future","family"] else 2 if kind in ["ecology","theater","race"] else 4
 if variant<0 or variant>maximum: return false
 if kind=="family":
  for id in BondCatalog.SISTERS:
   if not progress.is_unlocked(id): return false
 if not progress.begin_run(): return false
 if not CharacterCatalog.playable(selected_character): selected_character="neris"
 trial_kind="bonds:%s:%d" % [kind,variant]
 dungeon_mode=false
 expedition=false
 lab_mode=false
 start_game()
 return true

func show_bond_analysis() -> void:
 if state!="playing" or not is_instance_valid(bonds): return
 set_world_active(false)
 state="bond_analysis"
 var box:=menu("ANÁLISIS DE CRIATURAS","Analizar registra la táctica de una criatura realmente observada")
 var scroll:=ScrollContainer.new()
 scroll.custom_minimum_size=Vector2(580,220)
 box.add_child(scroll)
 var list:=VBoxContainer.new()
 list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(list)
 var info_label:=label("Pulsa una criatura para consultar su táctica",16)
 info_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 info_label.custom_minimum_size=Vector2(580,68)
 box.add_child(info_label)
 for id: String in progress.data.journal.creatures:
  var info:=AbyssJournal.title("creatures",id)
  list.add_child(button(info,func():
   if progress.data.bonds.sets.weaknesses.has(id) or progress.record_bond("weaknesses",id):
    info_label.text=info+": "+BondProgress.weakness(id)
    player.character_state.observed[id]=3
   else: info_label.text="No se pudo guardar el análisis"))
 box.add_child(button("Volver",resume_game))
