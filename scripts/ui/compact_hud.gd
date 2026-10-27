class_name CompactHUD
extends Control

signal pause_requested
signal doors_requested
signal preference_failed

const ICONS = {"life":preload("res://assets/ui/life.svg"),"coins":preload("res://assets/relics/coins.svg"),"keys":preload("res://assets/relics/key.svg"),"shadows":preload("res://assets/ui/shadows.svg"),"damage":preload("res://assets/ui/damage.svg"),"speed":preload("res://assets/ui/speed.svg"),"cadence":preload("res://assets/ui/cadence.svg"),"range":preload("res://assets/ui/range.svg"),"luck":preload("res://assets/ui/luck.svg"),"defense":preload("res://assets/ui/defense.svg"),"projectile":preload("res://assets/ui/projectile.svg"),"critical":preload("res://assets/ui/critical.svg")}
const STAT_KEYS = ["damage","cadence","speed","range","luck","defense","projectile","critical"]
const NAMES = {"damage":"Daño","cadence":"Cadencia","speed":"Movimiento","range":"Alcance","luck":"Suerte","defense":"Defensa","projectile":"Vel. proyectil","critical":"Crítico"}
const UNITS = {"damage":"","cadence":"/s","speed":"px/s","range":"px","luck":"","defense":"","projectile":"px/s","critical":"%"}
var health_label: Label
var health_bar: ProgressBar
var coins_label: Label
var keys_label: Label
var enemies_label: Label
var pause_button: Button
var stats_button: Button
var doors_button: Button
var row: HBoxContainer
var wave_label: Label
var wave_cell: HBoxContainer
var compact: HBoxContainer
var detail: PanelContainer
var stats_labels: Dictionary={}
var compact_labels: Dictionary={}
var change_labels: Dictionary={}
var changes: Dictionary={}
var previous: Dictionary={}
var view := 0 # 0: three main stats, 1: expanded, 2: hidden
var playing:=false
var touch_buttons: Dictionary={}
var last_control_scale:=1.0

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 var settings:=get_tree().root.get_node("Settings")
 view=int(settings.values.get("stats_view",0))
 row=HBoxContainer.new()
 row.mouse_filter=Control.MOUSE_FILTER_IGNORE
 row.add_theme_constant_override("separation",8)
 add_child(row)
 var life:=HBoxContainer.new()
 life.add_theme_constant_override("separation",4)
 life.add_child(icon("life",24))
 var life_text:=VBoxContainer.new()
 life_text.add_theme_constant_override("separation",1)
 health_label=make_label("6/6",17)
 health_label.custom_minimum_size.x=64
 life_text.add_child(health_label)
 health_bar=ProgressBar.new()
 health_bar.custom_minimum_size=Vector2(66,5)
 health_bar.show_percentage=false
 var fill:=StyleBoxFlat.new()
 fill.bg_color=Color("93d8c9")
 fill.set_corner_radius_all(2)
 health_bar.add_theme_stylebox_override("fill",fill)
 life_text.add_child(health_bar)
 life.add_child(life_text)
 row.add_child(life)
 coins_label=resource_cell("coins","Óbolos: dinero disponible")
 keys_label=resource_cell("keys","Llaves disponibles")
 enemies_label=resource_cell("shadows","Enemigos activos en la habitación")
 pause_button=make_button("Ⅱ","Pausa")
 stats_button=make_button("","Estadísticas: ampliar u ocultar")
 stats_button.icon=preload("res://assets/ui/stats.svg")
 stats_button.expand_icon=true
 stats_button.add_theme_constant_override("icon_max_width",25)
 doors_button=make_button("","Puertas y cambio de piso")
 doors_button.icon=preload("res://assets/illustrated/door.svg")
 doors_button.expand_icon=true
 doors_button.add_theme_constant_override("icon_max_width",24)
 for node: Button in [pause_button,stats_button,doors_button]: row.add_child(node)
 pause_button.pressed.connect(func(): pause_requested.emit())
 doors_button.pressed.connect(func(): doors_requested.emit())
 stats_button.pressed.connect(cycle_view)
 compact=HBoxContainer.new()
 compact.mouse_filter=Control.MOUSE_FILTER_IGNORE
 compact.add_theme_constant_override("separation",12)
 add_child(compact)
 for key: String in STAT_KEYS.slice(0,3):
  var cell:=HBoxContainer.new()
  cell.mouse_filter=Control.MOUSE_FILTER_IGNORE
  cell.add_theme_constant_override("separation",3)
  cell.add_child(icon(key,18))
  var number:=make_label("",16)
  cell.add_child(number)
  compact.add_child(cell)
  compact_labels[key]=number
 wave_cell=HBoxContainer.new()
 wave_cell.mouse_filter=Control.MOUSE_FILTER_IGNORE
 wave_cell.add_child(icon("cadence",18))
 wave_label=make_label("",15)
 wave_cell.add_child(wave_label)
 add_child(wave_cell)
 wave_cell.hide()
 detail=PanelContainer.new()
 var style:=StyleBoxFlat.new()
 style.bg_color=Color(0.035,0.075,0.12,0.58)
 style.border_color=Color("4d777d")
 style.set_border_width_all(1)
 style.set_corner_radius_all(10)
 style.set_content_margin_all(6)
 detail.add_theme_stylebox_override("panel",style)
 detail.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(detail)
 var box:=VBoxContainer.new()
 box.mouse_filter=Control.MOUSE_FILTER_IGNORE
 box.add_theme_constant_override("separation",1)
 detail.add_child(box)
 box.add_child(make_label("ESTADÍSTICAS REALES",14))
 for key: String in STAT_KEYS:
  var cell:=HBoxContainer.new()
  cell.mouse_filter=Control.MOUSE_FILTER_IGNORE
  cell.add_theme_constant_override("separation",6)
  cell.add_child(icon(key,18))
  var name_label:=make_label(NAMES[key],15)
  name_label.custom_minimum_size.x=92
  cell.add_child(name_label)
  var number:=make_label("",16)
  number.custom_minimum_size.x=78
  cell.add_child(number)
  var change:=make_label("",14)
  cell.add_child(change)
  stats_labels[key]=number
  change_labels[key]=change
  box.add_child(cell)
 visibility_changed.connect(func():
  if not is_visible_in_tree(): cancel_touches())
 layout_hud()
 apply_view()

