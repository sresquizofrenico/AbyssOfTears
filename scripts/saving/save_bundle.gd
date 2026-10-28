class_name SaveBundle
extends RefCounted

static func export_code(progress: Node, store: Node) -> String:
 var data: Dictionary={"version":1,"progress":progress.data.duplicate(true),"expedition":store.cached.duplicate(true)}
 data.progress.events.clear()
 var text:=JSON.stringify(RunCodec.pack(data))
 return "AOT5."+Marshalls.utf8_to_base64(JSON.stringify({"payload":text,"sha256":text.sha256_text()}))

static func import_code(code: String, progress: Node, store: Node) -> bool:
 code=code.strip_edges()
 if not code.begins_with("AOT5."): return progress.import_code(code)
 if code.length()>2000000: return false
 var parser:=JSON.new()
 if parser.parse(RunCodec.decode_base64(code.substr(5)))!=OK: return false
 var box: Variant=parser.data
 if not box is Dictionary or not box.get("payload") is String or box.get("sha256")!=box.payload.sha256_text(): return false
 if parser.parse(box.payload)!=OK: return false
 var data: Variant=RunCodec.unpack(parser.data)
 if not data is Dictionary or data.get("version")!=1 or progress.validate(data.get("progress")).is_empty() or not data.get("expedition") is Dictionary: return false
 if not data.expedition.is_empty() and not RunSnapshot.valid(data.expedition): return false
 store.flush()
 var before: Dictionary=progress.data.duplicate(true)
 var old_run: Dictionary=store.cached.duplicate(true)
 if not progress.import_code("AOT4."+Marshalls.utf8_to_base64(JSON.stringify(data.progress))): return false
 if not data.expedition.is_empty() and (not store.submit(data.expedition) or store.flush()!=OK):
  progress.data=before
  progress.save_progress()
  store.cached=old_run
  return false
 return true
