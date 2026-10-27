class_name TouchControls
extends Control

signal item_requested
signal awaken_requested
signal ability_requested
var item_visible:=false
var item_cooldown:=0.0
var awaken_visible:=false
var determination:=0.0
var ability_cooldown:=0.0
var ability_icon: Texture2D
var ability_name: String="Impulso Astral"
var ability_finger: int=-1
var special_fingers: Dictionary={}
var move_vector:=Vector2.ZERO
var fire_vector:=Vector2.ZERO
var joystick_finger: int=-1
var fire_fingers: Dictionary={}
var fire_order: Array[int]=[]
var finger_roles: Dictionary={}
var joystick_position:=Vector2.ZERO
var floating_origin:=Vector2.ZERO
var joystick_touch_origin:=Vector2.ZERO
var enabled:=false
var scale_factor:=1.0
var opacity:=0.75
var move_deadzone:=0.12
var floating_joystick:=false
var fire_style:=0 # 0: directional pad, 1: cardinal shooting stick
var left_handed:=false
var safe_insets:=Vector4.ZERO # left, top, right, bottom in viewport coordinates
var excluded_regions: Array[Rect2]=[]

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(layout_changed)
 visibility_changed.connect(func():
  if not is_visible_in_tree(): release_all())
 layout_changed()

func layout_changed() -> void:
 release_all()
 if not OS.has_feature("android"): return
 var window:=Vector2(DisplayServer.window_get_size())
 if window.x<=0 or window.y<=0: return
 var safe:=Rect2(DisplayServer.get_display_safe_area())
 var origin:=Vector2(DisplayServer.window_get_position())
 if safe.size.x<=0 or safe.size.y<=0: return
 safe_insets=Vector4(maxf(0,safe.position.x-origin.x)*size.x/window.x,maxf(0,safe.position.y-origin.y)*size.y/window.y,maxf(0,origin.x+window.x-safe.end.x)*size.x/window.x,maxf(0,origin.y+window.y-safe.end.y)*size.y/window.y)
 queue_redraw()

func side_point(point: Vector2) -> Vector2:
 return Vector2(size.x-point.x,point.y) if left_handed else point

func joystick_anchor() -> Vector2:
 return side_point(Vector2(112+(safe_insets.z if left_handed else safe_insets.x),size.y-108-safe_insets.w))

func joystick_center() -> Vector2:
 return floating_origin if floating_joystick and joystick_finger!=-1 else joystick_anchor()

func attack_center() -> Vector2:
 return side_point(Vector2(size.x-112-(safe_insets.x if left_handed else safe_insets.z),size.y-108-safe_insets.w))

func ability_center() -> Vector2:
 var y:=maxf(size.y-215-safe_insets.w,safe_insets.y+160+38*scale_factor+12)
 return side_point(Vector2(size.x-235-(safe_insets.x if left_handed else safe_insets.z),y))
func awaken_center() -> Vector2:
 return ability_center()-Vector2(0,80)
func item_center() -> Vector2:
 return ability_center()-Vector2(0,160)

func attack_positions() -> Array[Vector2]:
 var c:=attack_center()
 var gap:=49.0*scale_factor
 return [c+Vector2.UP*gap,c+Vector2.RIGHT*gap,c+Vector2.DOWN*gap,c+Vector2.LEFT*gap]

func configure(values: Dictionary) -> void:
 release_all()
 scale_factor=clampf(float(values.get("control_scale",1.0)),0.8,1.25)
 opacity=clampf(float(values.get("control_opacity",0.75)),0.3,1.0)
 move_deadzone=clampf(float(values.get("move_deadzone",0.12)),0.08,0.28)
 floating_joystick=bool(values.get("floating_joystick",false))
 fire_style=clampi(int(values.get("fire_style",0)),0,1)
 left_handed=bool(values.get("left_handed",false))
 layout_changed()

