extends Node

const MAIN_MENU = preload("res://scenes/ui/main_menu.tscn")
var menu_intro_seen := false

const PLAYER = preload("res://scenes/player/player.tscn")
const ENEMY = preload("res://scenes/enemies/enemy.tscn")
const CHAMBER = preload("res://scenes/rooms/chamber.tscn")
const BULLET = preload("res://scripts/combat/projectile.gd")
const DOOR_ART = preload("res://assets/environment/door.svg")
const MAX_BULLETS := 96
const MAX_ENEMIES := 16
const MAX_HAZARDS := 10
var dungeon_mode := false
var layout := FloorLayout.new()
var dungeon_seed := 0
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
var hud: HBoxContainer
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

func _ready() -> void:
 get_tree().quit_on_go_back = false
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
 ui.add_child(controls)
 get_viewport().size_changed.connect(resize_world)
 build_hud()
 dungeon_map = DungeonMap.new()
 dungeon_map.size = Vector2(150,110)
 dungeon_map.set_anchors_preset(Control.PRESET_TOP_RIGHT)
 dungeon_map.position = Vector2(ui.size.x-160,6)
 ui.add_child(dungeon_map)
 floor_label = label("",15)
 floor_label.position = Vector2(24,52)
 ui.add_child(floor_label)
 navigation = button("Puertas / Piso",show_doors)
 navigation.custom_minimum_size = Vector2(160,40)
 navigation.position = Vector2(520,12)
 ui.add_child(navigation)
 build_relic_ui()
 show_main_menu()

func resize_world() -> void:
 if is_instance_valid(dungeon_map): dungeon_map.position.x = get_viewport().get_visible_rect().size.x-160
 if is_instance_valid(world):
  world.position = (get_viewport().get_visible_rect().size - Vector2(960,540)) * 0.5

func build_hud() -> void:
 hud = HBoxContainer.new()
 hud.position = Vector2(22, 12)
 hud.add_theme_constant_override("separation", 20)
 ui.add_child(hud)
 health_label = label("", 22)
 coins_label = label("", 20)
 enemies_label = label("", 20)
 var life := VBoxContainer.new()
 life.add_theme_constant_override("separation", 0)
 life.add_child(health_label)
 health_bar = ProgressBar.new()
 health_bar.show_percentage = false
 health_bar.custom_minimum_size = Vector2(120, 8)
 var fill := StyleBoxFlat.new()
 fill.bg_color = Color("8de5dc")
 fill.set_corner_radius_all(3)
 health_bar.add_theme_stylebox_override("fill", fill)
 life.add_child(health_bar)
 hud.add_child(life)
 hud.add_child(coins_label)
 hud.add_child(enemies_label)
 var pause_button := button("Ⅱ Pausa", pause_game)
 pause_button.custom_minimum_size = Vector2(112,42)
 hud.add_child(pause_button)
 hud.hide()

func label(text: String, font_size: int = 20) -> Label:
 var node := Label.new()
 node.text = text
 node.add_theme_font_size_override("font_size", font_size)
 node.add_theme_color_override("font_color", Color("d5f6ee"))
 return node

func button(text: String, action: Callable) -> Button:
 var node := Button.new()
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
 expedition = false
 dungeon_mode = false
 dungeon_map.hide()
 floor_label.hide()
 navigation.hide()
 if is_instance_valid(toast): toast.hide()
 if is_instance_valid(diagnostics): diagnostics.hide()
 controls.set_enabled(false)
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
 match action:
  "new_game": start_game()
  "options": show_options("menu")
  "credits": show_credits()
  "modes": show_modes()
  "exit": get_tree().quit()

func show_modes() -> void:
 state = "modes"
 var box := menu("Otros caminos", "Los modos de juego actuales siguen disponibles")
 box.add_child(button("Mazmorra · 3 pisos",start_dungeon))
 box.add_child(button("Incursión de enemigos",func(): expedition=true; wave=0; start_game()))
 box.add_child(button("Prueba de reliquias",start_relic_room))
 box.add_child(button("Volver",show_main_menu))

func dispose_world() -> void:
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

