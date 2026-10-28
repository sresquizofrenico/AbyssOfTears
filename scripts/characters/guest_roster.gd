class_name GuestRoster
extends RefCounted
# Optional private pack. Public APKs contain no pack, names, portraits or sprites.
const PACK:="res://"+"private_pack/catalog.json"
static var cache: Array=[]
static var loaded:=false
static var lookup: Dictionary={}
static var atlas: Texture2D
static var frames: Dictionary={}
static func enabled() -> bool:
 return OS.has_feature("abyss_private") or (OS.has_feature("editor") and not OS.has_feature("android") and OS.get_cmdline_user_args().has("--private-anime"))
static func entries() -> Array:
 if not enabled(): return []
 if loaded: return cache.duplicate(true)
 loaded=true
 if not FileAccess.file_exists(PACK): return []
 var parser:=JSON.new()
 if parser.parse(FileAccess.get_file_as_string(PACK))!=OK or not parser.data is Dictionary or not parser.data.get("characters") is Array: return []
 for entry in parser.data.characters:
  if not entry is Dictionary or not str(entry.get("id","")).begins_with("guest_") or entry.get("role") not in ["performer","tempest","analyst","athlete","scholar","seer","explorer","automaton","naturalist"]: continue
  cache.append(entry.duplicate(true))
  lookup[str(entry.id)]=cache.back()
 return cache.duplicate(true)
static func definition(id: String) -> Dictionary:
 if not id.begins_with("guest_"): return {}
 if not loaded: entries()
 return lookup.get(id,{})
static func behavior(id: String) -> String:
 return str(definition(id).get("behavior",id))
static func role(player) -> String:
 return str(definition(player.roster_id).get("role",""))
static func texture(id: String) -> Texture2D:
 var entry:=definition(id)
 if entry.is_empty(): return null
 if not frames.has(id):
  if atlas==null: atlas=load(str(entry.sprite))
  var size: Vector2=atlas.get_size()/3.0
  var frame:=AtlasTexture.new()
  frame.atlas=atlas
  var region: Array=entry.get("region",[])
  frame.region=Rect2(region[0],region[1],region[2],region[3]) if region.size()==4 else Rect2(Vector2(int(entry.cell)%3,int(entry.cell)/3)*size,size)
  frame.filter_clip=true
  frames[id]=frame
 return frames[id]
