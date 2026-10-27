class_name CharacterSelection
extends PanelContainer

signal begin_requested(id: String)
signal back_requested
var entries: Array = CharacterCatalog.DATA.duplicate(true)
var index := 0
var character: MenuCharacter
var heading: Label
var details: Label
var status: Label
var begin_button: Button
var back_button: Button
var left_button: Button
var right_button: Button
var plate: Panel
var clock := 0.0
var pending := false
var remaining := 0.0
var slide: Tween
var suspended := false
var seal: UnlockSeal
var counter_label: Label
var stat_bars: Array[ProgressBar] = []
var preview_unlocked := false
var reveal_age := 0.0

func _ready() -> void:
 var style := StyleBoxFlat.new()
 style.bg_color = Color("101a27")
 add_theme_stylebox_override("panel",style)
 var canvas := Control.new()
 canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(canvas)
 heading = make_label("",27)
 canvas.add_child(heading)
 plate = Panel.new()
 var parchment := StyleBoxTexture.new()
 parchment.texture=preload("res://assets/illustrated/journal.svg")
 plate.add_theme_stylebox_override("panel",parchment)
 canvas.add_child(plate)
 details = make_label("",15)
 details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 plate.add_child(details)
 details.minimum_size_changed.connect(func(): details.set_deferred("size",plate.size-Vector2(60,40)))
 var icons := [preload("res://assets/ui/life.svg"),preload("res://assets/ui/damage.svg"),preload("res://assets/ui/speed.svg"),preload("res://assets/ui/cadence.svg"),preload("res://assets/ui/range.svg"),preload("res://assets/ui/luck.svg"),preload("res://assets/ui/defense.svg")]
 for i in range(icons.size()):
  var icon := TextureRect.new()
  icon.texture = icons[i]
  icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.position = Vector2(-34,i*26+2)
  icon.size = Vector2(22,22)
  icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
  details.add_child(icon)
 for i in range(7):
  var bar:=ProgressBar.new()
  bar.show_percentage=false
  bar.max_value=100
  bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
  bar.size=Vector2(46,4)
  details.add_child(bar)
  stat_bars.append(bar)
 status = make_label("",17)
 status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 canvas.add_child(status)
 seal=UnlockSeal.new()
 status.add_child(seal)
 counter_label = make_label("",18)
 canvas.add_child(counter_label)
 character = MenuCharacter.new()
 character.body_texture = IllustratedNeris.BODY
 canvas.add_child(character)
 begin_button = make_button("COMENZAR",start)
 back_button = make_button("VOLVER",func():
  if not pending: back_requested.emit())
 left_button = make_button("‹",func(): select_offset(-1))
 right_button = make_button("›",func(): select_offset(1))
 for node in [begin_button,back_button,left_button,right_button]: canvas.add_child(node)
 resized.connect(layout_selection)
 refresh()
 layout_selection()

func make_label(text: String, font_size: int) -> Label:
 var node := Label.new()
 node.text = text
 node.add_theme_font_size_override("font_size",font_size)
 node.add_theme_color_override("font_color",Color("dfdfc8"))
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return node

func make_button(text: String, callback: Callable) -> Button:
 var node := Button.new()
 node.text = text
 node.add_theme_font_size_override("font_size",22)
 var style := StyleBoxFlat.new()
 style.bg_color = Color("243e50")
 style.border_color = Color("85b6b2")
 style.set_border_width_all(2)
 style.set_corner_radius_all(10)
 node.add_theme_stylebox_override("normal",style)
 var pressed := style.duplicate()
 pressed.bg_color = Color("3c626c")
 node.add_theme_stylebox_override("pressed",pressed)
 node.custom_minimum_size = Vector2(64,52)
 node.pressed.connect(callback)
 return node

