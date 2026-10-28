class_name RunCodec
extends RefCounted

# JSON only: never deserialize objects/resources or execute Variant expressions.
static func pack(value: Variant) -> Variant:
 if value is Vector2 or value is Vector2i: return {"@v":2 if value is Vector2 else 3,"x":value.x,"y":value.y}
 if value is Array:
  var out: Array=[]
  for item in value: out.append(pack(item))
  return out
 if value is Dictionary:
  var out: Dictionary={}
  for key in value: out[str(key)]=pack(value[key])
  return out
 return value

static func unpack(value: Variant, depth: int=0) -> Variant:
 if depth>16: return null
 if value is Dictionary:
  if value.has("@v"):
   if value.size()!=3 or (value.get("@v")!=2 and value.get("@v")!=3) or not number(value.get("x")) or not number(value.get("y")): return null
   return Vector2(value.x,value.y) if value["@v"]==2 else Vector2i(value.x,value.y)
  if value.size()>4096: return null
  var out: Dictionary={}
  for key in value:
   if not key is String or key.length()>150: return null
   var decoded=unpack(value[key],depth+1)
   if decoded==null and value[key]!=null: return null
   out[key]=decoded
  return out
 if value is Array:
  if value.size()>4096: return null
  var out: Array=[]
  for item in value:
   var decoded=unpack(item,depth+1)
   if decoded==null and item!=null: return null
   out.append(decoded)
  return out
 if value is String: return value if value.length()<=4096 else null
 if value is bool or value==null: return value
 if number(value): return int(value) if float(value)==floorf(float(value)) else value
 return null

static func number(value: Variant) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and absf(float(value))<=1e12

static func take(object: Object, fields: Array) -> Dictionary:
 var data: Dictionary={}
 for field: String in fields: data[field]=object.get(field)
 return data.duplicate(true)

static func put(object: Object, fields: Array, data: Dictionary) -> void:
 for field: String in fields:
  if not data.has(field): continue
  var current: Variant=object.get(field)
  if current is Array:
   current.assign(data[field])
  else: object.set(field,data[field])

static func matches(reference: Variant, value: Variant) -> bool:
 if reference==null: return value==null
 if reference is float or reference is int: return number(value)
 if reference is Dictionary:
  if not value is Dictionary: return false
  for key in value:
   if reference.has(key) and not matches(reference[key],value[key]): return false
  return true
 if reference is Array:
  if not value is Array: return false
  if reference.is_typed():
   for item in value:
    if reference.get_typed_builtin()!=TYPE_NIL and typeof(item)!=reference.get_typed_builtin() and not (reference.get_typed_builtin()==TYPE_INT and number(item)): return false
  return true
 return typeof(reference)==typeof(value)

static func valid_fields(object: Object, fields: Array, value: Variant) -> bool:
 if not value is Dictionary or value.size()!=fields.size(): return false
 for field: String in fields:
  if not value.has(field) or not matches(object.get(field),value[field]): return false
 return true

static func decode_base64(encoded: String) -> String:
 if encoded.length()%4!=0: return ""
 var alphabet:=RegEx.new()
 alphabet.compile("^[A-Za-z0-9+/]*={0,2}$")
 if not alphabet.search(encoded): return ""
 var bytes:=Marshalls.base64_to_raw(encoded)
 var i:=0
 while i<bytes.size():
  var first:=int(bytes[i])
  var count:=1 if first<128 else 2 if first>=194 and first<=223 else 3 if first>=224 and first<=239 else 4 if first>=240 and first<=244 else 0
  if count==0 or i+count>bytes.size(): return ""
  for j in range(1,count):
   if bytes[i+j]<128 or bytes[i+j]>191: return ""
  if count==3 and ((first==224 and bytes[i+1]<160) or (first==237 and bytes[i+1]>=160)): return ""
  if count==4 and ((first==240 and bytes[i+1]<144) or (first==244 and bytes[i+1]>=144)): return ""
  i+=count
 return bytes.get_string_from_utf8()
