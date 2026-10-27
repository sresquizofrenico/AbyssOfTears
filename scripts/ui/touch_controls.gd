class_name TouchControls
extends Control

signal item_requested
signal awaken_requested
var item_visible:=false
var item_cooldown:=0.0
var awaken_visible:=false
var determination:=0.0
var special_fingers: Dictionary={}

func item_center() -> Vector2: return Vector2(size.x-235,size.y-375)
func awaken_center() -> Vector2: return Vector2(size.x-235,size.y-295)

signal ability_requested
var ability_cooldown := 0.0
var ability_icon: Texture2D
var ability_name := "Impulso Astral"
var ability_finger := -1

func ability_center() -> Vector2:
 return Vector2(size.x-235,size.y-215)

var move_vector := Vector2.ZERO
var fire_vector := Vector2.ZERO
var joystick_finger: int = -1
var fire_fingers: Dictionary = {}
var joystick_position := Vector2.ZERO
var enabled := false
var scale_factor: float = 1.0
var opacity: float = 0.75

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func joystick_center() -> Vector2:
 return Vector2(112, size.y - 108)

func attack_center() -> Vector2:
 return Vector2(size.x - 112, size.y - 108)

func attack_positions() -> Array[Vector2]:
 var c := attack_center()
 var gap := 49.0 * scale_factor
 return [c + Vector2(0, -gap), c + Vector2(gap, 0), c + Vector2(0, gap), c + Vector2(-gap, 0)]

func release_all() -> void:
 joystick_finger = -1
 ability_finger=-1
 special_fingers.clear()
 fire_fingers.clear()
 move_vector = Vector2.ZERO
 fire_vector = Vector2.ZERO
 joystick_position = Vector2.ZERO
 queue_redraw()

func set_enabled(value: bool) -> void:
 enabled = value
 visible = value
 release_all()

func _input(event: InputEvent) -> void:
 if not enabled:
  return
 if event is InputEventScreenTouch:
  if event.pressed:
   if item_visible and event.position.distance_to(item_center())<30*scale_factor:
    if not special_fingers.has(event.index): special_fingers[event.index]="item"; item_requested.emit()
   elif awaken_visible and event.position.distance_to(awaken_center())<30*scale_factor:
    if not special_fingers.has(event.index): special_fingers[event.index]="awaken"; awaken_requested.emit()
   elif event.position.distance_to(ability_center())<30*scale_factor:
    if ability_finger==-1:
     ability_finger=event.index
     ability_requested.emit()
   elif joystick_finger == -1 and event.position.distance_to(joystick_center()) < 90.0 * scale_factor:
    joystick_finger = event.index
    update_joystick(event.position)
   else:
    update_fire(event.index, event.position)
  else:
   special_fingers.erase(event.index)
   if event.index==ability_finger: ability_finger=-1
   if event.index == joystick_finger:
    joystick_finger = -1
    move_vector = Vector2.ZERO
    joystick_position = Vector2.ZERO
   fire_fingers.erase(event.index)
   refresh_fire()
  queue_redraw()
 elif event is InputEventScreenDrag:
  if event.index == joystick_finger:
   update_joystick(event.position)
  elif event.index!=ability_finger and not special_fingers.has(event.index):
   update_fire(event.index, event.position)
  queue_redraw()
 elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_SPACE:
  ability_requested.emit()

func update_joystick(point: Vector2) -> void:
 joystick_position = (point - joystick_center()).limit_length(55.0 * scale_factor)
 move_vector = joystick_position / (55.0 * scale_factor)
 if move_vector.length() < 0.12:
  move_vector = Vector2.ZERO

func update_fire(index: int, point: Vector2) -> void:
 var positions := attack_positions()
 var dirs := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
 fire_fingers.erase(index)
 for i in range(4):
  if point.distance_to(positions[i]) < 30.0 * scale_factor:
   fire_fingers[index] = dirs[i]
   break
 refresh_fire()

func refresh_fire() -> void:
 # Four-direction attacks: last held button wins; no diagonal shots.
 fire_vector = Vector2.ZERO
 for dir: Vector2 in fire_fingers.values():
  fire_vector = dir

func _draw() -> void:
 if not enabled:
  return
 var base := Color(0.23, 0.55, 0.65, opacity * 0.45)
 var edge := Color(0.55, 0.94, 0.94, opacity)
 draw_circle(joystick_center(), 65.0 * scale_factor, base)
 draw_arc(joystick_center(), 65.0 * scale_factor, 0, TAU, 48, edge, 2.0)
 draw_circle(joystick_center() + joystick_position, 25.0 * scale_factor, edge)
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
 draw_arc(center,28*scale_factor,0,TAU,32,edge,2)
 var font:=ThemeDB.fallback_font
 var caption: String=str(ceili(ability_cooldown)) if ability_cooldown>0 else "✦"
 if ability_cooldown<=0 and ability_icon:
  draw_texture_rect(ability_icon,Rect2(center-Vector2(17,17),Vector2(34,34)),false,Color(1,1,1,opacity))
 else:
  draw_string(font,center+Vector2(-font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,19).x/2,7),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,19,edge)
 draw_string(font,center+Vector2(-29,-35),"Habilidad",HORIZONTAL_ALIGNMENT_LEFT,-1,13,edge)

 if item_visible: draw_special(item_center(),str(ceili(item_cooldown)) if item_cooldown>0 else "◇","Objeto",base,edge)
 if awaken_visible:
  draw_special(awaken_center(),"✧","Despertar",base,edge)
  var rect:=Rect2(awaken_center()+Vector2(-66,37),Vector2(132,6))
  draw_rect(rect,Color(0.12,0.11,0.2,opacity))
  draw_rect(Rect2(rect.position,Vector2(rect.size.x*determination/100,6)),Color("cba4ed"))

func draw_special(center: Vector2, caption: String, title: String, base: Color, edge: Color) -> void:
 draw_circle(center,28*scale_factor,base)
 draw_arc(center,28*scale_factor,0,TAU,24,edge,2)
 var font:=ThemeDB.fallback_font
 draw_string(font,center+Vector2(-9,7),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,19,edge)
 draw_string(font,center+Vector2(-30,-35),title,HORIZONTAL_ALIGNMENT_LEFT,-1,13,edge)