func start_game(keep_progress: bool = false) -> void:
 backdrop.hide()
 var carried_relics: RelicInventory = player.relics if keep_progress and is_instance_valid(player) else null
 var carried: ActorStats = player.stats if keep_progress and is_instance_valid(player) else null
 var carried_coins := coins if keep_progress else 0
 clear_panel()
 dispose_world()
 state = "playing"
 coins = carried_coins
 wave = 0
 world = Node2D.new()
 add_child(world)
 resize_world()
 chamber = CHAMBER.instantiate()
 chamber.quality = Settings.values.quality
 world.add_child(chamber)
 player = PLAYER.instantiate()
 if carried != null: player.stats = carried
 if carried_relics != null: player.relics = carried_relics
 player.position = Vector2(480, 390)
 player.controls = controls
 player.shot.connect(spawn_player_bullet)
 player.health_changed.connect(update_health)
 player.died.connect(func(): finish(false))
 world.add_child(player)
 if dungeon_mode:
  populate_room()
 elif expedition:
  spawn_wave()
 else:
  for entry in [[0, Vector2(150,140)], [0, Vector2(800,140)], [1, Vector2(480,120)], [1, Vector2(820,300)], [2, Vector2(140,330)], [2, Vector2(480,250)]]:
   spawn_enemy(entry[0],entry[1])
 effect_layer = Node2D.new()
 world.add_child(effect_layer)
 effect_layer.draw.connect(draw_effects)
 apply_controls()
 controls.set_enabled(true)
 hud.show()
 update_health(player.stats.health, player.stats.max_health)
 update_counts()
 if dungeon_mode:
  chamber.modulate = [Color(1,1,1),Color(0.7,1,0.82),Color(0.9,0.75,1)][layout.floor_index]
  dungeon_map.layout = layout
  dungeon_map.show()
  dungeon_map.queue_redraw()
  floor_label.text = "Piso %d/3 · %s" % [layout.floor_index+1,FloorLayout.BIOMES[layout.floor_index]]
  floor_label.show()
  navigation.show()
  reward_room()
 if dungeon_mode:
  room_pickups = layout.rooms[layout.current].get("pickups",[])
  layout.rooms[layout.current].pickups = room_pickups
 else:
  room_pickups = []
 for data: Dictionary in room_pickups:
  if not data.get("collected",false): spawn_pickup(data)
 if not dungeon_mode and not expedition:
  spawn_pickup({"id":"crystal","position":Vector2(480,330),"collected":false,"chest":false})
 transitioning = false

func apply_controls() -> void:
 controls.scale_factor = Settings.values.control_scale
 controls.opacity = Settings.values.control_opacity
 controls.queue_redraw()

func update_health(current: float, maximum: float) -> void:
 health_label.text = "VIDA %d / %d" % [ceili(current), ceili(maximum)]
 health_bar.max_value = maximum
 health_bar.value = current

func update_counts() -> void:
 coins_label.text = "Óbolos %d" % coins
 enemies_label.text = ("O%d/5 · " % (wave+1) if expedition else "") + "Sombras %d" % enemies.size()

func spawn_player_bullet(origin: Vector2, direction: Vector2, stats: ActorStats) -> void:
 var inventory := player.relics
 var directions: Array[Vector2] = [direction]
 if inventory.has("crown"):
  directions.append(direction.rotated(-0.25))
  directions.append(direction.rotated(0.25))
 var origins: Array[Vector2] = [origin]
 if inventory.has("double"): origins = [origin-direction.orthogonal()*7,origin+direction.orthogonal()*7]
 var echoes: Array[Vector2] = [Vector2.ZERO]
 if inventory.mirror_active(): echoes.append(Vector2(40,0))
 for echo in echoes:
  for at in origins:
   for aim in directions:
    var before := bullets.size()
    spawn_bullet(at+echo,aim,stats.projectile_speed,stats.damage,stats.attack_range,false)
    if bullets.size() > before:
     var bullet: AbyssProjectile = bullets.back()
     bullet.pierce = 1 if inventory.has("pierce") else 0
     bullet.bounces = 1 if inventory.has("bounce") else 0
     for element in ["fire","ice","electric"]:
      if inventory.has(element): bullet.elements.append(element)

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
 update_relic_ui(delta)
 for i in range(hazards.size()-1,-1,-1):
  if not is_instance_valid(hazards[i]): hazards.remove_at(i)
 var targets := enemies.duplicate()
 for i in range(bullets.size()-1, -1, -1):
  var bullet := bullets[i]
  if not is_instance_valid(bullet) or bullet.expired:
   bullets.remove_at(i)
   continue
  var old := bullet.position
  bullet.advance(delta)
  # Sample travel at <= 5 px so fast bullets cannot pass through pillars/walls.
  var steps := maxi(1, ceili(old.distance_to(bullet.position) / 5.0))
  for step in range(1, steps + 1):
   var point := old.lerp(bullet.position, float(step) / steps)
   if projectile_blocked(point):
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
    if point.distance_to(player.position) < 18:
     player.take_damage(bullet.damage)
     bullet.expire()
     break
   else:
    for enemy in targets:
     if is_instance_valid(enemy) and not enemy.dead and not bullet.hits.has(enemy.get_instance_id()) and point.distance_to(enemy.position) < 20:
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

