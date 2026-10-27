class_name RoomProp
extends Node2D
signal activated(prop: RoomProp)
var data: Dictionary
var player: AbyssPlayer
var clock := 0.0
var flash := 0.0
var collider: StaticBody2D

func _ready() -> void:
 if data.kind=="barrel" and not data.get("used",false):
  collider=StaticBody2D.new()
  collider.collision_layer=1
  collider.collision_mask=0
  var collision:=CollisionShape2D.new()
  var shape:=CircleShape2D.new()
  shape.radius=15
  collision.shape=shape
  collider.add_child(collision)
  add_child(collider)

func take_damage(amount: float) -> void:
 if data.kind!="barrel" or data.get("used",false): return
 data.health=float(data.get("health",2.0))-amount
 flash=0.15
 if data.health<=0:
  data.used=true
  collider.collision_layer=0
  collider.get_child(0).set_deferred("disabled",true)
  activated.emit(self)
 queue_redraw()

func _physics_process(delta: float) -> void:
 clock+=delta
 flash=maxf(0,flash-delta)
 if not is_instance_valid(player) or not player.active: return
 var near := position.distance_to(player.position)<27
 if near and data.kind=="trap":
  var phase := fmod(clock,2.8)
  if phase>=0.8 and phase<1.25: player.take_damage(1)
 elif near and data.kind in ["switch","fountain"] and not data.get("used",false):
  if data.kind=="fountain" and player.stats.health>=player.stats.max_health: return
  data.used=true
  activated.emit(self)
 queue_redraw()

func _draw() -> void:
 var used: bool=data.get("used",false)
 if data.kind=="barrel":
  if used:
   draw_line(Vector2(-14,10),Vector2(12,15),Color("927f73"),4)
   return
  draw_style_box(barrel_style(),Rect2(-16,-21,32,41))
  for y in [-12,10]: draw_line(Vector2(-16,y),Vector2(16,y),Color("a8adb2"),4)
  draw_line(Vector2(-5,-18),Vector2(-5,17),Color("413644"),2)
 elif data.kind=="trap":
  var phase:=fmod(clock,2.8)
  var dangerous:=phase>=0.8 and phase<1.25
  draw_circle(Vector2.ZERO,24,Color(0.9,0.45,0.35,0.3 if dangerous else 0.08))
  draw_arc(Vector2.ZERO,24,0,TAU,24,Color("f3c591") if phase<1.25 else Color("696278"),2)
  for x in [-12,0,12]:
   draw_colored_polygon(PackedVector2Array([Vector2(x-4,9),Vector2(x,-12 if dangerous else 2),Vector2(x+4,9)]),Color("b7bdc7"))
 elif data.kind=="switch":
  draw_circle(Vector2.ZERO,19,Color("536776"))
  draw_line(Vector2.ZERO,Vector2(10 if used else -10,-20),Color("b6c4c7"),5)
  draw_circle(Vector2(10 if used else -10,-20),6,Color("8ddfba") if used else Color("d2af81"))
 else:
  draw_circle(Vector2.ZERO,24,Color("607b88"))
  draw_circle(Vector2(0,-4),18,Color("293d58"))
  draw_circle(Vector2(0,-6),12,Color("536d80") if used else Color("8bdbd5"))
  if not used: draw_line(Vector2.ZERO,Vector2(0,-25+sin(clock*3)*3),Color("b6eee0"),3)

func barrel_style() -> StyleBoxFlat:
 # Created once and reused; drawing does not allocate a style every frame.
 if not has_meta("style"):
  var style:=StyleBoxFlat.new()
  style.bg_color=Color("79636a")
  style.border_color=Color("3d3e50")
  style.set_border_width_all(3)
  style.set_corner_radius_all(7)
  set_meta("style",style)
 var style: StyleBoxFlat=get_meta("style")
 style.bg_color=Color("ccbfac") if flash>0 else Color("79636a")
 return style
