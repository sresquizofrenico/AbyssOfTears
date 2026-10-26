extends Node

const PATH := "user://settings.json"
const DEFAULTS := {"version": 1, "quality": 1, "control_scale": 1.0, "control_opacity": 0.75}
var values: Dictionary = DEFAULTS.duplicate()

func _ready() -> void:
 load_settings()

func validate(data: Variant) -> Dictionary:
 var clean := DEFAULTS.duplicate()
 if not data is Dictionary or data.get("version") != 1:
  return clean
 if data.get("quality") is int or data.get("quality") is float:
  clean.quality = clampi(int(data.quality), 0, 2)
 for key in ["control_scale", "control_opacity"]:
  var v = data.get(key)
  if (v is float or v is int) and is_finite(float(v)):
   clean[key] = clampf(float(v), 0.8 if key == "control_scale" else 0.3, 1.25 if key == "control_scale" else 1.0)
 return clean

func load_settings() -> void:
 if not FileAccess.file_exists(PATH):
  return
 var file := FileAccess.open(PATH, FileAccess.READ)
 if file:
  var parser := JSON.new()
  var error := parser.parse(file.get_as_text())
  values = validate(parser.data) if error == OK else DEFAULTS.duplicate()

func save_settings() -> Error:
 values = validate(values)
 var file := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
 if not file:
  return FileAccess.get_open_error()
 file.store_string(JSON.stringify(values))
 file.close()
 return DirAccess.rename_absolute(PATH + ".tmp", PATH)
