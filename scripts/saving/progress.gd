extends Node

signal character_unlocked(id: String)
signal save_failed(error: Error)
const VERSION := 1
const COUNTERS := ["enemies","bosses","minibosses","floors","wanderer_floors","clean_streak","best_clean_streak","secrets","endings","elemental_bosses"]
var storage_path := "user://progress.json"
var data: Dictionary = fresh()
var recovered := false

func fresh() -> Dictionary:
 var value := {"version":VERSION,"serial":0,"counters":{},"items":[],"events":{},"unlocked":["neris"],"pending":[]}
 for key in COUNTERS: value.counters[key]=0
 return value

func _ready() -> void:
 load_progress()

func validate(value: Variant) -> Dictionary:
 if not value is Dictionary or value.get("version")!=VERSION: return {}
 var clean := fresh()
 for key in ["serial"]:
  var number = value.get(key,0)
  if not (number is float or number is int) or not is_finite(float(number)): return {}
  clean[key]=clampi(int(number),0,2147483646)
 var counts = value.get("counters",{})
 if not counts is Dictionary: return {}
 for key in COUNTERS:
  var number = counts.get(key,0)
  if not (number is float or number is int) or not is_finite(float(number)): return {}
  clean.counters[key]=clampi(int(number),0,100000000)
 for field in ["items","unlocked","pending"]:
  if not value.get(field,[]) is Array: return {}
  for id in value.get(field,[]):
   if not id is String: return {}
   var valid: bool = not RelicCatalog.definition(id).is_empty() if field=="items" else not CharacterCatalog.definition(id).is_empty()
   if valid and not clean[field].has(id): clean[field].append(id)
 var events = value.get("events",{})
 if not events is Dictionary or events.size()>4096: return {}
 for key in events:
  if not key is String or key.length()>160 or events[key]!=true: return {}
  clean.events[key]=true
 return clean

func read_file(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {}
 var file := FileAccess.open(path,FileAccess.READ)
 if not file or file.get_length()>1048576: return {}
 var parser := JSON.new()
 if parser.parse(file.get_as_text())!=OK: return {}
 return validate(parser.data)

func load_progress() -> void:
 var loaded := read_file(storage_path)
 recovered=false
 if loaded.is_empty():
  loaded=read_file(storage_path+".bak")
  recovered=not loaded.is_empty()
 data=loaded if not loaded.is_empty() else fresh()

func save_progress() -> Error:
 var file := FileAccess.open(storage_path+".tmp",FileAccess.WRITE)
 if not file: return FileAccess.get_open_error()
 file.store_string(JSON.stringify(data))
 file.flush()
 var result := file.get_error()
 file.close()
 if result!=OK: return result
 # Preserve the last valid copy; never overwrite it with a corrupted primary file.
 if not read_file(storage_path).is_empty():
  result=DirAccess.copy_absolute(storage_path,storage_path+".bak")
  if result!=OK: return result
 return DirAccess.rename_absolute(storage_path+".tmp",storage_path)

func is_unlocked(id: String) -> bool:
 return id=="neris" or data.unlocked.has(id)

func amount(counter: String) -> int:
 return data.items.size() if counter=="items" else int(data.counters.get(counter,0))

func commit(previous: Dictionary) -> bool:
 var result := save_progress()
 if result!=OK:
  data=previous
  save_failed.emit(result)
  return false
 for id in data.unlocked:
  if not previous.unlocked.has(id): character_unlocked.emit(id)
 return true

func evaluate() -> void:
 for entry: Dictionary in CharacterCatalog.DATA:
  if not is_unlocked(entry.id) and amount(entry.counter)>=int(entry.target):
   data.unlocked.append(entry.id)
   if not data.pending.has(entry.id): data.pending.append(entry.id)

func begin_run() -> bool:
 var previous := data.duplicate(true)
 data.serial=int(data.serial)+1
 data.events.clear()
 data.counters.clean_streak=0
 return commit(previous)

# Events are unique within a persistent run serial, consumed before counters change.
# Tests/laboratories never call this method through the gameplay adapter.
func record(event: String, token: String, payload: Dictionary={}) -> bool:
 if event not in ["enemy","boss","miniboss","floor","room","item","secret","ending"] or token.is_empty() or token.length()>120: return false
 var key := event+":"+token
 if data.events.has(key) or data.events.size()>=4096: return false
 if event=="item" and RelicCatalog.definition(str(payload.get("id",""))).is_empty(): return false
 var previous := data.duplicate(true)
 data.events[key]=true
 match event:
  "enemy": data.counters.enemies+=1
  "boss":
   data.counters.bosses+=1
   if payload.get("elemental",false): data.counters.elemental_bosses+=1
  "miniboss": data.counters.minibosses+=1
  "floor":
   data.counters.floors+=1
   if payload.get("character")=="neris": data.counters.wanderer_floors+=1
  "room":
   data.counters.clean_streak=int(data.counters.clean_streak)+1 if payload.get("clean",false) else 0
   data.counters.best_clean_streak=maxi(int(data.counters.best_clean_streak),int(data.counters.clean_streak))
  "item":
   if not data.items.has(payload.id): data.items.append(payload.id)
  "secret": data.counters.secrets+=1
  "ending": data.counters.endings+=1
 evaluate()
 return commit(previous)

func acknowledge(id: String) -> bool:
 if not data.pending.has(id): return false
 var previous := data.duplicate(true)
 data.pending.erase(id)
 return commit(previous)

func export_code() -> String:
 var backup:=data.duplicate(true)
 backup.events.clear()
 backup.counters.clean_streak=0
 return "AOT1."+Marshalls.utf8_to_base64(JSON.stringify(backup))

func import_code(code: String) -> bool:
 code=code.strip_edges()
 if not code.begins_with("AOT1.") or code.length()>1500000: return false
 var parser:=JSON.new()
 if parser.parse(Marshalls.base64_to_utf8(code.substr(5)))!=OK: return false
 var incoming:=validate(parser.data)
 if incoming.is_empty(): return false
 var previous:=data.duplicate(true)
 for counter in COUNTERS:
  data.counters[counter]=maxi(int(data.counters[counter]),int(incoming.counters[counter]))
 data.counters.clean_streak=0
 for field in ["items","unlocked"]:
  for id in incoming[field]:
   if not data[field].has(id): data[field].append(id)
 data.serial=maxi(int(data.serial),int(incoming.serial))
 evaluate()
 return commit(previous)
