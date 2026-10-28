extends Node
signal saved
signal failed(error: Error)
const PATH:="user://expedition.json"
const LIMIT:=1500000
var storage_path:=PATH
var cached: Dictionary={}
var recovered:=false
var last_error: Error=OK
var worker: Thread
var queued: String=""
var writing:=false

func _ready() -> void:
 cached=load_disk()

func envelope(text: String) -> Dictionary:
 return {"format":"abyss-expedition","payload":text,"sha256":text.sha256_text()}

func read_one(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {}
 var file:=FileAccess.open(path,FileAccess.READ)
 if not file or file.get_length()>LIMIT: return {}
 var parser:=JSON.new()
 if parser.parse(file.get_as_text())!=OK or not parser.data is Dictionary: return {}
 var box: Dictionary=parser.data
 if box.get("format")!="abyss-expedition" or not box.get("payload") is String or not box.get("sha256") is String or box.payload.sha256_text()!=box.sha256: return {}
 if parser.parse(box.payload)!=OK: return {}
 var decoded: Variant=RunCodec.unpack(parser.data)
 return decoded if RunSnapshot.valid(decoded) else {}

func load_disk() -> Dictionary:
 recovered=false
 var result:=read_one(storage_path)
 if result.is_empty():
  result=read_one(storage_path+".bak")
  recovered=not result.is_empty()
 return result

func available() -> bool:
 return not cached.is_empty() and cached.get("active",false)

func submit(data: Dictionary) -> bool:
 if not RunSnapshot.valid(data):
  last_error=ERR_INVALID_DATA
  failed.emit(last_error)
  return false
 cached=data.duplicate(true)
 var text:=JSON.stringify(RunCodec.pack(data))
 queued=JSON.stringify(envelope(text))
 if queued.length()>LIMIT:
  queued=""
  last_error=ERR_OUT_OF_MEMORY
  failed.emit(last_error)
  return false
 last_error=OK
 begin_write()
 return true

func begin_write() -> void:
 if writing or queued.is_empty(): return
 writing=true
 var text:=queued
 queued=""
 worker=Thread.new()
 var error:=worker.start(write_file.bind(storage_path,text))
 if error!=OK:
  writing=false
  last_error=error
  failed.emit(error)

# Only immutable text and filesystem calls in the worker, no scene-tree access.
static func write_file(path: String, text: String) -> Error:
 var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if not file: return FileAccess.get_open_error()
 file.store_string(text)
 file.flush()
 var error:=file.get_error()
 file.close()
 if error!=OK: return error
 # Keep a previously validated main file as backup. Never replace a good backup
 # with a corrupt main file that was recovered from the backup on startup.
 var check:=JSON.new()
 var inactive:=false
 if check.parse(text)==OK:
  var payload_text: String=check.data.get("payload","")
  if check.parse(payload_text)==OK: inactive=check.data is Dictionary and check.data.get("active")==false
 if inactive:
  var backup:=FileAccess.open(path+".bak.tmp",FileAccess.WRITE)
  if not backup: return FileAccess.get_open_error()
  backup.store_string(text)
  backup.flush()
  error=backup.get_error()
  backup.close()
  if error!=OK: return error
  error=DirAccess.rename_absolute(path+".bak.tmp",path+".bak")
  if error!=OK: return error
 elif FileAccess.file_exists(path):
  var old:=FileAccess.get_file_as_string(path)
  var parser:=JSON.new()
  if parser.parse(old)==OK and parser.data is Dictionary and parser.data.get("payload") is String and parser.data.get("sha256")==parser.data.payload.sha256_text():
   error=DirAccess.copy_absolute(path,path+".bak.tmp")
   if error!=OK: return error
   error=DirAccess.rename_absolute(path+".bak.tmp",path+".bak")
   if error!=OK: return error
 return DirAccess.rename_absolute(path+".tmp",path)

func poll_write() -> void:
 if not writing or worker.is_alive(): return
 var error: Error=worker.wait_to_finish()
 worker=null
 writing=false
 last_error=error
 if error==OK: saved.emit()
 else: failed.emit(error)
 begin_write()

func _process(_delta: float) -> void:
 poll_write()

func flush() -> Error:
 # Lifecycle boundaries wait only for bounded local writes; regular play is async.
 while writing or not queued.is_empty():
  if writing:
   var error: Error=worker.wait_to_finish()
   worker=null
   writing=false
   last_error=error
   if error==OK: saved.emit()
   else: failed.emit(error)
  begin_write()
 return last_error

func invalidate() -> bool:
 return submit({"version":RunSnapshot.VERSION,"active":false})

func _exit_tree() -> void:
 flush()