func make_label(text: String, font_size: int) -> Label:
 var node:=Label.new()
 node.text=text
 node.add_theme_font_size_override("font_size",font_size)
 node.add_theme_color_override("font_color",Color("d6ede1"))
 node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return node

func icon(key: String, dimension: float) -> TextureRect:
 var node:=TextureRect.new()
 node.texture=ICONS[key]
 node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 node.custom_minimum_size=Vector2(dimension,dimension)
 node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return node

func resource_cell(key: String, description: String) -> Label:
 var cell:=HBoxContainer.new()
 cell.add_theme_constant_override("separation",3)
 cell.mouse_filter=Control.MOUSE_FILTER_IGNORE
 cell.add_child(icon(key,23))
 var number:=make_label("0",18)
 number.custom_minimum_size.x=32
 number.tooltip_text=description
 cell.add_child(number)
 row.add_child(cell)
 return number

func make_button(text: String, description: String) -> Button:
 var node:=Button.new()
 node.text=text
 node.tooltip_text=description
 node.custom_minimum_size=Vector2(44,44)
 node.add_theme_font_size_override("font_size",22)
 var style:=StyleBoxFlat.new()
 style.bg_color=Color("182d3b")
 style.border_color=Color("497078")
 style.set_border_width_all(1)
 style.set_corner_radius_all(8)
 node.add_theme_stylebox_override("normal",style)
 return node

func layout_hud(control_scale:=1.0) -> void:
 var width:=get_viewport().get_visible_rect().size.x
 var inset:=16.0
 if OS.has_feature("android"):
  var safe:=Rect2(DisplayServer.get_display_safe_area())
  var window:=Vector2(DisplayServer.window_get_size())
  if window.x>0 and safe.size.x>0:
   inset=maxf(inset,(safe.position.x-DisplayServer.window_get_position().x)*width/window.x+6)
 row.position=Vector2(inset,3)
 compact.position=Vector2(inset,50)
 wave_cell.position=Vector2(inset+270,50)
 # Optional glass panel leaves all four physical doorway positions clear.
 detail.position=Vector2((width-960)*0.5+175,(get_viewport().get_visible_rect().size.y-540)*0.5+118)
 detail.size=Vector2(280,218)
 last_control_scale=control_scale

func set_health(current: float, maximum: float) -> void:
 health_label.text=short_number(current)+"/"+short_number(maximum)
 health_bar.max_value=maximum
 health_bar.value=current

func set_counts(coins: int, keys: int, enemies: int, wave: int=-1) -> void:
 coins_label.text=str(coins)
 keys_label.text=str(keys)
 enemies_label.text=str(enemies)
 wave_cell.visible=wave>=0
 wave_label.text="%d/5" % (wave+1) if wave>=0 else ""
 enemies_label.tooltip_text="Enemigos activos: %d" % enemies+(" · Oleada %d/5" % (wave+1) if wave>=0 else "")

