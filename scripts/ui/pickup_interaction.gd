class_name PickupInteraction
extends PanelContainer

signal interact_requested(pickup: RelicPickup)
var target: RelicPickup
var text: Label
var action: Button
var art: TextureRect

func _ready() -> void:
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
 target=pickup
 if not is_instance_valid(target): hide(); return
 var price:=int(target.data.get("price",0))
 art.texture=target.icon()
 text.text=target.display_name()+(" · %d monedas" % price if price>0 else "")+"\n"+target.description()
 if price>0:
  action.text="COMPRAR"
  action.show()
 elif target.data.get("chest",false):
  action.text="ABRIR COFRE"+(" · 1 llave" if target.data.get("locked",false) else "")
  action.show()
 else:
  action.hide()
 action.disabled=not target.valid_reward() or (price<=0 and target.cooldown>0)
 show()
