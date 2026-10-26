class_name AnimatedMainMenu
extends PanelContainer

signal action_requested(action: String)
var stage: MenuBackdrop
var play_intro := true
var intro := MenuIntro.new()
var buttons: Dictionary = {}
var title: Label
var subtitle: Label
var hint: Label
var button_panel: PanelContainer
var darkness: ColorRect
var pending := ""
var pending_time := 0.0
var guard_time := 0.0
var transition_elapsed := 0.0
var suspended := false
var disabled_actions: Array[String] = []

func _ready() -> void:
 add_theme_stylebox_override("panel",StyleBoxEmpty.new())
 var content := Control.new()
 content.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(content)
 title = make_label("ABYSS OF\nTEARS",43)
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 title.add_theme_color_override("font_shadow_color",Color("060e1c"))
 title.add_theme_constant_override("shadow_offset_y",3)
 content.add_child(title)
 subtitle = make_label("EL FARO RECUERDA TU NOMBRE",17)
 subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(subtitle)
 hint = make_label("Toca para omitir la introducción",15)
 content.add_child(hint)
 button_panel = PanelContainer.new()
 var panel_style := StyleBoxFlat.new()
 panel_style.bg_color = Color(0.05,0.1,0.17,0.94)
 panel_style.border_color = Color("4b747f")
 panel_style.set_border_width_all(1)
 panel_style.set_corner_radius_all(15)
 panel_style.content_margin_left = 16
 panel_style.content_margin_right = 16
 panel_style.content_margin_top = 15
 panel_style.content_margin_bottom = 15
 button_panel.add_theme_stylebox_override("panel",panel_style)
 content.add_child(button_panel)
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",5)
 button_panel.add_child(box)
 box.add_child(make_label("ELIGE TU CAMINO",16))
 add_button(box,"NUEVA PARTIDA","new_game")
 add_button(box,"OPCIONES","options")
 add_button(box,"SALIR","exit")
 if OS.has_feature("web"):
  disabled_actions.append("exit")
  buttons.exit.text = "SALIR · NO DISPONIBLE EN WEB"
 box.add_child(make_label("0.5.0 · AVENTURA SIN CONEXIÓN",12))
 darkness = ColorRect.new()
 darkness.color = Color.BLACK
 darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
 darkness.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 content.add_child(darkness)
 if not play_intro: intro.skip()
 if is_instance_valid(stage):
  stage.intro_time = intro.elapsed
  if play_intro: stage.character.position=Vector2(-60,stage.center().y)
 resized.connect(layout_menu)
 layout_menu()
 refresh_visuals()

func make_label(text: String, font_size: int) -> Label:
 var label := Label.new()
 label.text = text
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",Color("d3ece6"))
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return label

func add_button(box: VBoxContainer, text: String, action: String) -> void:
 var button := Button.new()
 button.text = text
 button.custom_minimum_size = Vector2(280,44)
 button.add_theme_font_size_override("font_size",16)
 for variation in ["normal","hover","pressed","disabled","focus"]:
  var style := StyleBoxFlat.new()
  style.bg_color = Color("243e50") if variation in ["hover","focus"] else Color("345363") if variation=="pressed" else Color("142735")
  style.border_color = Color("b2d6c7") if variation in ["pressed","focus"] else Color("365968")
  style.set_border_width_all(1)
  style.set_corner_radius_all(6)
  button.add_theme_stylebox_override(variation,style)
 button.add_theme_color_override("font_disabled_color",Color("7c8e9e"))
 button.pressed.connect(func(): request_action(action))
 button.button_down.connect(func(): animate_button(button,Color("a8d9de")))
 button.button_up.connect(func(): animate_button(button,Color.WHITE))
 button.mouse_entered.connect(func(): animate_button(button,Color("d3f6ed")))
 button.mouse_exited.connect(func(): animate_button(button,Color.WHITE))
 button.focus_entered.connect(func(): animate_button(button,Color("d3f6ed")))
 button.focus_exited.connect(func(): animate_button(button,Color.WHITE))
 box.add_child(button)
 buttons[action]=button