func short_number(value: float) -> String:
 return str(int(value)) if is_equal_approx(value,roundf(value)) else ("%.2f" % value).trim_suffix("0")

func values_from(stats: ActorStats) -> Dictionary:
 return {"damage":stats.damage,"cadence":1.0/stats.attack_interval,"speed":stats.speed,"range":stats.attack_range,"luck":stats.luck,"defense":stats.defense,"projectile":stats.projectile_speed,"critical":stats.critical_chance*100}

func bind_stats(stats: ActorStats) -> void:
 previous.clear()
 changes.clear()
 for key: String in change_labels:
  change_labels[key].text=""
  stats_labels[key].add_theme_color_override("font_color",Color("d6ede1"))
  if compact_labels.has(key): compact_labels[key].add_theme_color_override("font_color",Color("d6ede1"))
 refresh_stats(stats)

func refresh_stats(stats: ActorStats, delta:=0.0) -> void:
 var current:=values_from(stats)
 for key: String in STAT_KEYS:
  var value: float=current[key]
  var changed:=previous.has(key) and not is_equal_approx(value,float(previous[key]))
  if previous.has(key) and not changed and not changes.has(key): continue
  if changed:
   changes[key]={"before":float(previous[key]),"after":value,"life":2.8}
  var suffix: String=UNITS[key]
  var formatted: String=("%.2f" % value if key in ["damage","cadence","luck","defense"] else short_number(value))+suffix
  if stats_labels[key].text!=formatted: stats_labels[key].text=formatted
  if compact_labels.has(key) and compact_labels[key].text!=formatted: compact_labels[key].text=formatted
  if changes.has(key):
   changes[key].life-=delta
   if changes[key].life<=0:
    changes.erase(key)
    change_labels[key].text=""
    stats_labels[key].add_theme_color_override("font_color",Color("d6ede1"))
    if compact_labels.has(key): compact_labels[key].add_theme_color_override("font_color",Color("d6ede1"))
   else:
    var difference: float=changes[key].after-changes[key].before
    var color:=Color("a2e2b3") if difference>0 else Color("f3a7a3")
    change_labels[key].text=("+" if difference>0 else "")+short_number(difference)
    if changed:
     change_labels[key].add_theme_color_override("font_color",color)
     stats_labels[key].add_theme_color_override("font_color",color)
     if compact_labels.has(key): compact_labels[key].add_theme_color_override("font_color",color)
  previous[key]=value

func cycle_view() -> void:
 if not playing: return
 var old:=view
 view=(view+1)%3
 var settings:=get_tree().root.get_node("Settings")
 settings.values.stats_view=view
 if settings.save_settings()!=OK:
  view=old
  settings.values.stats_view=old
  preference_failed.emit()
 apply_view()

func apply_view() -> void:
 compact.visible=view!=2 and playing
 detail.visible=view==1 and playing
 stats_button.tooltip_text=["Ampliar estadísticas","Ocultar estadísticas","Mostrar estadísticas"][view]

func set_playing(active: bool) -> void:
 playing=active
 doors_button.disabled=not active
 stats_button.disabled=not active
 cancel_touches()
 apply_view()

func cancel_touches() -> void:
 for button: Button in touch_buttons.values():
  if is_instance_valid(button): button.self_modulate=Color.WHITE
 touch_buttons.clear()

func _input(event: InputEvent) -> void:
 if not is_visible_in_tree(): return
 var buttons: Array[Button]=[pause_button,stats_button,doors_button]
 if event is InputEventScreenTouch:
  if event.pressed:
   for button: Button in buttons:
    if button.visible and not button.disabled and button.get_global_rect().has_point(event.position):
     touch_buttons[event.index]=button
     button.self_modulate=Color("a8d9de")
     get_viewport().set_input_as_handled()
     break
  elif touch_buttons.has(event.index):
   var button: Button=touch_buttons[event.index]
   touch_buttons.erase(event.index)
   button.self_modulate=Color.WHITE
   get_viewport().set_input_as_handled()
   if not button.disabled and button.get_global_rect().has_point(event.position): button.pressed.emit()
 elif event is InputEventScreenDrag and touch_buttons.has(event.index): get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton and event.device==InputEvent.DEVICE_ID_EMULATION:
  for button: Button in buttons:
   if button.visible and button.get_global_rect().has_point(event.position): get_viewport().set_input_as_handled(); break

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: cancel_touches()
