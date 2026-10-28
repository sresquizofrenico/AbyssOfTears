extends Node

const PATH := "user://settings.json"
const DEFAULTS := {"version": 1, "quality": 1, "control_scale": 1.0, "control_opacity": 0.75, "diagnostics": false, "stats_view": 0,"move_deadzone":0.12,"floating_joystick":false,"fire_style":0,"left_handed":false,"music_volume":0.55,"sfx_volume":0.8,"selected_character":"neris"}
var values: Dictionary = DEFAULTS.duplicate()
var dirty_age: float=-1.0

func _ready() -> void:
 load_settings()

func validate(data: Variant) -> Dictionary:
 var clean := DEFAULTS.duplicate()
 if not data is Dictionary or data.get("version") != 1:
  return clean
 if data.get("quality") is int or data.get("quality") is float:
  clean.quality = clampi(int(data.quality), 0, 2)
 if (data.get("stats_view") is int or data.get("stats_view") is float) and is_finite(float(data.stats_view)):
  clean.stats_view=clampi(int(data.stats_view),0,2)
 for key in ["diagnostics","floating_joystick","left_handed"]:
  if data.get(key) is bool: clean[key]=data[key]
 if (data.get("fire_style") is int or data.get("fire_style") is float) and is_finite(float(data.fire_style)): clean.fire_style=clampi(int(data.fire_style),0,1)
 var deadzone: Variant=data.get("move_deadzone")
 if (deadzone is int or deadzone is float) and is_finite(float(deadzone)): clean.move_deadzone=clampf(float(deadzone),0.08,0.28)
 for key in ["control_scale", "control_opacity"]:
  var v = data.get(key)
  if (v is float or v is int) and is_finite(float(v)):
   clean[key] = clampf(float(v), 0.8 if key == "control_scale" else 0.3, 1.25 if key == "control_scale" else 1.0)
 for key in ["music_volume","sfx_volume"]:
  var v: Variant=data.get(key)
  if (v is float or v is int) and is_finite(float(v)): clean[key]=clampf(float(v),0,1)
 if data.get("selected_character") is String and not CharacterCatalog.definition(data.selected_character).is_empty(): clean.selected_character=data.selected_character
 return clean

func read_settings(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {}
 var file:=FileAccess.open(path,FileAccess.READ)
 if not file or file.get_length()>65536: return {}
 var parser:=JSON.new()
 if parser.parse(file.get_as_text())!=OK or not parser.data is Dictionary or parser.data.get("version")!=1: return {}
 return validate(parser.data)

func load_settings() -> void:
 var result:=read_settings(PATH)
 if result.is_empty(): result=read_settings(PATH+".bak")
 values=result if not result.is_empty() else DEFAULTS.duplicate()

func schedule_save() -> void:
 dirty_age=0.4

func _process(delta: float) -> void:
 if dirty_age<0: return
 dirty_age-=delta
 if dirty_age<=0:
  dirty_age=-1
  save_settings()

func _exit_tree() -> void:
 if dirty_age>=0: save_settings()

func save_settings() -> Error:
 values = validate(values)
 var file := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
 if not file:
  return FileAccess.get_open_error()
 file.store_string(JSON.stringify(values))
 file.flush()
 var error:=file.get_error()
 file.close()
 if error!=OK: return error
 if not read_settings(PATH).is_empty():
  error=DirAccess.copy_absolute(PATH,PATH+".bak.tmp")
  if error!=OK: return error
  error=DirAccess.rename_absolute(PATH+".bak.tmp",PATH+".bak")
  if error!=OK: return error
 dirty_age=-1
 return DirAccess.rename_absolute(PATH + ".tmp", PATH)