func refresh() -> void:
 if entries.is_empty():
  begin_button.disabled = true
  return
 var entry: Dictionary = entries[index]
 var unlocked: bool = entry.get("unlocked",true) and CharacterCatalog.playable(entry.id)
 preview_unlocked=unlocked
 heading.text = entry.name if unlocked else "Viajero sellado"
 character.animation_rate=float(entry.get("animation_rate",1.0))
 counter_label.text = "%d / %d" % [index+1,entries.size()]
 character.body_texture = CharacterCatalog.texture(entry.id)
 reveal_age=0.0
 var progress := CharacterCatalog.progress_node()
 if unlocked and progress and progress.data.pending.has(entry.id):
  reveal_age=1.4
  progress.acknowledge(entry.id)
 status.text = entry.get("requirement","") if not unlocked else "Disponible · El abismo espera tus pasos"
 character.modulate = Color.WHITE if unlocked else Color(0,0,0,1)
 begin_button.disabled = not unlocked or pending
 if not unlocked and progress and entry.get("target",0)>0:
  status.text += "\nProgreso: %d / %d" % [mini(progress.amount(entry.counter),int(entry.target)),entry.target]
 status.text = ("DESBLOQUEADO\n" if unlocked else "BLOQUEADO\n")+status.text
 var stats: ActorStats = CharacterCatalog.preview_stats(entry.id)
 if stats != null and unlocked:
  details.text = "VIDA       %d / %d\nDAÑO       %.2f\nMOV.       %.0f px/s\nCADENCIA   %.2f/s\nALCANCE    %.0f px\nSUERTE     %.2f\nDEFENSA    %.2f\n\n%s · %.0f s\n+ %s\n− %s\n%s · Objetos: ninguno" % [stats.health,stats.max_health,stats.damage,stats.speed,1.0/stats.attack_interval,stats.attack_range,stats.luck,stats.defense,entry.ability,entry.cooldown,entry.advantages,entry.drawbacks,entry.difficulty]
 else: details.text = "PERSONAJE BLOQUEADO\n\n" + entry.get("requirement","")
 if not unlocked and entry.id in ["vex","orin"]:
  details.text += "\n\nEl contenido necesario para completar este desafío llegará en otra entrega."
 for bar in stat_bars: bar.visible=unlocked
 for i in range(7): details.get_child(i).visible=unlocked
 if stats and unlocked:
  var values: Array=[stats.max_health/10.0,stats.damage/2.0,stats.speed/260.0,(1.0/stats.attack_interval)/6.0,stats.attack_range/700.0,(stats.luck+1)/3.0,(stats.defense+0.25)/1.0]
  var baseline:=CharacterCatalog.preview_stats("neris")
  var normals: Array=[baseline.max_health,baseline.damage,baseline.speed,1.0/baseline.attack_interval,baseline.attack_range,baseline.luck,baseline.defense]
  var actual: Array=[stats.max_health,stats.damage,stats.speed,1.0/stats.attack_interval,stats.attack_range,stats.luck,stats.defense]
  for i in range(7):
   stat_bars[i].value=clampf(values[i]*100,0,100)
   var fill:=StyleBoxFlat.new()
   fill.bg_color=Color("74c69a") if actual[i]>normals[i] else Color("d7898d") if actual[i]<normals[i] else Color("9cabb4")
   stat_bars[i].add_theme_stylebox_override("fill",fill)
 left_button.visible = entries.size()>1
 right_button.visible = entries.size()>1

