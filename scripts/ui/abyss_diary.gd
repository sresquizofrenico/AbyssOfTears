class_name AbyssDiary
extends PanelContainer
signal close_requested
var snapshot: Dictionary={"items":[],"journal":AbyssJournal.fresh()}
var category: String="floors"
var page:=0
var navigation: VBoxContainer
var content: VBoxContainer
var scroll: ScrollContainer
var heading: Label
var summary: Label
var paging: Label
var previous: Button
var next: Button
var back: Button
var buttons: Dictionary={}
var touch_finger: int=-1
var touch_button: Button
var touch_origin:=Vector2.ZERO
var touch_moved:=false
var touch_scroll: ScrollContainer
var scroll_start:=0
const PAGE_SIZE:=4

func text(value: String, font_size: int) -> Label:
 var node:=Label.new()
 node.add_theme_font_size_override("font_size",font_size)
 node.add_theme_color_override("font_color",Color("d4ece5"))
 node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 node.text=value
 node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return node

func action(caption: String, callable: Callable) -> Button:
 var node:=Button.new()
 node.text=caption
 node.custom_minimum_size=Vector2(180,46)
 node.add_theme_font_size_override("font_size",17)
 node.pressed.connect(callable)
 return node

func _ready() -> void:
 var paper:=StyleBoxFlat.new()
 paper.bg_color=Color("101f2e")
 paper.border_color=Color("6f9696")
 paper.set_border_width_all(2)
 add_theme_stylebox_override("panel",paper)
 var canvas:=Control.new()
 canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(canvas)
 var title:=text("DIARIO DEL ABISMO",28)
 title.position=Vector2(26,16)
 title.size=Vector2(630,42)
 canvas.add_child(title)
 summary=text("Solo hallazgos de expediciones reales · recuerdos permanentes",14)
 summary.position=Vector2(28,60)
 canvas.add_child(summary)
 var tabs:=ScrollContainer.new()
 tabs.position=Vector2(24,98)
 tabs.size=Vector2(214,348)
 tabs.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 canvas.add_child(tabs)
 navigation=VBoxContainer.new()
 navigation.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 navigation.add_theme_constant_override("separation",5)
 tabs.add_child(navigation)
 for key: String in AbyssJournal.CATEGORIES:
  var button:=action(AbyssJournal.TITLES[key]+(" · pronto" if key=="machines" else ""),func(): select_category(key))
  button.add_theme_font_size_override("font_size",16)
  buttons[key]=button
  navigation.add_child(button)
 heading=text("",22)
 heading.position=Vector2(260,98)
 canvas.add_child(heading)
 scroll=ScrollContainer.new()
 scroll.position=Vector2(260,145)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 canvas.add_child(scroll)
 content=VBoxContainer.new()
 content.add_theme_constant_override("separation",10)
 content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(content)
 previous=action("← Anteriores",func(): page-=1; refresh())
 next=action("Siguientes →",func(): page+=1; refresh())
 paging=text("",16)
 paging.autowrap_mode=TextServer.AUTOWRAP_OFF
 paging.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 paging.size=Vector2(120,32)
 canvas.add_child(previous)
 canvas.add_child(next)
 canvas.add_child(paging)
 back=action("VOLVER",func(): close_requested.emit())
 back.position=Vector2(26,470)
 canvas.add_child(back)
 resized.connect(layout_diary)
 layout_diary()
 refresh()

func layout_diary() -> void:
 if not is_instance_valid(scroll): return
 scroll.size=Vector2(maxf(400,size.x-294),280)
 heading.size=Vector2(scroll.size.x,40)
 previous.position=Vector2(260,452)
 next.position=Vector2(size.x-214,452)
 paging.position=Vector2(460,462)
 summary.size=Vector2(size.x-56,30)

func select_category(value: String) -> void:
 if value not in AbyssJournal.CATEGORIES: return
 category=value
 page=0
 refresh()

