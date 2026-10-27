class_name AbyssPlayer
extends CharacterBody2D

signal shot(origin: Vector2, direction: Vector2, stats: ActorStats)
signal health_changed(current: float, maximum: float)
signal died
signal damaged
signal ability_used

const BODY = IllustratedNeris.BODY
var character_id := "neris"
var body_texture: Texture2D = BODY
var animation_rate := 1.0
var ability_remaining := 0.0
var ability_active := 0.0
var fatigue := 0.0
var ability_age := 0.0
var skill_origin := Vector2.ZERO
var dash_direction := Vector2.DOWN
var heal_budget := 0.0
var mixture := 0
var spawn_pose := 0.5
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
 tick_ability(delta)
 relics.tick(delta)
 pickup_pose = maxf(0,pickup_pose-delta)
 cooldown = maxf(0, cooldown - delta)
 immunity = maxf(0, immunity - delta)
 velocity = movement_input() * stats.speed
 if character_id=="neris" and ability_active>0: velocity=dash_direction*520.0
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
 if character_id=="orin" and ability_active>0: return
 if relics.block_hit():
  immunity = 0.3
  queue_redraw()
  return
 stats.apply_damage(amount)
 damaged.emit()
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
 if spawn_pose>0: jump-=sin(spawn_pose*PI*2)*7
 if ability_active>0: pose="present"
 IllustratedNeris.paint(self,clock*animation_rate,velocity.length()>1,pose,facing,Vector2(0,bob+jump),tilt,1.0,Color.WHITE,body_texture)
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
 if relics.mirror_active() or (character_id=="mira" and ability_active>0):
  IllustratedNeris.paint(self,clock*animation_rate,velocity.length()>1,pose,facing,Vector2(44,bob),tilt,1.0,Color(0.55,0.8,1,0.4),body_texture)

 if ability_active>0:
  var color:=Color(CharacterCatalog.definition(character_id).color)
  draw_arc(Vector2(0,-9),31+sin(clock*9)*3,0,TAU,24,Color(color,0.7),2,true)
 if character_id in ["nyra","lumi"] and ability_active>0:
  draw_set_transform(skill_origin-position,0,Vector2.ONE)
  if character_id=="nyra": IllustratedNeris.paint(self,clock*animation_rate,false,"rest",facing,Vector2.ZERO,0,1.0,Color(0.35,0.2,0.55,0.55),body_texture)
  else: draw_arc(Vector2.ZERO,72,0,TAU,32,Color(1,0.9,0.55,0.8),3,true)
  draw_set_transform(Vector2.ZERO)

func draw_ellipse_shadow() -> void:
 draw_texture_rect(IllustratedNeris.SHADOW,Rect2(-29,9,58,23),false)

func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func configure_character(id: String) -> void:
 character_id=id
 animation_rate=float(CharacterCatalog.definition(id).animation_rate)
 body_texture=CharacterCatalog.texture(id)

func activate_ability() -> bool:
 if not active or ability_remaining>0 or not CharacterCatalog.playable(character_id): return false
 var entry:=CharacterCatalog.definition(character_id)
 ability_remaining=float(entry.cooldown)
 ability_active=float(entry.duration)
 ability_age=0.0
 skill_origin=position
 dash_direction=movement_input().normalized() if movement_input()!=Vector2.ZERO else facing
 if character_id=="neris": immunity=maxf(immunity,0.24)
 if character_id=="lumi": heal_budget=1.5
 if character_id=="vex": mixture=posmod(mixture+1,3)
 if character_id=="nox": stats.set_temporary("character",{"damage":0.45,"attack_interval":-0.05})
 ability_used.emit()
 queue_redraw()
 return true

func tick_ability(delta: float) -> void:
 spawn_pose=maxf(0,spawn_pose-delta)
 ability_remaining=maxf(0,ability_remaining-delta)
 var was_active:=ability_active>0
 ability_active=maxf(0,ability_active-delta)
 ability_age+=delta
 if character_id=="lumi" and ability_active>0 and position.distance_to(skill_origin)<=72 and heal_budget>0:
  var healing:=minf(heal_budget,minf(delta*0.5,stats.max_health-stats.health))
  stats.health+=healing
  heal_budget-=healing
  if healing>0: health_changed.emit(stats.health,stats.max_health)
 if character_id=="nox" and was_active and ability_active<=0:
  stats.set_temporary("character",{"damage":-0.15,"speed":-40.0})
  fatigue=2.0
 elif fatigue>0:
  fatigue=maxf(0,fatigue-delta)
  if fatigue<=0: stats.clear_temporary("character")

func pursuit_point() -> Vector2:
 return skill_origin if character_id=="nyra" and ability_active>0 else position

func ability_snapshot() -> Dictionary:
 return {"remaining":ability_remaining,"active":ability_active,"fatigue":fatigue,"age":ability_age,"origin":skill_origin,"direction":dash_direction,"heal":heal_budget,"mixture":mixture}

func restore_ability(value: Dictionary) -> void:
 ability_remaining=value.remaining
 ability_active=value.active
 fatigue=value.fatigue
 ability_age=value.age
 skill_origin=value.origin
 dash_direction=value.direction
 heal_budget=value.heal
 mixture=value.mixture