func layout_selection() -> void:
 if not is_instance_valid(character): return
 var inset := 28.0
 if OS.has_feature("android"):
  var safe := Rect2(DisplayServer.get_display_safe_area())
  var window := Vector2(DisplayServer.window_get_size())
  if window.x>0 and safe.size.x>0:
   var origin := Vector2(DisplayServer.window_get_position())
   inset = maxf(inset,maxf(safe.position.x-origin.x,window.x-(safe.end.x-origin.x))*size.x/window.x+12)
 heading.position=Vector2(size.x*0.35,26)
 heading.size=Vector2(size.x*0.34,52)
 heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 character.position=Vector2(size.x*0.54,size.y*0.53)
 character.scale=Vector2(1.65,1.65)
 plate.position=Vector2(inset,84)
 plate.size=Vector2(size.x*0.3-inset*0.35,size.y-106)
 details.position=Vector2(42,24)
 details.size=plate.size-Vector2(60,40)
 details.add_theme_font_size_override("font_size",15)
 var line_height:=details.get_theme_font("font").get_height(15)+details.get_theme_constant("line_spacing")
 for i in range(7):
  details.get_child(i).position.y=i*line_height+2
  stat_bars[i].position=Vector2(details.size.x-46,i*line_height+16)
 status.position=Vector2(size.x-218-inset*0.2,142)
 status.size=Vector2(190,160)
 counter_label.position=Vector2(size.x*0.48,size.y-78)
 counter_label.size=Vector2(120,30)
 counter_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 seal.position=Vector2(75,-52)
 seal.size=Vector2(40,40)
 begin_button.position=Vector2(size.x-218-inset*0.2,size.y-192)
 begin_button.size=Vector2(190,58)
 back_button.position=Vector2(size.x-218-inset*0.2,size.y-116)
 back_button.size=Vector2(190,52)
 left_button.position=Vector2(size.x*0.34,size.y*0.5-26)
 right_button.position=Vector2(size.x*0.69,size.y*0.5-26)
 queue_redraw()

func select_offset(offset: int) -> void:
 if pending or entries.size()<2: return
 index = posmod(index+offset,entries.size())
 refresh()
 if slide != null and slide.is_valid(): slide.kill()
 var resting := Vector2(size.x*0.54,size.y*0.53)
 character.position = resting+Vector2(offset*24,0)
 slide = create_tween()
 slide.tween_property(character,"position",resting,0.18).set_trans(Tween.TRANS_SINE)

func start() -> void:
 if pending or entries.is_empty(): return
 var entry: Dictionary = entries[index]
 if not entry.get("unlocked",true) or not CharacterCatalog.playable(entry.id): return
 pending = true
 remaining = 0.42
 begin_button.disabled = true
 back_button.disabled = true
 left_button.disabled = true
 right_button.disabled = true

func _process(delta: float) -> void:
 if suspended: return
 clock += delta
 character.clock += delta
 reveal_age=maxf(0,reveal_age-delta)
 if preview_unlocked:
  character.modulate=Color(0,0,0,1).lerp(Color.WHITE,clampf(1.0-reveal_age/1.4,0,1)) if reveal_age>0 else Color.WHITE
  character.scale=Vector2.ONE*(1.65+sin(reveal_age*PI/1.4)*0.08)
 seal.visible=not preview_unlocked or reveal_age>0
 seal.reveal=1.0-reveal_age/1.4 if reveal_age>0 else 0.0
 seal.queue_redraw()
 character.pose = "present" if pending or reveal_age>0 else "attack" if fmod(clock*character.animation_rate,7)>6.4 else "rest"
 character.look = Vector2(sin(clock*0.7)*0.5,0.4).normalized()
 character.queue_redraw()
 if pending:
  remaining -= delta
  character.position.x += delta*75
  plate.modulate.a = maxf(0,remaining/0.42)
  if remaining<=0:
   set_process(false)
   begin_requested.emit(entries[index].id)
 queue_redraw()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: suspended=true
 elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]: suspended=false

func _draw() -> void:
 # Shared original dungeon textures, one draw per surface, no light nodes.
 draw_texture_rect(MenuBackdrop.FLOOR,Rect2(Vector2.ZERO,size),false,Color(0.4,0.48,0.58))
 if not preview_unlocked:
  draw_circle(Vector2(size.x*0.54,size.y*0.53-45),105,Color(0.4,0.53,0.65,0.3))
 var center := Vector2(size.x*0.54,size.y*0.53+74)
 draw_set_transform(center,0,Vector2(1,0.3))
 draw_circle(Vector2.ZERO,130,Color(0.1,0.18,0.25,0.8))
 draw_arc(Vector2.ZERO,125,0,TAU,64,Color("637b83"),3,true)
 draw_set_transform(Vector2.ZERO)