func release_all() -> void:
 joystick_finger=-1
 ability_finger=-1
 special_fingers.clear()
 finger_roles.clear()
 fire_order.clear()
 fire_fingers.clear()
 move_vector=Vector2.ZERO
 fire_vector=Vector2.ZERO
 joystick_position=Vector2.ZERO
 floating_origin=Vector2.ZERO
 joystick_touch_origin=Vector2.ZERO
 queue_redraw()

func set_enabled(value: bool) -> void:
 enabled=value
 visible=value
 release_all()

func blocks(point: Vector2) -> bool:
 for rect: Rect2 in excluded_regions:
  if rect.has_point(point): return true
 return false

func movement_region(point: Vector2) -> bool:
 if not floating_joystick: return point.distance_to(joystick_anchor())<90*scale_factor
 var horizontal:=size.x-point.x if left_handed else point.x
 return horizontal>=(safe_insets.z if left_handed else safe_insets.x) and horizontal<minf(size.x*0.28,255) and point.y>size.y*0.64 and point.y<size.y-safe_insets.w

func capture(index: int, point: Vector2) -> bool:
 if finger_roles.has(index) or blocks(point): return false
 var role: String=""
 if item_visible and point.distance_to(item_center())<30*scale_factor: role="item"
 elif awaken_visible and point.distance_to(awaken_center())<30*scale_factor: role="awaken"
 elif point.distance_to(ability_center())<30*scale_factor: role="ability"
 elif joystick_finger==-1 and movement_region(point): role="move"
 elif point.distance_to(attack_center())<92*scale_factor: role="fire"
 if role.is_empty(): return false
 if role=="ability" and ability_finger!=-1: return false
 finger_roles[index]=role
 match role:
  "move":
   joystick_finger=index
   joystick_touch_origin=point
   floating_origin=Vector2(clampf(point.x,safe_insets.x+66*scale_factor,size.x-safe_insets.z-66*scale_factor),clampf(point.y,safe_insets.y+66*scale_factor,size.y-safe_insets.w-66*scale_factor))
   update_joystick(point)
  "fire":
   fire_order.append(index)
   update_fire(index,point)
  "ability":
   ability_finger=index
   if ability_cooldown<=0: ability_requested.emit()
  "item":
   special_fingers[index]=role
   if item_cooldown<=0: item_requested.emit()
  "awaken":
   special_fingers[index]=role
   if determination>=100: awaken_requested.emit()
 queue_redraw()
 return true

func release(index: int) -> bool:
 if not finger_roles.has(index): return false
 var role: String=finger_roles[index]
 finger_roles.erase(index)
 if role=="move":
  joystick_finger=-1
  move_vector=Vector2.ZERO
  joystick_position=Vector2.ZERO
 elif role=="fire":
  fire_fingers.erase(index)
  fire_order.erase(index)
  refresh_fire()
 elif role=="ability": ability_finger=-1
 special_fingers.erase(index)
 queue_redraw()
 return true

func _input(event: InputEvent) -> void:
 if not enabled or not is_visible_in_tree(): return
 if event is InputEventScreenTouch:
  if capture(event.index,event.position) if event.pressed else release(event.index): get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag and finger_roles.has(event.index):
  var role: String=finger_roles[event.index]
  if role=="move": update_joystick(event.position)
  elif role=="fire": update_fire(event.index,event.position)
  get_viewport().set_input_as_handled()
  queue_redraw()
 elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_SPACE:
  ability_requested.emit()

func update_joystick(point: Vector2) -> void:
 joystick_position=(point-(joystick_touch_origin if floating_joystick else joystick_center())).limit_length(55*scale_factor)
 var value:=joystick_position/(55*scale_factor)
 var strength:=value.length()
 move_vector=Vector2.ZERO if strength<=move_deadzone else value.normalized()*clampf((strength-move_deadzone)/(1-move_deadzone),0,1)
 queue_redraw()

func update_fire(index: int, point: Vector2) -> void:
 # A touch has one owner from press to release. An unrelated drag cannot shoot.
 if finger_roles.get(index)!="fire": return
 var offset:=point-attack_center()
 if offset.length()>14*scale_factor:
  var direction:=Vector2(signf(offset.x),0) if absf(offset.x)>absf(offset.y) else Vector2(0,signf(offset.y))
  var previous: Vector2=fire_fingers.get(index,Vector2.ZERO)
  if previous==Vector2.ZERO or previous==direction or previous.dot(offset.normalized())<0.65: fire_fingers[index]=direction
 refresh_fire()

