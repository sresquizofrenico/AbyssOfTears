class_name RoomBlueprint
extends RefCounted

const NAMES = ["Atrio despejado","Islas de piedra","Cobertura lateral","Muros quebrados","Cuatro rincones","Cruce abierto","Pasillos de escombros","Pantallas asimétricas","Núcleo cerrado","Galería horizontal","Vigías de piedra","Arena amplia"]
const BOUNDS := Rect2(42,68,876,412)
const START := Vector2(480,390)
const GRID_SIZE := Vector2i(21,9)
const ANCHORS := [Vector2i(10,0),Vector2i(10,8),Vector2i(0,4),Vector2i(20,4),Vector2i(10,7)]

static func create(seed_value: int, floor_index: int, room_id: int, kind: String) -> Dictionary:
 var rng:=RandomNumberGenerator.new()
 rng.seed=seed_value+floor_index*7907+room_id*1031
 var variant:=posmod(seed_value+floor_index*5+room_id,12)
 # Important rooms deliberately retain generous space for goods and boss attacks.
 if kind in ["start","boss","shop","treasure","secret","special"]: variant=0
 var circles: Array[Vector2]=[]
 var walls: Array[Rect2]=[]
 match variant:
  1: circles.assign([Vector2(300,210),Vector2(660,340)])
  2: walls.assign([Rect2(220,170,100,28),Rect2(640,330,100,28)])
  3: walls.assign([Rect2(360,180,28,100),Rect2(575,280,28,100)])
  4: circles.assign([Vector2(260,150),Vector2(700,150),Vector2(260,400),Vector2(700,400)])
  5: circles.assign([Vector2(400,210),Vector2(560,210),Vector2(400,350),Vector2(560,350)])
  6: walls.assign([Rect2(240,180,100,28),Rect2(620,180,100,28),Rect2(240,330,100,28),Rect2(620,330,100,28)])
  7:
   circles.assign([Vector2(210,340),Vector2(740,210)])
   walls.assign([Rect2(360,160,100,28),Rect2(580,330,100,28)])
  8: walls.assign([Rect2(420,230,120,64)])
  9: circles.assign([Vector2(300,175),Vector2(600,175),Vector2(350,375),Vector2(650,375)])
  10: circles.assign([Vector2(360,210),Vector2(600,340)])
  11: circles.assign([Vector2(180,160),Vector2(780,390)])
 for i in range(circles.size()): circles[i]+=Vector2(rng.randi_range(-10,10),rng.randi_range(-10,10))
 for i in range(walls.size()): walls[i].position+=Vector2(rng.randi_range(-10,10),rng.randi_range(-10,10))
 var result: Dictionary={"variant":variant,"name":NAMES[variant],"circles":circles,"walls":walls,"statues":variant==10,"decor_seed":rng.randi(),"fallback":false}
 if not connected(result):
  result.variant=0
  result.name=NAMES[0]
  result.circles=[]
  result.walls=[]
  result.fallback=true
 return result

static func blocks(data: Dictionary, point: Vector2, radius: float=5) -> bool:
 if not BOUNDS.grow(-radius).has_point(point): return true
 for circle: Vector2 in data.get("circles",[]):
  if point.distance_to(circle)<24+radius: return true
 for wall: Rect2 in data.get("walls",[]):
  if wall.grow(radius).has_point(point): return true
 return false

static func point(cell: Vector2i) -> Vector2:
 return Vector2(80+cell.x*40,110+cell.y*40)

static func reachable(data: Dictionary) -> Dictionary:
 var begin:=Vector2i(10,7)
 if blocks(data,point(begin),16): return {}
 var reached: Dictionary={begin:true}
 var queue: Array[Vector2i]=[begin]
 var cursor:=0
 while cursor<queue.size():
  var cell:=queue[cursor]
  cursor+=1
  for direction: Vector2i in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   var next:=cell+direction
   if next.x<0 or next.y<0 or next.x>=GRID_SIZE.x or next.y>=GRID_SIZE.y or reached.has(next): continue
   if blocks(data,point(next),16) or blocks(data,(point(cell)+point(next))*0.5,16): continue
   reached[next]=true
   queue.append(next)
 return reached

static func connected(data: Dictionary) -> bool:
 var reached:=reachable(data)
 for anchor: Vector2i in ANCHORS:
  if not reached.has(anchor): return false
 for y in range(GRID_SIZE.y):
  for x in range(GRID_SIZE.x):
   var cell:=Vector2i(x,y)
   if not blocks(data,point(cell),16) and not reached.has(cell): return false
 return true

static func safe_point(data: Dictionary, requested: Vector2, radius:=26.0) -> Vector2:
 var candidate:=requested.clamp(Vector2(80,110),Vector2(880,430))
 if not blocks(data,candidate,radius): return candidate
 var nearest:=START
 var distance:=INF
 for y in range(GRID_SIZE.y):
  for x in range(GRID_SIZE.x):
   var position:=point(Vector2i(x,y))
   if blocks(data,position,radius): continue
   var separation:=requested.distance_squared_to(position)
   if separation<distance: nearest=position; distance=separation
 return nearest
