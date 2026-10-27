class_name AbyssJournal
extends RefCounted

const CATEGORIES := ["floors","rooms","items","creatures","bosses","secrets","maps","events","machines"]
const STORED := ["floors","rooms","creatures","bosses","secrets","maps","events","machines"]
const TITLES := {"floors":"Pisos descubiertos","rooms":"Salas especiales","items":"Objetos recogidos","creatures":"Criaturas observadas","bosses":"Jefes encontrados","secrets":"Rutas secretas","maps":"Mapas completos","events":"Desafíos superados","machines":"Máquinas antiguas"}
const FLOOR_IDS := ["salt_crypt","sunken_gardens","crystal_fault"]
const ROOM_NAMES := {"treasure":"Cámara de tesoro","shop":"Tienda del abismo","special":"Sala de mecanismos","secret":"Cámara secreta","boss":"Cámara del custodio","descent":"Escalera de descenso"}
const EVENTS := {"illusion_trial":"Prueba de Ilusiones","shader_trial":"La Prueba de Shader","ending":"El sello purificado"}
const LIMIT := 256

static func fresh() -> Dictionary:
 var result: Dictionary={}
 for category: String in STORED: result[category]=[]
 return result

static func floor_id(index: int) -> String:
 return FLOOR_IDS[index] if index>=0 and index<FLOOR_IDS.size() else ""

static func valid_id(category: String, id: String) -> bool:
 if id.length()>100: return false
 match category:
  "floors","maps": return id in FLOOR_IDS
  "rooms": return ROOM_NAMES.has(id)
  "items": return not RelicCatalog.definition(id).is_empty()
  "creatures":
   for entry: Dictionary in EnemyCatalog.DATA:
    if entry.id==id: return true
  "bosses": return id in TideWarden.BOSS_IDS
  "events": return EVENTS.has(id)
  "secrets":
   var parts:=id.split(":")
   if parts.size()!=4 or parts[0] not in FLOOR_IDS: return false
   for i in range(1,4):
    if not parts[i].is_valid_int() or str(int(parts[i]))!=parts[i]: return false
   return int(parts[1])>=0 and int(parts[1])<=2147483647 and absi(int(parts[2]))<=64 and absi(int(parts[3]))<=64
 return false # Machines have no implemented catalog yet; never invent repairs.

static func validate(value: Variant) -> Dictionary:
 if not value is Dictionary: return {}
 var result:=fresh()
 for category: String in STORED:
  var entries: Variant=value.get(category,[])
  if not entries is Array or entries.size()>LIMIT: return {}
  for id: Variant in entries:
   if not id is String: return {}
   if valid_id(category,id) and not result[category].has(id): result[category].append(id)
 return result

static func room_observations(layout: FloorLayout, enemies: Array) -> Dictionary:
 var id:=floor_id(layout.floor_index)
 if id.is_empty() or layout.rooms.is_empty(): return {}
 var room: Dictionary=layout.rooms[layout.current]
 var result: Dictionary={"floors":[id],"rooms":[],"creatures":[],"bosses":[],"secrets":[],"maps":[]}
 if ROOM_NAMES.has(room.kind): result.rooms.append(room.kind)
 for enemy in enemies:
  if not is_instance_valid(enemy) or enemy.dead: continue
  if enemy is TideWarden:
   if not result.bosses.has(enemy.definition.id): result.bosses.append(enemy.definition.id)
  elif not result.creatures.has(enemy.definition.id): result.creatures.append(enemy.definition.id)
 if room.kind=="secret":
  var cell: Vector2i=room.cell
  result.secrets.append("%s:%d:%d:%d" % [id,layout.seed_value,cell.x,cell.y])
 # A complete map includes the secret, not just the initially visible graph.
 if layout.expanded and layout.rooms.all(func(entry): return entry.visited): result.maps.append(id)
 return result

static func entries(data: Dictionary, category: String) -> Array:
 return data.items.duplicate() if category=="items" else data.journal.get(category,[]).duplicate()

static func title(category: String, id: String) -> String:
 match category:
  "floors","maps": return FloorLayout.BIOMES[FLOOR_IDS.find(id)]
  "rooms": return ROOM_NAMES.get(id,id)
  "items": return RelicCatalog.definition(id).get("name",id)
  "creatures":
   for entry: Dictionary in EnemyCatalog.DATA:
    if entry.id==id: return entry.name
  "bosses": return TideWarden.BOSS_NAMES[TideWarden.BOSS_IDS.find(id)]
  "events": return EVENTS.get(id,id)
  "secrets":
   var parts:=id.split(":")
   return "%s · semilla %s · (%s, %s)" % [title("floors",parts[0]),parts[1],parts[2],parts[3]]
 return id

static func description(category: String, id: String) -> String:
 match category:
  "items": return RelicCatalog.definition(id).description
  "maps": return "Todas las habitaciones visitadas, incluida la cámara secreta. Cada piso cuenta una vez entre partidas."
  "floors": return "Piso visitado en una expedición."
  "rooms": return "Tipo de sala descubierto durante la exploración."
  "bosses": return "Encuentro registrado. Encontrar un jefe no significa haberlo derrotado."
  "events": return "Objetivo completado en una partida real."
  "secrets": return "Ruta visitada. Repetir esta semilla y entrada no duplica el hallazgo."
  "creatures":
   for entry: Dictionary in EnemyCatalog.DATA:
    if entry.id==id: return "Datos base · vida %.1f · daño %.1f · resistencia %.0f%%. Las variantes pueden cambiar estos valores." % [entry.health,entry.damage,float(entry.resistance)*100]
 return ""
