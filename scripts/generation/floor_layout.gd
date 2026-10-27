class_name FloorLayout
extends RefCounted

const DIRECTIONS := [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
const BIOMES := ["Cripta de Sal", "Jardines Hundidos", "Falla de Cristal"]
var rooms: Array[Dictionary] = []
var floor_index := 0
var current := 0
var seed_value := 0
var expanded := false
var boss_room := -1
var secret_room := -1

func generate(run_seed: int, index: int, with_exploration: bool = false) -> void:
 expanded = with_exploration
 boss_room = -1
 secret_room = -1
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
 if expanded: expand_rooms(cells,rng)

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
 return door_visible(index) and not rooms[index].get("locked",false)

func enter(index: int) -> bool:
 if not can_enter(index): return false
 current = index
 rooms[index].visited = true
 return true

func visible_rooms() -> Array[int]:
 var result: Array[int] = []
 for i in range(rooms.size()):
  if rooms[i].visited:
   if not room_hidden(i) and not result.has(i): result.append(i)
   for neighbor: int in rooms[i].links:
    if not room_hidden(neighbor) and not result.has(neighbor): result.append(neighbor)
 if expanded and secret_room>=0 and not room_hidden(secret_room) and not result.has(secret_room): result.append(secret_room)
 for i in range(rooms.size()):
  if rooms[i].get("mapped",false) and not room_hidden(i) and not result.has(i): result.append(i)
 return result

func expand_rooms(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
 # Every addition connects directly to the original unlocked graph. A secret
 # can never become the only path to a required room or the boss.
 for kind in ["shop","special","secret","boss"]:
  var candidates: Array[Vector2i] = []
  for i in range(8):
   for direction: Vector2i in DIRECTIONS:
    var cell: Vector2i = cells[i]+direction
    if not cells.has(cell) and not candidates.has(cell): candidates.append(cell)
  var cell: Vector2i = candidates[rng.randi_range(0,candidates.size()-1)]
  cells.append(cell)
  var room := {"cell":cell,"links":[],"kind":kind,"cleared":kind!="boss","rewarded":false,"visited":false,"locked":kind=="secret","revealed":kind!="secret"}
  rooms.append(room)
  if kind=="boss": boss_room=rooms.size()-1
  if kind=="secret": secret_room=rooms.size()-1
 for i in range(rooms.size()):
  var links: Array[int]=[]
  for direction: Vector2i in DIRECTIONS:
   var neighbor := cells.find(cells[i]+direction)
   if neighbor>=0: links.append(neighbor)
  rooms[i].links=links

func room_hidden(index: int) -> bool:
 return index>=0 and index<rooms.size() and rooms[index].kind=="secret" and not rooms[index].get("revealed",false)

func door_visible(index: int) -> bool:
 return index>=0 and index<rooms.size() and rooms[current].cleared and rooms[current].links.has(index) and not room_hidden(index)

func unlock(index: int, available_keys: int) -> bool:
 if not door_visible(index) or not rooms[index].get("locked",false) or available_keys<1: return false
 rooms[index].locked=false
 return true

func reveal_secret() -> void:
 if secret_room>=0: rooms[secret_room].revealed=true

func boss_defeated() -> bool:
 return boss_room<0 or rooms[boss_room].cleared
