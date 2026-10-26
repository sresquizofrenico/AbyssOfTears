class_name AbyssEnemy
extends CharacterBody2D

signal shot(origin: Vector2, direction: Vector2)
signal defeated(location: Vector2, reward: int)

@export_enum("Perseguidor", "Tirador", "Veloz") var kind: int = 0
var target: AbyssPlayer
var health := 3.0
var max_health := 3.0
var speed := 70.0
var clock := 0.0
var attack_timer := 1.6
var flash := 0.0
var telegraph := false
var dead := false

func _ready() -> void:
 health = [3.0, 4.0, 2.0][kind]
 max_health = health
 speed = [70.0, 50.0, 123.0][kind]
 attack_timer += float(get_instance_id() % 7) * 0.1

func _physics_process(delta: float) -> void:
 if dead or not is_instance_valid(target) or not target.active:
  return
 clock += delta
 flash = maxf(0, flash - delta)
 attack_timer -= delta
 var difference := target.position - position
 var direction := difference.normalized()
 if kind == 1:
  telegraph = attack_timer < 0.5
  velocity = direction * speed if difference.length() > 240.0 else -direction * speed if difference.length() < 155.0 else Vector2.ZERO
  if telegraph:
   velocity = Vector2.ZERO
  if attack_timer <= 0.0:
   shot.emit(position + direction * 23, direction)
   attack_timer = 2.0
 else:
  velocity = direction.rotated(sin(clock * 4.0) * 0.35 if kind == 2 else 0.0) * speed
 move_and_slide()
 if difference.length() < 30.0:
  target.take_damage(1.0)
 queue_redraw()

func take_damage(amount: float) -> void:
 if dead: return
 health -= amount
 flash = 0.12
 if health <= 0.0:
  dead = true
  defeated.emit(position, kind + 1)
  queue_free()
 queue_redraw()

func _draw() -> void:
 var colors := [Color("b87392"), Color("d79d68"), Color("9f8cdd")]
 var color: Color = Color.WHITE if flash > 0.0 else colors[kind]
 var bob := sin(clock * 7) * 2
 draw_set_transform(Vector2(0, 15), 0.0, Vector2(1, 0.3))
 draw_circle(Vector2.ZERO, 21, Color(0, 0, 0, 0.3))
 draw_set_transform(Vector2(0, bob))
 if kind == 0:
  draw_circle(Vector2.ZERO, 16, color)
  for i in range(5):
   var p := Vector2.from_angle(float(i) * TAU / 5) * 15
   draw_line(p, p * 1.5, color, 4)
 elif kind == 1:
  draw_colored_polygon(PackedVector2Array([Vector2(0,-24),Vector2(20,12),Vector2(0,21),Vector2(-20,12)]), color)
  if telegraph:
   draw_arc(Vector2.ZERO, 27, 0, TAU, 24, Color("ffd5a1"), 2.0)
 else:
  draw_colored_polygon(PackedVector2Array([Vector2(-23,0),Vector2(0,-13),Vector2(23,0),Vector2(0,16)]), color)
 draw_circle(Vector2(-5,-3), 3, Color("1c1b32"))
 draw_circle(Vector2(5,-3), 3, Color("1c1b32"))
 draw_set_transform(Vector2.ZERO)
 if health < max_health:
  draw_rect(Rect2(-18,-31,36,3),Color("302b46"))
  draw_rect(Rect2(-18,-31,36 * maxf(health,0) / max_health,3),Color("efb2ae"))
