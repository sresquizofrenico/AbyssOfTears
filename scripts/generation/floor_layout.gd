class_name FloorLayout
extends RefCounted

const DIRECTIONS := [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
const BIOMES := ["Cripta de Sal", "Jardines Hundidos", "Falla de Cristal"]
var rooms: Array[Dictionary] = []
var floor_index := 0
var current := 0
var seed_value := 0

func generate(run_seed: int, index: int) -> void:
 rooms.clear()
 current = 0
 floor_index = clampi(index,0,2)
 seed_value = run_seed
 var rng := RandomNumberGenerator.new()
 rng.seed = run_seed + index * 7919
 var cells: Array[Vector2i] = [Vector2i.ZERO]
 for attempt in range(512):
  if cells.size() == 8: break
  var cell: Vector2i = cells[rng.randi_range(0,cells.size()-1)] + DIRECTIONS[rng.randi_range(0,3)]
  if not cells.has(cell): cells.append(cell)
 # Bounded fallback guarantees eight connected rooms even for unusual RNG sequences.
 while cells.size() < 8:
  var right := cells[0]
  for cell in cells:
   if cell.x > right.x: right = cell
  cells.append(right + Vector2i.RIGHT)
 for cell in cells:
  var links: Array[int] = []
  for direction: Vector2i in DIRECTIONS:
   var neighbor := cells.find(cell+direction)
   if neighbor >= 0: links.append(neighbor)
  rooms.append({"cell":cell,"links":links,"kind":"combat","cleared":false,"rewarded":false,"visited":false})
 rooms[0].kind = "start"
 rooms[0].cleared = true
 var distances := distances_from_start()
 var exit_room := 1
 for i in range(1,rooms.size()):
  if distances[i] > distances[exit_room]: exit_room = i
 rooms[exit_room].kind = "descent"
 var treasure := 1 if exit_room != 1 else 2
 for i in range(1,rooms.size()):
  if i != exit_room and distances[i] > distances[treasure]: treasure = i
 rooms[treasure].kind = "treasure"
 rooms[treasure].cleared = true
 rooms[0].visited = true

func distances_from_start() -> Dictionary:
 var distances := {0:0}
 var queue: Array[int] = [0]
 while not queue.is_empty():
  var at: int = queue.pop_front()
  for next: int in rooms[at].links:
   if not distances.has(next):
    distances[next] = distances[at]+1
    queue.append(next)
 return distances

func can_enter(index: int) -> bool:
 return index >= 0 and index < rooms.size() and rooms[current].cleared and rooms[current].links.has(index)

func enter(index: int) -> bool:
 if not can_enter(index): return false
 current = index
 rooms[index].visited = true
 return true

func visible_rooms() -> Array[int]:
 var result: Array[int] = []
 for i in range(rooms.size()):
  if rooms[i].visited:
   if not result.has(i): result.append(i)
   for neighbor: int in rooms[i].links:
    if not result.has(neighbor): result.append(neighbor)
 return result