func on_enemy_defeated(enemy: AbyssEnemy, point: Vector2, reward: int) -> void:
 enemies.erase(enemy)
 coins += reward
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
   var point := door_point(neighbor)
   var open: bool = layout.rooms[layout.current].cleared
   effect_layer.draw_texture_rect(DOOR_ART,Rect2(point-Vector2(20,30),Vector2(40,50)),false,Color.WHITE if open else Color(0.7,0.5,0.6))
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
 if is_instance_valid(world):
  world.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
 controls.set_enabled(active)

func pause_game() -> void:
 if state != "playing": return
 state = "paused"
 set_world_active(false)
 var box := menu("Mareas en calma", "Partida en pausa")
 box.add_child(button("Continuar", resume_game))
 box.add_child(button("Reliquias",show_inventory))
 box.add_child(button("Prueba de carga (nueva)",start_benchmark))
 box.add_child(button("Opciones", func(): show_options("paused")))
 box.add_child(button("Menú principal", show_main_menu))

func resume_game() -> void:
 clear_panel()
 state = "playing"
 set_world_active(true)

func finish(won: bool) -> void:
 if state != "playing": return
 state = "victory" if won else "defeat"
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
 add_slider(box, "Tamaño de controles", "control_scale", 0.8, 1.25)
 add_slider(box, "Opacidad de controles", "control_opacity", 0.3, 1.0)
 var fps_toggle := CheckButton.new()
 fps_toggle.text = "Diagnóstico FPS"
 fps_toggle.button_pressed = Settings.values.get("diagnostics",false)
 fps_toggle.toggled.connect(func(value: bool): Settings.values.diagnostics = value)
 box.add_child(fps_toggle)
 box.add_child(label("Audio: aún no disponible en esta versión",14))
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

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
  if is_instance_valid(controls): controls.release_all()
  pause_game()
 if what == NOTIFICATION_WM_GO_BACK_REQUEST:
  if state == "menu" and panel is AnimatedMainMenu: panel.skip_intro()
  elif state in ["modes","credits"]: show_main_menu()
  elif state == "playing": pause_game()
  elif state == "paused": resume_game()

func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
  if state == "playing": pause_game()
  elif state == "paused": resume_game()

func show_credits() -> void:
 state = "credits"
 var box := menu("Créditos", "Abyss of Tears · Código y arte originales · MIT")
 var scroll := ScrollContainer.new()
 scroll.custom_minimum_size = Vector2(440, 220)
 box.add_child(scroll)
 var text := label("Motor: Godot 4.6.3 (MIT).\n\n" + FileAccess.get_file_as_string("res://assets/licenses/GODOT_LICENSE.txt") + "\n\nComponentes del motor:\n" + FileAccess.get_file_as_string("res://assets/licenses/GODOT_COPYRIGHT.txt"), 14)
 text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(text)
 box.add_child(button("Volver", show_main_menu))

func spawn_enemy(kind_id: int, point: Vector2, weak: bool = false) -> void:
 if state != "playing" or enemies.size() >= MAX_ENEMIES: return
 var enemy: AbyssEnemy = ENEMY.instantiate()
 enemy.kind = clampi(kind_id,0,19)
 enemy.weak = weak
 enemy.once = weak
 enemy.position = safe_point(point)
 enemy.target = player
 enemy.peers = enemies
 enemy.shot.connect(spawn_enemy_bullet)
 enemy.summon.connect(func(id: int, location: Vector2, small: bool): spawn_enemy(id, location, small))
 enemy.hazard.connect(spawn_hazard)
 enemy.defeated.connect(func(location: Vector2, reward: int): on_enemy_defeated(enemy, location, reward))
 world.add_child(enemy)
 enemies.append(enemy)
 update_counts()

