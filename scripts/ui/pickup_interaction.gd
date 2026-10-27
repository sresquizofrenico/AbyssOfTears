class_name PickupInteraction
extends PanelContainer

signal interact_requested(pickup: RelicPickup)
var target: RelicPickup
var text: Label
var action: Button
var art: TextureRect

func _ready() -> void:
 visibility_changed.connect(func():
  if not is_visible_in_tree(): cancel_touch())
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 var style:=StyleBoxFlat.new()
 style.bg_color=Color(0.06,0.12,0.18,0.96)
 style.border_color=Color("89ada6")
 style.set_border_width_all(1)
 style.set_corner_radius_all(12)
 style.set_content_margin_all(10)
 add_theme_stylebox_override("panel",style)
 var row:=HBoxContainer.new()
 row.add_theme_constant_override("separation",10)
 row.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(row)
 art=TextureRect.new()
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 art.custom_minimum_size=Vector2(44,44)
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 row.add_child(art)
 var box:=VBoxContainer.new()
 box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 box.mouse_filter=Control.MOUSE_FILTER_IGNORE
 row.add_child(box)
 text=Label.new()
 text.add_theme_font_size_override("font_size",16)
 text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 text.max_lines_visible=3
 text.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 text.mouse_filter=Control.MOUSE_FILTER_IGNORE
 box.add_child(text)
 action=Button.new()
 action.custom_minimum_size=Vector2(280,48)
 action.add_theme_font_size_override("font_size",20)
 action.pressed.connect(func():
  if is_instance_valid(target): interact_requested.emit(target))
 box.add_child(action)
 hide()

func present(pickup: RelicPickup) -> void:
 if pickup!=target: cancel_touch()
 target=pickup
 if not is_instance_valid(target): hide(); return
 var price:=int(target.data.get("price",0))
 art.texture=target.icon()
 text.text=target.display_name()+(" · "+target.rarity_label() if target.rarity_label()!="" else "")+(" · %d monedas" % price if price>0 else "")+"\n"+target.description()
 if price>0:
  action.text="LÍMITE ALCANZADO" if target.at_stack_limit() else "COMPRAR"
  action.show()
 elif target.data.get("chest",false):
  action.text="ABRIR COFRE"+(" · 1 llave" if target.data.get("locked",false) else "")
  action.show()
 else:
  action.hide()
 action.disabled=not target.valid_reward() or (price<=0 and target.cooldown>0) or (price>0 and target.at_stack_limit())
 if not action.visible or action.disabled: cancel_touch()
 show()

var touch_finger := -1
var pressed_target: RelicPickup

func cancel_touch() -> void:
 touch_finger=-1
 pressed_target=null
 if is_instance_valid(action): action.self_modulate=Color.WHITE

func _input(event: InputEvent) -> void:
 if not is_visible_in_tree() or not action.visible or action.disabled: return
 var rect:=action.get_global_rect()
 if event is InputEventScreenTouch:
  if event.pressed and rect.has_point(event.position):
   if touch_finger==-1:
    touch_finger=event.index
    pressed_target=target
    action.self_modulate=Color("a8d9de")
   get_viewport().set_input_as_handled()
  elif not event.pressed and event.index==touch_finger:
   var confirmed:=rect.has_point(event.position) and is_instance_valid(pressed_target) and pressed_target==target
   cancel_touch()
   get_viewport().set_input_as_handled()
   if confirmed: interact_requested.emit(target)
 elif event is InputEventScreenDrag and event.index==touch_finger:
  get_viewport().set_input_as_handled()
 # Touch is handled above, including non-primary fingers. Suppress its duplicate
 # mouse emulation here; real mouse input remains available for desktop/tests.
 elif event is InputEventMouseButton and event.device==InputEvent.DEVICE_ID_EMULATION and rect.has_point(event.position):
  get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: cancel_touch()
