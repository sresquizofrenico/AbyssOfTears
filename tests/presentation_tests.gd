extends SceneTree
var checks:=0
var failures:=0
func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var entries:=CharacterPresentation.entries()
 check(entries.size()==20,"Neither mode duplicates heroes")
 var aliases:=0
 for entry: Dictionary in entries:
  var original:=CharacterCatalog.definition(entry.id)
  check(entry.modifiers==original.modifiers and entry.cooldown==original.cooldown,"Reference cards preserve actual mechanics")
  if entry.name!=original.name: aliases+=1
  check(not original.name.contains("Nakano") and not original.name.contains("Gasai"),"Public catalog remains original")
 check(aliases==(9 if CharacterPresentation.private_enabled() else 0),"Private editor gate changes only nine reference labels")
 check(not CharacterPresentation.private_enabled() or OS.has_feature("editor") and not OS.has_feature("android"),"Private prototype never enabled on Android")
 var codec_samples: Array=[Vector2(1.25,-2.5),Vector2i(3,-4),{"á":"lágrima","v":Vector2.UP},[1,2.5,true]]
 for sample in codec_samples:
  var parser:=JSON.new()
  parser.parse(JSON.stringify(RunCodec.pack(sample)))
  check(RunCodec.unpack(parser.data)==sample,"JSON preserves vectors and UTF-8")
 for invalid in ["invalid!","////","a===","sQ=="]: check(RunCodec.decode_base64(invalid)=="","Invalid portable UTF-8 fails quietly")
 print("PRESENTATION RESULT: %d checks, %d failures · %s" % [checks,failures,"private cards" if CharacterPresentation.private_enabled() else "public"])
 quit(0 if failures==0 else 1)