func safe_point(point: Vector2) -> Vector2:
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
 if type == "wall" and point.distance_to(player.position) < 65: return
 var hazard := EnemyHazard.new()
 hazard.kind = type
 hazard.player = player
 hazard.position = point
 world.add_child(hazard)
 hazards.append(hazard)

func spawn_wave() -> void:
 var points := [Vector2(150,140),Vector2(800,140),Vector2(480,120),Vector2(820,300)]
 for i in range(4): spawn_enemy(wave * 4 + i,points[i])
 enemies_label.text = "Oleada %d/5" % (wave+1)

func clear_wave() -> void:
 if state != "playing" or not enemies.is_empty(): return
 # Resolve announced death explosions before allowing victory or the next wave.
 for node in world.get_children():
  if node is EnemyHazard and node.kind == "explosion":
   return
 if dungeon_mode:
  if not layout.rooms[layout.current].cleared:
   layout.rooms[layout.current].cleared = true
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
 if chamber.blocks(point): return true
 for node in hazards:
  if is_instance_valid(node) and node.kind == "wall" and point.distance_to(node.position) < 27: return true
 return false

func start_dungeon() -> void:
 dungeon_mode = true
 expedition = false
 dungeon_seed = randi()
 layout.generate(dungeon_seed,0)
 start_game()

func populate_room() -> void:
 var room: Dictionary = layout.rooms[layout.current]
 if room.cleared: return
 var rng := RandomNumberGenerator.new()
 rng.seed = dungeon_seed + layout.floor_index * 1000 + layout.current * 71
 var count := 3 + layout.floor_index
 if room.kind == "descent": count += 1
 var points := [Vector2(150,140),Vector2(800,140),Vector2(480,120),Vector2(820,300),Vector2(140,330),Vector2(480,250)]
 for i in range(count):
  var kind := rng.randi_range(0,[7,13,19][layout.floor_index])
  spawn_enemy(kind,points[i])
  enemies.back().health *= 1 + layout.floor_index * 0.3
  enemies.back().max_health = enemies.back().health

func reward_room() -> void:
 var room: Dictionary = layout.rooms[layout.current]
 if not room.cleared or room.rewarded or room.kind == "start": return
 room.rewarded = true
 var rng := RandomNumberGenerator.new()
 rng.seed = dungeon_seed + layout.floor_index * 101 + layout.current
 coins += rng.randi_range(2,5) + layout.floor_index
 if room.kind == "descent": floor_label.text += " · Salida abierta: Puertas / Piso"
 if not room.has("pickups"): room.pickups = []
 if room.kind == "treasure" or rng.randf() < float(RelicCatalog.DROP_SETTINGS.room_chance):
  var data := {"id":RelicCatalog.roll(rng,layout.floor_index),"position":Vector2(480,274),"chest":room.kind != "treasure" and rng.randf()<float(RelicCatalog.DROP_SETTINGS.chest_chance),"collected":false}
  if data.chest:
   var content := rng.randf()
   data.reward_kind = "coins" if content<float(RelicCatalog.DROP_SETTINGS.chest_coins) else "heal" if content<float(RelicCatalog.DROP_SETTINGS.chest_coins)+float(RelicCatalog.DROP_SETTINGS.chest_heal) else "relic"
  room.pickups.append(data)
  if is_instance_valid(effect_layer) and room_pickups == room.pickups: spawn_pickup(data)
 update_counts()

func door_point(neighbor: int) -> Vector2:
 var direction: Vector2i = layout.rooms[neighbor].cell-layout.rooms[layout.current].cell
 return Vector2(480,274)+Vector2(direction)*Vector2(410,185)

func check_doors() -> void:
 for neighbor: int in layout.rooms[layout.current].links:
  if player.position.distance_to(door_point(neighbor)) < 35:
   transitioning = true
   travel_to.call_deferred(neighbor)
   return

func travel_to(neighbor: int) -> void:
 if not dungeon_mode or state not in ["playing","doors"] or not layout.enter(neighbor):
  transitioning = false
  return
 start_game(true)

