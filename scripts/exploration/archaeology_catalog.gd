class_name ArchaeologyCatalog
extends RefCounted
const PATH := "res://data/archaeology.json"
const RARITIES := ["Vestigio común","Vestigio poco común","Vestigio raro"]
static var _entries: Array[Dictionary]=[]
static var _config: Dictionary={}

static func config() -> Dictionary:
 if _config.is_empty():
  var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
  if parsed is Dictionary: _config=parsed
 return _config

static func entries() -> Array[Dictionary]:
 if _entries.is_empty():
  var parsed: Variant=config()
  if parsed is Dictionary and parsed.get("version")==1 and parsed.get("artifacts") is Array:
   for entry: Dictionary in parsed.artifacts: _entries.append(entry)
 return _entries

static func definition(id: String) -> Dictionary:
 for entry: Dictionary in entries():
  if entry.id==id: return entry.duplicate(true)
 return {}

static func roll(rng: RandomNumberGenerator, floor_index: int, source: String, found: Array) -> String:
 var candidates: Array[Dictionary]=[]
 var total:=0
 for entry: Dictionary in entries():
  if int(entry.floor)!=floor_index or not entry.sources.has(source) or found.has(entry.id): continue
  var weight: int=int(config().get("rarity_weights",[7,3,1])[int(entry.rarity)])
  candidates.append({"id":entry.id,"weight":weight})
  total+=weight
 if total<=0: return ""
 var value:=rng.randi_range(0,total-1)
 for candidate in candidates:
  value-=int(candidate.weight)
  if value<0: return candidate.id
 return ""

static func errors() -> Array[String]:
 var result: Array[String]=[]
 var weights: Variant=config().get("rarity_weights")
 if not weights is Array or weights.size()!=3:
  result.append("Invalid archaeology rarity weights")
 else:
  var total:=0.0
  for weight: Variant in weights:
   if not (weight is int or weight is float) or not is_finite(float(weight)) or float(weight)<0 or float(weight)>1000 or float(weight)!=float(int(weight)): result.append("Invalid archaeology weight")
   else: total+=float(weight)
  if total<=0: result.append("Empty archaeology weight table")
 var ids: Dictionary={}
 for entry: Dictionary in entries():
  var id: String=entry.get("id","")
  if id.is_empty() or ids.has(id): result.append("Duplicate/empty artifact ID")
  ids[id]=true
  if entry.get("effect","") not in ["story","hint","key","map"]: result.append("Unknown artifact effect")
  for field in ["floor","rarity"]:
   var value: Variant=entry.get(field)
   if not (value is float or value is int) or not is_finite(float(value)) or float(value)!=float(int(value)) or float(value)<0 or float(value)>2: result.append("Invalid artifact "+field)
  for field in ["name","story","summary","icon"]:
   if not entry.get(field) is String or str(entry[field]).is_empty(): result.append("Missing artifact "+field)
  if not ResourceLoader.exists(str(entry.get("icon",""))): result.append("Missing artifact icon")
  if not entry.get("sources") is Array or entry.sources.is_empty(): result.append("Missing artifact source")
 return result
