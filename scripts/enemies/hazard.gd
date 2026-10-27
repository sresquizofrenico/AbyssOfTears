class_name EnemyHazard
extends Node2D

var kind := "acid"
var player: AbyssPlayer
var age := 0.0
var duration := 3.0
var radius := 34.0
var activated := false
var original_speed := 0.0
var stat_source: String=""

func _ready() -> void:
 stat_source="cold_env:%d" % get_instance_id()
 if kind == "wall":
  var body := StaticBody2D.new()
  body.collision_layer = 1
  var collision := CollisionShape2D.new()
  var shape := CircleShape2D.new()
  shape.radius = 22
  collision.shape = shape
  body.add_child(collision)
  add_child(body)
 if kind == "dark": radius = 85
 if kind == "cold": duration=4.0; radius=42.0

func _physics_process(delta: float) -> void:
 age += delta
 if not is_instance_valid(player): queue_free(); return
 if age >= 0.8 and player.position.distance_to(position) < radius and not player.environment_protected():
  if kind in ["acid","lightning","explosion","cold","heat"]: player.take_damage(1,kind)
  if kind=="cold" and not activated:
   activated=true
   player.stats.set_temporary(stat_source,{"speed":-player.stats._speed*0.25})
  if kind == "curse" and not activated:
   activated = true
   original_speed = player.stats.speed
   player.stats.set_temporary("curse",{"speed":-player.stats._speed*0.3})
 if age >= (1.15 if kind in ["lightning","explosion"] else duration):
  restore()
  queue_free()
 queue_redraw()

func restore() -> void:
 if activated and is_instance_valid(player):
  player.stats.clear_temporary(stat_source if kind=="cold" else "curse")
  activated = false

func _exit_tree() -> void:
 restore()

func _draw() -> void:
 var color := Color("9ac451") if kind == "acid" else Color("efc482")
 if kind == "cold": color=Color("a1e4f5")
 if kind == "wall": color = Color("817fa3")
 if kind == "curse": color = Color("b688cc")
 if kind == "dark":
  draw_circle(Vector2.ZERO,radius,Color(0.01,0.01,0.04,0.65))
  return
 draw_circle(Vector2.ZERO,radius,Color(color,0.15 if age < 0.8 else 0.4))
 draw_arc(Vector2.ZERO,radius,0,TAU,32,color,2)
 if kind == "lightning": draw_line(Vector2(-10,-20),Vector2(10,20),color,3)
