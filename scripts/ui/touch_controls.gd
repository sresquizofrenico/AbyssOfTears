class_name TouchControls
extends Control

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
   if joystick_finger == -1 and event.position.distance_to(joystick_center()) < 90.0 * scale_factor:
    joystick_finger = event.index
    update_joystick(event.position)
   else:
    update_fire(event.index, event.position)
  else:
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
  else:
   update_fire(event.index, event.position)
  queue_redraw()

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
