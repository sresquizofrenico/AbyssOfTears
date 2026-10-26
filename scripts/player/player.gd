class_name AbyssPlayer
extends CharacterBody2D

signal shot(origin: Vector2, direction: Vector2, stats: ActorStats)
signal health_changed(current: float, maximum: float)
signal died

var stats := ActorStats.new()
var controls: TouchControls
var active := true
var cooldown := 0.0
var immunity := 0.0
var clock := 0.0
var facing := Vector2.DOWN

func movement_input() -> Vector2:
 var keyboard := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
 if controls and controls.move_vector.length() > 0.0:
  return controls.move_vector.limit_length(1.0)
 return keyboard.limit_length(1.0)

func attack_input() -> Vector2:
 if controls and controls.fire_vector != Vector2.ZERO:
  return controls.fire_vector
 if Input.is_physical_key_pressed(KEY_UP): return Vector2.UP
 if Input.is_physical_key_pressed(KEY_RIGHT): return Vector2.RIGHT
 if Input.is_physical_key_pressed(KEY_DOWN): return Vector2.DOWN
 if Input.is_physical_key_pressed(KEY_LEFT): return Vector2.LEFT
 return Vector2.ZERO

func _physics_process(delta: float) -> void:
 if not active:
  return
 clock += delta
 cooldown = maxf(0, cooldown - delta)
 immunity = maxf(0, immunity - delta)
 velocity = movement_input() * stats.speed
 move_and_slide()
 var direction := attack_input()
 if direction != Vector2.ZERO:
  facing = direction
  try_shoot(direction)
 queue_redraw()

func try_shoot(direction: Vector2) -> bool:
 if cooldown > 0.0 or not active or direction == Vector2.ZERO:
  return false
 cooldown = stats.attack_interval
 shot.emit(position + direction * 21.0, direction, stats)
 return true

func take_damage(amount: float) -> void:
 if not active or immunity > 0.0:
  return
 stats.apply_damage(amount)
 immunity = 1.1
 health_changed.emit(stats.health, stats.max_health)
 if stats.health <= 0.0:
  active = false
  died.emit()
 queue_redraw()

func _draw() -> void:
 var bob := sin(clock * 13.0) * 2.0 if velocity.length() > 1.0 else sin(clock * 3.0)
 draw_ellipse_shadow()
 if immunity > 0.0 and int(clock * 18.0) % 2 == 0:
  return
 draw_colored_polygon(PackedVector2Array([Vector2(0, -15 + bob), Vector2(-17, 18), Vector2(0, 12), Vector2(17, 18)]), Color("355b7c"))
 draw_circle(Vector2(0, -9 + bob), 13, Color("8de5dc"))
 draw_arc(Vector2(0, -9 + bob), 15, PI, TAU, 20, Color("e9d8b3"), 4)
 var eyes := facing * 3.0 + Vector2(0, -9 + bob)
 draw_circle(eyes + Vector2(-4, 0), 2.3, Color("101b30"))
 draw_circle(eyes + Vector2(4, 0), 2.3, Color("101b30"))
 draw_line(Vector2(-6, 17), Vector2(-6, 21 + bob), Color("8de5dc"), 4)
 draw_line(Vector2(6, 17), Vector2(6, 21 - bob), Color("8de5dc"), 4)

func draw_ellipse_shadow() -> void:
 draw_set_transform(Vector2(0, 18), 0.0, Vector2(1, 0.35))
 draw_circle(Vector2.ZERO, 20, Color(0, 0, 0, 0.35))
 draw_set_transform(Vector2.ZERO)