func refresh_fire() -> void:
 fire_vector=Vector2.ZERO
 for index: int in fire_order:
  if fire_fingers.has(index): fire_vector=fire_fingers[index]
 queue_redraw()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: release_all()

func _draw() -> void:
 if not enabled:
  return
 var base := Color(0.23, 0.55, 0.65, opacity * 0.45)
 var edge := Color(0.55, 0.94, 0.94, opacity)
 draw_circle(joystick_center(), 65.0 * scale_factor, base)
 draw_arc(joystick_center(), 65.0 * scale_factor, 0, TAU, 48, edge, 2.0)
 draw_circle(joystick_center() + joystick_position*0.7, 25.0 * scale_factor, edge)
 if fire_style==1:
  draw_circle(attack_center(),65*scale_factor,base)
  draw_arc(attack_center(),65*scale_factor,0,TAU,48,edge,2)
  draw_circle(attack_center()+fire_vector*38*scale_factor,22*scale_factor,edge)
  for direction in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]: draw_line(attack_center()+direction*51*scale_factor,attack_center()+direction*60*scale_factor,edge,3,true)
 else:
  var dirs := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
  var positions := attack_positions()
  for i in range(4):
   var p := positions[i]
   var d: Vector2 = dirs[i]
   var color := edge if fire_vector == d else base
   draw_circle(p, 28.0 * scale_factor, color)
   var side := d.orthogonal()
   draw_colored_polygon(PackedVector2Array([p + d * 13, p - d * 7 + side * 9, p - d * 7 - side * 9]), Color(0.85, 1, 1, opacity))

 # Independent third-finger ability target; no overlap with four firing buttons.
 var center:=ability_center()
 draw_circle(center,28*scale_factor,base)
 draw_arc(center,28*scale_factor,0,TAU,32,edge if ability_cooldown<=0 else Color(edge,0.4),2)
 var font:=ThemeDB.fallback_font
 var caption: String=str(ceili(ability_cooldown)) if ability_cooldown>0 else "✦"
 if ability_cooldown<=0 and ability_icon:
  draw_texture_rect(ability_icon,Rect2(center-Vector2(17,17),Vector2(34,34)),false,Color(1,1,1,opacity))
 else:
  draw_string(font,center+Vector2(-font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,19).x/2,7),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,19,edge)
 draw_string(font,center+Vector2(-29,-35),"Habilidad",HORIZONTAL_ALIGNMENT_LEFT,-1,13,edge)

 if item_visible: draw_special(item_center(),str(ceili(item_cooldown)) if item_cooldown>0 else "◇","Objeto",base,edge if item_cooldown<=0 else Color(edge,0.4))
 if awaken_visible:
  draw_special(awaken_center(),"✧","Despertar",base,edge if determination>=100 else Color(edge,0.35))
  var rect:=Rect2(awaken_center()+Vector2(46 if left_handed else -126,-3),Vector2(80,6))
  draw_rect(rect,Color(0.12,0.11,0.2,opacity))
  draw_rect(Rect2(rect.position,Vector2(rect.size.x*determination/100,6)),Color("cba4ed"))
  draw_string(font,rect.position+Vector2(2,-7),"%d / 100" % roundi(determination),HORIZONTAL_ALIGNMENT_LEFT,-1,13,edge)

func draw_special(center: Vector2, caption: String, title: String, base: Color, edge: Color) -> void:
 draw_circle(center,28*scale_factor,base)
 draw_arc(center,28*scale_factor,0,TAU,24,edge,2)
 var font:=ThemeDB.fallback_font
 draw_string(font,center+Vector2(-9,7),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,19,edge)
 draw_string(font,center+Vector2(-30,-35),title,HORIZONTAL_ALIGNMENT_LEFT,-1,13,edge)
