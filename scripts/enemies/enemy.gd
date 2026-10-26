class_name AbyssEnemy
extends CharacterBody2D

signal shot(origin: Vector2, direction: Vector2)
signal summon(kind_id: int, location: Vector2, weak: bool)
signal hazard(location: Vector2, hazard_type: String)

signal defeated(location: Vector2, reward: int)

@export_range(0, 19) var kind: int = 0
var definition: Dictionary
var facing := Vector2.DOWN
var once := false
var weak := false
var slowed := 0.0
var destination := Vector2.ZERO
var events: Dictionary = {}

func record(key: String) -> void:
 events[key] = int(events.get(key, 0)) + 1
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
 definition = EnemyCatalog.DATA[kind]
 health = float(definition.health) * (0.5 if weak else 1.0)
 max_health = health
 speed = definition.speed
 if kind == 5: collision_mask = 0
 attack_timer = float(definition.interval)

func _physics_process(delta: float) -> void:
 if dead or not is_instance_valid(target) or not target.active: return
 clock += delta
 flash = maxf(0, flash - delta)
 attack_timer -= delta
 var difference := target.position - position
 var direction := difference.normalized()
 facing = direction if velocity.length() > 1 else facing
 velocity = direction * speed
 telegraph = attack_timer < 0.65
 match kind:
  0: record("pursue")
  1:
   velocity = direction * speed if difference.length() > 240 else -direction * speed
   if telegraph: velocity = Vector2.ZERO
  2:
   velocity = direction.rotated(sin(clock * 4) * 0.7) * speed
   record("zigzag")
  3:
   var center := Vector2.ZERO
   var count := 0
   for other in get_parent().get_children():
    if other is AbyssEnemy and other != self and other.kind == 3:
     center += other.position
     count += 1
   if count > 0: velocity += (center / count - position).limit_length(40)
   record("flock")
  4:
   velocity = Vector2.ZERO
   if difference.length() > 300: attack_timer = maxf(attack_timer,0.7)
   record("detect")
  5: record("phase_obstacles")
  6: record("frontal_armor")
  9:
   velocity = Vector2.from_angle(clock * 3 + sin(clock * 7) * 2) * speed + direction * 25
   record("erratic")
  13:
   if telegraph:
    velocity = Vector2.ZERO
    if destination == Vector2.ZERO: destination = target.position
   record("marked_dash")
  15:
   if health <= max_health * 0.5 and not once:
    once = true
    summon.emit(15, position + Vector2(35,0), true)
    record("duplicate")
 move_and_slide()
 # Ghosts cross pillars but never cross the outer arena boundary.
 position = position.clamp(Vector2(59,85), Vector2(901,463))
 if attack_timer <= 0:
  attack_timer = float(definition.interval)
  perform_attack(direction)
 if difference.length() < 30: target.take_damage(float(definition.damage))
 queue_redraw()

func perform_attack(direction: Vector2) -> void:
 record(definition.behavior)
 match kind:
  1,4: shot.emit(position + direction * 23, direction)
  7: hazard.emit(position,"acid")
  8: hazard.emit(position + direction * 65,"wall")
  10: summon.emit(3, position + direction.orthogonal() * 40, true)
  11:
   for i in range(4): shot.emit(position,Vector2.from_angle(i * PI / 2))
  12: hazard.emit(target.position,"dark")
  13:
   if destination != Vector2.ZERO:
    position = destination.clamp(Vector2(70,95),Vector2(890,455))
    destination = Vector2.ZERO
  16: hazard.emit(target.position,"curse")
  17:
   for i in range(8): shot.emit(position,Vector2.from_angle(i * TAU / 8 + clock))
  19: hazard.emit(target.position,"lightning")

func take_damage(amount: float, incoming := Vector2.ZERO) -> void:
 if dead: return
 if kind == 6 and incoming != Vector2.ZERO and incoming.normalized().dot(facing) < -0.5:
  amount *= 0.3
  record("blocked_front")
 health -= amount * (1.0 - float(definition.resistance))
 flash = 0.12
 if health <= 0.0:
  dead = true
  if kind == 14: hazard.emit(position,"explosion")
  if kind == 18:
   summon.emit(3, position + Vector2(-30,0), true)
   summon.emit(3, position + Vector2(30,0), true)
  defeated.emit(position, int(definition.reward))
  queue_free()
 queue_redraw()

func _draw() -> void:
 var color := Color.WHITE if flash > 0 else Color.from_hsv(float(kind) / 23,0.4,0.85)
 draw_set_transform(Vector2(0,sin(clock * (4 + kind % 5)) * 2))
 var points := PackedVector2Array()
 for i in range(int(definition.sides) * 2):
  var radius := 22.0 if i % 2 == 0 else 12.0 + kind % 4
  points.append(Vector2.from_angle(i * TAU / (int(definition.sides) * 2) + (sin(clock) * 0.15)) * radius)
 draw_colored_polygon(points,color)
 # Distinct internal glyphs encode the behavior, rather than color alone.
 for i in range(1 + kind / 5):
  draw_line(Vector2(-10 + i*6,6),Vector2(-10 + i*6,12),Color("193047"),2)
 if kind == 6: draw_arc(Vector2.ZERO,25,facing.angle()-0.8,facing.angle()+0.8,12,Color("e3ebcd"),5)
 if telegraph: draw_arc(Vector2.ZERO,29,0,TAU,24,Color("ffcf91"),2)
 if destination != Vector2.ZERO:
  draw_arc(destination-position,25,0,TAU,24,Color("ffcf91"),2)
 draw_circle(Vector2(-5,-3), 3, Color("1c1b32"))
 draw_circle(Vector2(5,-3), 3, Color("1c1b32"))
 draw_set_transform(Vector2.ZERO)
 if health < max_health:
  draw_rect(Rect2(-18,-31,36,3),Color("302b46"))
  draw_rect(Rect2(-18,-31,36 * maxf(health,0) / max_health,3),Color("efb2ae"))