func animate_button(button: Button, color: Color) -> void:
 if button.disabled: return
 var previous = button.get_meta("visual_tween") if button.has_meta("visual_tween") else null
 if previous is Tween and previous.is_valid(): previous.kill()
 var tween := create_tween()
 button.set_meta("visual_tween",tween)
 tween.tween_property(button,"self_modulate",color,0.1)

func layout_menu() -> void:
 if not is_instance_valid(title): return
 var insets := safe_insets()
 var left_width := maxf(440,size.x-360-insets.x-insets.z)
 if is_instance_valid(stage):
  stage.safe_left=insets.x
  stage.safe_right=insets.z
 title.position=Vector2(24+insets.x,35+insets.y)
 title.size=Vector2(left_width-48,110)
 subtitle.position=Vector2(24+insets.x,155+insets.y)
 subtitle.size=Vector2(left_width-48,28)
 hint.position=Vector2(24+insets.x,size.y-32-insets.w)
 button_panel.position=Vector2(size.x-340-insets.z,maxf(24,(size.y-270)*0.5)+insets.y)
 button_panel.size=Vector2(316,270)

func refresh_visuals() -> void:
 title.modulate.a=intro.title_alpha()
 subtitle.modulate.a=intro.title_alpha()*0.75
 button_panel.modulate.a=intro.buttons_alpha()
 darkness.color.a=intro.darkness()
 hint.text="Toca para omitir la introducción" if intro.active else "Neris · Guardián de las mareas"
 for action: String in buttons:
  buttons[action].disabled=intro.active or pending!="" or disabled_actions.has(action)
 if is_instance_valid(stage): stage.intro_time=intro.elapsed

func _process(delta: float) -> void:
 if suspended: return
 guard_time=maxf(0,guard_time-delta)
 var was_intro := intro.active
 intro.advance(delta)
 if pending!="":
  pending_time-=delta
  transition_elapsed+=delta
  button_panel.modulate.a=maxf(0.1,1-transition_elapsed*1.5)
  if pending_time<=0:
   var action := pending
   pending=""
   action_requested.emit(action)
   return
 elif was_intro: refresh_visuals()

func skip_intro() -> void:
 if not intro.active: return
 intro.skip()
 if is_instance_valid(stage): stage.character.position=stage.center()
 guard_time=0.2
 refresh_visuals()

func _input(event: InputEvent) -> void:
 var pointer := event is InputEventScreenTouch or event is InputEventMouseButton
 var pressed: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)
 if pointer and (intro.active or guard_time>0):
  if pressed: skip_intro()
  get_viewport().set_input_as_handled()
 elif intro.active and event is InputEventKey and event.pressed:
  skip_intro()
  get_viewport().set_input_as_handled()

func request_action(action: String) -> void:
 if intro.active or guard_time>0 or pending!="" or disabled_actions.has(action) or not buttons.has(action): return
 pending=action
 transition_elapsed=0
 pending_time=0.45 if action=="new_game" else 0.18
 if is_instance_valid(stage): stage.react(action)
 refresh_visuals()

func deactivate() -> void:
 pending=""
 if is_instance_valid(stage): stage.intro_time=MenuIntro.DURATION

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: suspended=true
 elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]: suspended=false

func safe_insets() -> Vector4:
 if not OS.has_feature("android"): return Vector4.ZERO
 var safe := Rect2(DisplayServer.get_display_safe_area())
 var window := Vector2(DisplayServer.window_get_size())
 if window.x<=0 or window.y<=0 or safe.size.x<=0: return Vector4.ZERO
 var ratio := size/window
 var origin := Vector2(DisplayServer.window_get_position())
 var local_start := (safe.position-origin).max(Vector2.ZERO)*ratio
 var local_end := (safe.end-origin).min(window)*ratio
 return Vector4(local_start.x,local_start.y,maxf(0,size.x-local_end.x),maxf(0,size.y-local_end.y))