func show_doors() -> void:
 if not dungeon_mode or state != "playing": return
 state = "doors"
 set_world_active(false)
 var room: Dictionary = layout.rooms[layout.current]
 var box := menu("Piso %d · %s" % [layout.floor_index+1,FloorLayout.BIOMES[layout.floor_index]],"Limpia la habitación para abrir las puertas" if not room.cleared else "Elige una puerta o acércate a ella")
 if room.cleared:
  for neighbor: int in room.links:
   var difference: Vector2i = layout.rooms[neighbor].cell-room.cell
   var direction := "Norte" if difference.y < 0 else "Sur" if difference.y > 0 else "Este" if difference.x > 0 else "Oeste"
   box.add_child(button("Puerta " + direction,func(): travel_to(neighbor)))
  if room.kind == "descent":
   box.add_child(button("Descender" if layout.floor_index < 2 else "Salir del abismo",descend))
 box.add_child(button("Volver",resume_game))

func descend() -> void:
 if not dungeon_mode or state != "doors" or not layout.rooms[layout.current].cleared or layout.rooms[layout.current].kind != "descent": return
 if layout.floor_index == 2:
  state = "playing"
  finish(true)
  return
 layout.generate(dungeon_seed,layout.floor_index+1)
 start_game(true)

func restart_game() -> void:
 if dungeon_mode: start_dungeon()
 else: start_game()

func build_relic_ui() -> void:
 toast = HBoxContainer.new()
 toast.position = Vector2(285,435)
 toast.add_theme_constant_override("separation",10)
 ui.add_child(toast)
 toast_icon = TextureRect.new()
 toast_icon.custom_minimum_size = Vector2(42,42)
 toast_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 toast_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 toast.add_child(toast_icon)
 toast_label = label("",16)
 toast.add_child(toast_label)
 toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
 diagnostics = label("",14)
 diagnostics.position = Vector2(240,515)
 ui.add_child(diagnostics)

func spawn_pickup(data: Dictionary) -> RelicPickup:
 var pickup := RelicPickup.new()
 pickup.data = data
 pickup.player = player
 pickup.position = safe_point(data.get("position",Vector2(480,274)))
 pickup.quality = Settings.values.quality
 pickup.claimed.connect(collect_relic)
 world.add_child(pickup)
 pickups.append(pickup)
 return pickup

func collect_relic(pickup: RelicPickup) -> void:
 var kind: String = pickup.data.get("reward_kind","relic")
 if kind in ["coins","heal"]:
  if kind=="coins": coins += 5
  else: player.stats.health = minf(player.stats.max_health,player.stats.health+2)
  update_counts()
  update_health(player.stats.health,player.stats.max_health)
  toast_icon.texture = RelicPickup.COINS if kind=="coins" else RelicPickup.HEAL
  toast_label.text = "Óbolos del faro · +5 monedas" if kind=="coins" else "Tónico de sal · Recupera hasta 2 de vida"
  toast_timer = 2.8
  toast.show()
  player.pickup_pose = 1.0
  return
 var id: String = pickup.data.id
 var definition := RelicCatalog.definition(id)
 var added := player.relics.add(id,player.stats)
 if not added: coins += 3
 player.pickup_pose = 1.0
 player.queue_redraw()
 update_health(player.stats.health,player.stats.max_health)
 update_counts()
 toast_icon.texture = RelicCatalog.icon(id)
 toast_label.text = definition.name + " · " + RelicCatalog.RARITIES[definition.rarity] + "\n" + (definition.description if added else "Máximo alcanzado: +3 óbolos")
 toast_timer = 2.8
 toast.show()

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
 if "fire" in bullet.elements: enemy.burning = 3.0
 if "ice" in bullet.elements: enemy.slowed = 2.0
 enemy.take_damage(bullet.damage,bullet.direction)
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
 scroll.custom_minimum_size = Vector2(490,240)
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
  row.add_child(label("%s ×%d · %s\n%s" % [definition.name,player.relics.owned[id],RelicCatalog.RARITIES[definition.rarity],definition.description],16))
 box.add_child(button("Volver",func(): state="playing"; pause_game()))

func start_relic_room() -> void:
 dungeon_mode = false
 expedition = false
 start_game()
 for pickup in pickups: pickup.queue_free()
 pickups.clear()
 for enemy in enemies: enemy.queue_free()
 enemies.clear()
 # Keep victory pending until the player chooses to finish the laboratory.
 for i in range(RelicCatalog.DATA.size()):
  var point := Vector2(150+(i%7)*105,180+(i/7)*150)
  spawn_pickup({"id":RelicCatalog.DATA[i].id,"position":safe_point(point),"collected":false,"chest":i%3==0})
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
