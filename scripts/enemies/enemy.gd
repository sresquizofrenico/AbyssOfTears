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
var burning := 0.0
var burn_tick := 0.0
var destination := Vector2.ZERO
var events: Dictionary = {}

func record(key: String) -> void:
 events[key] = int(events.get(key, 0)) + 1
var peers: Array[AbyssEnemy] = []
var target: AbyssPlayer
var health := 3.0
var max_health := 3.0
var hit_radius := 20.0
var speed := 70.0
var clock := 0.0
var attack_timer := 1.6
var flash := 0.0
var telegraph := false
var dead := false

func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 definition = EnemyCatalog.DATA[kind]
 health = float(definition.health) * (0.5 if weak else 1.0)
 max_health = health
 speed = definition.speed
 if kind == 5: collision_mask = 0
 attack_timer = float(definition.interval)

func _physics_process(delta: float) -> void:
 if dead or not is_instance_valid(target) or not target.active: return
 if not step_conditions(delta): return
 attack_timer -= delta
 var difference := target.pursuit_point() - position
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
   for other in peers:
    if is_instance_valid(other) and not other.dead and other != self and other.kind == 3:
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
 if slowed>0: velocity *= 0.6
 move_and_slide()
 # Ghosts cross pillars but never cross the outer arena boundary.
 position = position.clamp(Vector2(59,85), Vector2(901,463))
 if attack_timer <= 0:
  attack_timer = float(definition.interval)
  perform_attack(direction)
 if target.position.distance_to(position) < 30 and float(definition.damage)>0: target.take_damage(float(definition.damage))
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
 draw_texture_rect(IllustratedNeris.SHADOW,Rect2(-30,5,60,24),false)
 var bob := sin(clock*(4+kind%5))*2
 var scale_y := 1.0 + sin(clock*5)*0.035
 draw_set_transform(Vector2(0,bob),sin(clock*3)*0.04,Vector2(1,scale_y))
 var tint := Color(1.5,1.5,1.5) if flash>0 else Color.WHITE
 draw_texture_rect(EnemyArt.TEXTURES[kind],Rect2(-27,-32,54,54),false,tint)
 draw_set_transform(Vector2.ZERO)
 if burning>0: draw_circle(Vector2(0,15),7,Color(1,0.5,0.2,0.7))
 if slowed>0: draw_arc(Vector2.ZERO,27,0,TAU,20,Color("a1e4f5"),2)
 if kind == 6: draw_arc(Vector2.ZERO,25,facing.angle()-0.8,facing.angle()+0.8,12,Color("e3ebcd"),5)
 if telegraph: draw_arc(Vector2.ZERO,29,0,TAU,24,Color("ffcf91"),2)
 if destination != Vector2.ZERO:
  draw_arc(destination-position,25,0,TAU,24,Color("ffcf91"),2)
 draw_set_transform(Vector2.ZERO)
 if health < max_health:
  draw_rect(Rect2(-18,-31,36,3),Color("302b46"))
  draw_rect(Rect2(-18,-31,36 * maxf(health,0) / max_health,3),Color("efb2ae"))

func step_conditions(delta: float) -> bool:
 clock += delta
 slowed = maxf(0,slowed-delta)
 burning = maxf(0,burning-delta)
 burn_tick -= delta
 if burning > 0 and burn_tick <= 0:
  burn_tick = 0.6
  take_damage(0.3)
  if dead: return false
 flash = maxf(0, flash - delta)
 return not dead
