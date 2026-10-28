class_name RoomTransition
extends RefCounted

const CENTER:=Vector2(480,274)
const OFFSET:=Vector2(410,185)
const INSET:=58.0

static func direction(layout: FloorLayout, origin: int, destination: int) -> Vector2i:
 if origin<0 or destination<0 or origin>=layout.rooms.size() or destination>=layout.rooms.size(): return Vector2i.ZERO
 var delta: Vector2i=layout.rooms[destination].cell-layout.rooms[origin].cell
 return delta if delta in FloorLayout.DIRECTIONS and layout.rooms[origin].links.has(destination) else Vector2i.ZERO

static func record(layout: FloorLayout, destination: int) -> Dictionary:
 var exit:=direction(layout,layout.current,destination)
 if exit==Vector2i.ZERO: return {}
 var entry:=-exit
 var desired:=CENTER+Vector2(entry)*(OFFSET-Vector2.ONE*INSET)
 var room: Dictionary=layout.rooms[destination]
 var blueprint:=RoomBlueprint.create(layout.seed_value,layout.floor_index,destination,room.kind)
 var spawn:=desired
 if RoomBlueprint.blocks(blueprint,spawn,18):
  var distance:=INF
  for y in range(RoomBlueprint.GRID_SIZE.y):
   for x in range(RoomBlueprint.GRID_SIZE.x):
    var at:=RoomBlueprint.point(Vector2i(x,y))
    if (at-(CENTER+Vector2(entry)*OFFSET)).dot(Vector2(-entry))<50 or RoomBlueprint.blocks(blueprint,at,18): continue
    if at.distance_squared_to(desired)<distance:
     spawn=at
     distance=at.distance_squared_to(desired)
 return {"origin":layout.current,"destination":destination,"exit":exit,"entry":entry,"door":"%d:%d:%d:%d" % [layout.floor_index,layout.current,exit.x,exit.y],"marker":CENTER+Vector2(entry)*OFFSET,"spawn":spawn,"facing":Vector2(exit)}

static func safe_spawn(game, desired: Vector2) -> Vector2:
 # Test the interior marker first; bounded rings keep the correction local.
 for ring in range(26):
  for i in range(1 if ring==0 else 24):
   var at: Vector2=desired+Vector2.from_angle(i*TAU/24)*ring*18
   if game.chamber.blocks(at,18): continue
   var blocked:=false
   if game.dungeon_mode:
    for neighbor in game.layout.rooms[game.layout.current].links:
     if at.distance_to(game.door_point(neighbor))<48: blocked=true; break
   for enemy in game.enemies:
    if is_instance_valid(enemy) and not enemy.dead and at.distance_to(enemy.position)<enemy.hit_radius+40: blocked=true; break
   for prop in game.props:
    if is_instance_valid(prop) and not prop.data.get("used",false) and prop.data.kind in ["barrel","trap"] and at.distance_to(prop.position)<55: blocked=true; break
   for hazard in game.hazards:
    if is_instance_valid(hazard) and at.distance_to(hazard.position)<hazard.radius+25: blocked=true; break
   if not blocked: return at
 return game.safe_point(Vector2(480,390))