func refresh() -> void:
 for child in content.get_children(): content.remove_child(child); child.queue_free()
 var records:=AbyssJournal.entries(snapshot,category)
 var pages:=maxi(1,ceili(records.size()/float(PAGE_SIZE)))
 page=clampi(page,0,pages-1)
 heading.text=AbyssJournal.TITLES[category]+" · %d" % records.size()
 paging.text="%d / %d" % [page+1,pages]
 previous.disabled=page==0
 next.disabled=page>=pages-1
 for key: String in buttons: buttons[key].disabled=key==category or key=="machines"
 if records.is_empty():
  var message: String="Todavía no hay hallazgos registrados. Explora una expedición para añadirlos."
  if category=="machines": message="La reparación de máquinas aún no está implementada. No se registran reparaciones ficticias."
  elif category=="maps": message="Visita todas las habitaciones de un piso, incluida la secreta. Cada piso diferente cuenta una vez."
  content.add_child(text(message,18))
 for i in range(page*PAGE_SIZE,mini(records.size(),(page+1)*PAGE_SIZE)):
  var id: String=records[i]
  var row:=HBoxContainer.new()
  row.custom_minimum_size.y=74
  row.add_theme_constant_override("separation",12)
  content.add_child(row)
  if category in ["items","artifacts"]:
   var icon:=TextureRect.new()
   icon.texture=RelicCatalog.icon(id) if category=="items" else load(ArchaeologyCatalog.definition(id).icon) as Texture2D
   icon.custom_minimum_size=Vector2(48,48)
   icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
   icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   row.add_child(icon)
  var details:=VBoxContainer.new()
  details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  row.add_child(details)
  details.add_child(text(AbyssJournal.title(category,id),18))
  details.add_child(text(AbyssJournal.description(category,id),15))
 scroll.scroll_vertical=0

func cancel_touch() -> void:
 if is_instance_valid(touch_button): touch_button.self_modulate=Color.WHITE
 touch_button=null
 touch_finger=-1
 touch_moved=false
 touch_scroll=null

func _input(event: InputEvent) -> void:
 if not is_visible_in_tree(): return
 if event is InputEventMouseButton and event.device==InputEvent.DEVICE_ID_EMULATION:
  get_viewport().set_input_as_handled()
 elif event is InputEventScreenTouch:
  if event.pressed and touch_finger<0:
   for container: ScrollContainer in [navigation.get_parent(),scroll]:
    if container.get_global_rect().has_point(event.position):
     touch_finger=event.index
     touch_scroll=container
     touch_origin=event.position
     scroll_start=container.scroll_vertical
     break
   var candidates: Array=[previous,next,back]
   candidates.append_array(buttons.values())
   for button: Button in candidates:
    if button.disabled or not button.is_visible_in_tree() or not button.get_global_rect().has_point(event.position): continue
    # Do not capture clipped navigation rows outside their scroll area.
    if buttons.values().has(button) and not navigation.get_parent().get_global_rect().has_point(event.position): continue
    touch_finger=event.index
    touch_button=button
    touch_origin=event.position
    button.self_modulate=Color("a8d9de")
    break
   if touch_finger==event.index: get_viewport().set_input_as_handled()
  elif not event.pressed and event.index==touch_finger:
   var selected:=touch_button
   var confirmed: bool=is_instance_valid(selected) and not selected.disabled and not touch_moved and selected.get_global_rect().has_point(event.position) and not event.canceled
   cancel_touch()
   get_viewport().set_input_as_handled()
   if confirmed: selected.pressed.emit()
 elif event is InputEventScreenDrag and event.index==touch_finger:
  if event.position.distance_to(touch_origin)>14: touch_moved=true
  if touch_moved and is_instance_valid(touch_scroll): touch_scroll.scroll_vertical=scroll_start+roundi(touch_origin.y-event.position.y)
  get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: cancel_touch()
