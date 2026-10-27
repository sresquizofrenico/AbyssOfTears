extends Node2D

const FLOOR = preload("res://assets/illustrated/floor_0.svg")
const FLOORS = [FLOOR,preload("res://assets/illustrated/floor_1.svg"),preload("res://assets/illustrated/floor_2.svg")]
var biome := 0
const COLUMN = preload("res://assets/illustrated/column.svg")
const WALL = preload("res://assets/illustrated/wall.svg")
const BOUNDS := Rect2(42, 68, 876, 412)
const PILLARS := [Vector2(320, 200), Vector2(640, 200), Vector2(320, 355), Vector2(640, 355)]
var blueprint: Dictionary = {}
const ROCK = preload("res://assets/illustrated/rock.svg")
const STATUE = preload("res://assets/illustrated/statue.svg")
const BROKEN_WALL = preload("res://assets/illustrated/broken_wall.svg")
var quality := 1
var clock := 0.0

func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 for rect in [Rect2(22,48,916,20), Rect2(22,480,916,20), Rect2(22,68,20,412), Rect2(918,68,20,412)]:
  var shape := RectangleShape2D.new()
  shape.size = rect.size
  add_wall(rect.get_center(), shape)
 for point: Vector2 in obstacle_points():
  var shape := CircleShape2D.new()
  shape.radius = 24
  add_wall(point, shape)

 if not blueprint.is_empty():
  for rect: Rect2 in blueprint.walls:
   var shape:=RectangleShape2D.new()
   shape.size=rect.size
   add_wall(rect.get_center(),shape)

func obstacle_points() -> Array:
 return PILLARS if blueprint.is_empty() else blueprint.circles

func add_wall(point: Vector2, shape: Shape2D) -> void:
 var body := StaticBody2D.new()
 body.position = point
 body.collision_layer = 1
 body.collision_mask = 0
 var collision := CollisionShape2D.new()
 collision.shape = shape
 body.add_child(collision)
 add_child(body)

func _process(delta: float) -> void:
 if quality == 2:
  clock += delta
  queue_redraw()

func blocks(point: Vector2, radius: float = 5.0) -> bool:
 if not blueprint.is_empty(): return RoomBlueprint.blocks(blueprint,point,radius)
 if not BOUNDS.grow(-radius).has_point(point): return true
 for pillar: Vector2 in PILLARS:
  if point.distance_to(pillar) < 24 + radius: return true
 return false

func _draw() -> void:
 draw_rect(Rect2(22,48,916,452),Color("29374b"))
 draw_rect(BOUNDS,Color("101f30"))
 draw_texture_rect(FLOORS[clampi(biome,0,2)],BOUNDS,false)
 for x in range(24,936,64):
  draw_texture_rect(WALL,Rect2(x,45,64,24),false)
  draw_texture_rect(WALL,Rect2(x,480,64,20),false)
 if quality > 0:
  for i in range(16):
   var point := Vector2(70 + (i * 137) % 810, 90 + (i * 97) % 350)
   draw_arc(point, 13 + sin(clock + i) * 3, 0, PI, 16, Color(0.3,0.7,0.8,0.12),1)
 for point: Vector2 in obstacle_points():
  draw_texture_rect(IllustratedNeris.SHADOW,Rect2(point-Vector2(35,7),Vector2(77,54)),false)
  var art: Texture2D=COLUMN if blueprint.is_empty() else STATUE if blueprint.statues else ROCK
  draw_texture_rect(art,Rect2(point-Vector2(29,42),Vector2(58,66)),false)
 if not blueprint.is_empty():
  for rect: Rect2 in blueprint.walls:
   draw_texture_rect(BROKEN_WALL,Rect2(rect.position-Vector2(2,20),rect.size+Vector2(4,22)),false)
  # Decorative ink/roots stay near edges and have no collision nodes.
  if quality>0:
   for i in range(6):
    var x:=110+int(blueprint.decor_seed+i*137)%720
    var y:=112 if i%2==0 else 432
    draw_polyline(PackedVector2Array([Vector2(x,y),Vector2(x+14,y+5),Vector2(x+20,y-4)]),Color(0.3,0.5,0.5,0.22),1.5,true)
 for point in [Vector2(60,85),Vector2(900,85),Vector2(60,462),Vector2(900,462)]:
  if quality > 0:
   for radius in [28,20,13]:
    draw_circle(point,radius,Color(0.3,0.9,0.85,0.04))
  draw_circle(point,5,Color("94f5db"))
