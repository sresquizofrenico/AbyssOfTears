class_name AbyssPlayer
extends CharacterBody2D

signal shot(origin: Vector2, direction: Vector2, stats: ActorStats)
signal health_changed(current: float, maximum: float)
signal died

const BODY = IllustratedNeris.BODY
var relics := RelicInventory.new()
var pickup_pose := 0.0
var expression := "idle"
var terminal_age := 0.0
var stats := ActorStats.new()
var controls: TouchControls
var active := true
var cooldown := 0.0
var immunity := 0.0
var clock := 0.0
var facing := Vector2.DOWN

func _process(delta: float) -> void:
 if not active and expression in ["victory","defeat"] and terminal_age<1.2:
  terminal_age += delta
  queue_redraw()

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
 relics.tick(delta)
 pickup_pose = maxf(0,pickup_pose-delta)
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
 if relics.block_hit():
  immunity = 0.3
  queue_redraw()
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
 var tilt := sin(clock*9)*0.05 if velocity.length()>1 else sin(clock*2)*0.015
 if expression == "defeat": tilt = minf(0.9,terminal_age*1.5)
 var jump := -sin(pickup_pose*PI)*9 if pickup_pose>0 else 0.0
 if expression == "victory": jump -= sin(minf(1,terminal_age/1.2)*PI)*12
 var pose: String = expression
 if pickup_pose>0: pose="pickup"
 elif cooldown>stats.attack_interval*0.7: pose="attack"
 IllustratedNeris.paint(self,clock,velocity.length()>1,pose,facing,Vector2(0,bob+jump),tilt)
 if cooldown > stats.attack_interval*0.7:
  draw_circle(facing*24,5,Color(0.7,1,0.9,0.7))
 if pickup_pose>0:
  draw_arc(Vector2(0,-9),30,0,TAU,20,Color(0.9,0.85,0.6,pickup_pose),2)
 if expression == "victory":
  draw_arc(Vector2(0,-38),14,PI,TAU,18,Color("ffe3a0"),3)
 draw_set_transform(Vector2.ZERO)
 if relics.has("orbital"):
  var point := relics.orbital_point(position)-position
  draw_circle(point,8,Color("b9d9ec"))
  draw_arc(point,12,0,TAU,16,Color(0.7,0.9,1,0.35),2)
 if relics.mirror_active():
  IllustratedNeris.paint(self,clock,velocity.length()>1,pose,facing,Vector2(44,bob),tilt,1.0,Color(0.55,0.8,1,0.4))

func draw_ellipse_shadow() -> void:
 draw_texture_rect(IllustratedNeris.SHADOW,Rect2(-29,9,58,23),false)

func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
