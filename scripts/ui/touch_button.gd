class_name AbyssTouchButton
extends Button
var owner_finger: int=-1
var origin:=Vector2.ZERO
var moved:=false
var scroll_parent: ScrollContainer
var global_origin:=Vector2.ZERO
var scroll_start:=0
func _ready() -> void:
 gui_input.connect(handle_touch)
 visibility_changed.connect(func():
  if not is_visible_in_tree(): cancel())
func cancel() -> void:
 owner_finger=-1
 moved=false
 self_modulate=Color.WHITE
func handle_touch(event: InputEvent) -> void:
 if disabled: cancel(); return
 if event is InputEventMouseButton and event.device==InputEvent.DEVICE_ID_EMULATION: accept_event()
 elif event is InputEventScreenTouch:
  if event.pressed:
   if owner_finger<0:
    owner_finger=event.index
    origin=event.position
    global_origin=get_global_transform()*event.position
    var ancestor:=get_parent()
    while ancestor and not ancestor is ScrollContainer: ancestor=ancestor.get_parent()
    scroll_parent=ancestor as ScrollContainer
    if scroll_parent: scroll_start=scroll_parent.scroll_vertical
    self_modulate=Color("b0dcdf")
   accept_event()
  elif event.index==owner_finger:
   var confirmed: bool=not moved and not event.canceled and Rect2(Vector2.ZERO,size).has_point(event.position)
   cancel()
   accept_event()
   if confirmed: pressed.emit()
 elif event is InputEventScreenDrag and event.index==owner_finger:
  if event.position.distance_to(origin)>14: moved=true
  accept_event()
func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]: cancel()

func _input(event: InputEvent) -> void:
 if owner_finger<0: return
 if event is InputEventScreenTouch and not event.pressed and event.index==owner_finger:
  var confirmed: bool=not moved and not event.canceled and not disabled and is_visible_in_tree() and get_global_rect().has_point(event.position)
  cancel()
  get_viewport().set_input_as_handled()
  if confirmed: pressed.emit()
 elif event is InputEventScreenDrag and event.index==owner_finger:
  if event.position.distance_to(global_origin)>14: moved=true
  if moved and is_instance_valid(scroll_parent): scroll_parent.scroll_vertical=scroll_start+roundi(global_origin.y-event.position.y)
  get_viewport().set_input_as_handled()
