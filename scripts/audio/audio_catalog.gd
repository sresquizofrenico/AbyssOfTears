class_name AbyssAudioCatalog
extends RefCounted

const SCORE_PATH := "res://data/soundtrack.json"
const BIOME_KEYS := ["salt","garden","crystal"]
const EFFECTS := ["shoot","hit","hurt","enemy","coin","relic","buy","chest","door","error","ui"]
const EFFECT_DIR := "res://assets/audio/sfx/"
static var _tracks: Dictionary={}

static func tracks() -> Dictionary:
 if _tracks.is_empty():
  var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(SCORE_PATH))
  if data is Dictionary and data.get("version")==1 and data.get("tracks") is Array:
   for entry: Dictionary in data.tracks: _tracks[str(entry.id)]=entry.duplicate(true)
 return _tracks

static func route(state: String, dungeon: bool, floor_index: int, room_kind: String, fighting: bool, paused_track: String="") -> String:
 if state=="victory": return "victory"
 if state=="defeat": return "defeat"
 if state!="playing": return paused_track if paused_track!="" else "menu"
 if not dungeon: return "crystal_boss" if room_kind=="trial" else "salt_combat"
 if not fighting and room_kind in ["shop","treasure","secret","special"]: return "special"
 var biome: String=BIOME_KEYS[clampi(floor_index,0,BIOME_KEYS.size()-1)]
 return biome+"_boss" if room_kind=="boss" and fighting else biome+"_combat" if fighting else biome+"_explore"
