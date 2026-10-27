class_name RelicCatalog
extends RefCounted

const RARITIES := ["Común","Poco común","Raro","Épico","Legendario","Mítico"]
const LEGACY_DATA: Array = [
 {
  "id": "crystal",
  "name": "Cristal de Ruptura",
  "description": "Daño +0,35 por copia.",
  "rarity": 0,
  "category": "pasivo",
  "max_stack": 3,
  "modifiers": {
   "damage": 0.35
  },
  "icon": "res://assets/illustrated/crystal.svg"
 },
 {
  "id": "double",
  "name": "Doble Eco",
  "description": "Dos proyectiles paralelos por ataque.",
  "rarity": 2,
  "category": "pasivo",
  "max_stack": 1,
  "modifiers": {},
  "icon": "res://assets/relics/double.svg"
 },
 {
  "id": "fire",
  "name": "Corazón Ígneo",
  "description": "Los impactos queman durante 3 s.",
  "rarity": 1,
  "category": "pasivo",
  "max_stack": 1,
  "modifiers": {},
  "icon": "res://assets/relics/fire.svg"
 },
 {
  "id": "ice",
  "name": "Lágrima Glacial",
  "description": "Los impactos ralentizan 40% durante 2 s.",
  "rarity": 2,
  "category": "pasivo",
  "max_stack": 1,
  "modifiers": {},
  "icon": "res://assets/relics/ice.svg"
 },
 {
  "id": "electric",
  "name": "Núcleo Eléctrico",
  "description": "Cada tercer impacto salta a otro enemigo cercano.",
  "rarity": 3,
  "category": "pasivo",
  "max_stack": 1,
  "modifiers": {},
  "icon": "res://assets/relics/electric.svg"
 },
 {
  "id": "pierce",
  "name": "Fragmento del Vacío",
  "description": "Cada proyectil atraviesa un enemigo.",
  "rarity": 2,
  "category": "pasivo",
  "max_stack": 1,
  "modifiers": {},
  "icon": "res://assets/relics/pierce.svg"
 },
 {
  "id": "bounce",
  "name": "Esfera de Rebote",
  "description": "Un rebote en paredes por proyectil.",
  "rarity": 1,
  "category": "pasivo",
  "max_stack": 1,
  "modifiers": {},
  "icon": "res://assets/relics/bounce.svg"
 },
 {
  "id": "crown",
  "name": "Corona de Espinas",
  "description": "Añade dos disparos oblicuos.",
  "rarity": 3,
  "category": "pasivo",
  "max_stack": 1,
  "modifiers": {},
  "icon": "res://assets/relics/crown.svg"
 },
 {
  "id": "orbital",
  "name": "Guardián Orbital",
  "description": "Una esfera bloquea proyectiles enemigos.",
  "rarity": 2,
  "category": "pasivo",
  "max_stack": 1,
  "modifiers": {},
  "icon": "res://assets/relics/orbital.svg"
 },
 {
  "id": "mirror",
  "name": "Espejo Fragmentado",
  "description": "Un eco dispara contigo 3 s de cada 10 s.",
  "rarity": 4,
  "category": "pasivo",
  "max_stack": 1,
  "modifiers": {},
  "icon": "res://assets/relics/mirror.svg"
 },
 {
  "id": "shield",
  "name": "Escudo Lunar",
  "description": "Bloquea un impacto cada 8 segundos.",
  "rarity": 2,
  "category": "pasivo",
  "max_stack": 1,
  "modifiers": {},
  "icon": "res://assets/relics/shield.svg"
 },
 {
  "id": "heart",
  "name": "Corazón de Cristal",
  "description": "Vida máxima +1 y recupera un punto.",
  "rarity": 0,
  "category": "pasivo",
  "max_stack": 2,
  "modifiers": {
   "max_health": 1
  },
  "icon": "res://assets/relics/heart.svg"
 },
 {
  "id": "boots",
  "name": "Botas Espectrales",
  "description": "Velocidad +20 por copia.",
  "rarity": 0,
  "category": "pasivo",
  "max_stack": 2,
  "modifiers": {
   "speed": 20
  },
  "icon": "res://assets/relics/boots.svg"
 },
 {
  "id": "clock",
  "name": "Reloj Fracturado",
  "description": "Intervalo entre ataques -0,03 s.",
  "rarity": 1,
  "category": "pasivo",
  "max_stack": 2,
  "modifiers": {
   "attack_interval": -0.03
  },
  "icon": "res://assets/relics/clock.svg"
 }
]
const EXPANSION_PATH := "res://data/relics_expansion.json"
static var DATA: Array=load_expansion()
static var textures: Dictionary = {}
static func load_expansion() -> Array:
 var data: Array=LEGACY_DATA.duplicate(true)
 var source: Variant=JSON.parse_string(FileAccess.get_file_as_string(EXPANSION_PATH))
 if not source is Dictionary or source.get("version")!=1 or not source.get("items") is Array:
  push_error("Invalid relic expansion data")
  return data
 var ids: Dictionary={}
 for entry: Dictionary in data:
  ids[entry.id]=true
  entry.effects=[]
  entry.condition="always"
  entry.price_profile=entry.rarity
  entry.compatibility="composable_bounded"
  entry.appearance_sources=["base","treasure","shop","chest","secret","boss"]
 for entry: Variant in source.items:
  if not valid_entry(entry) or ids.has(entry.get("id")):
   push_error("Invalid or duplicate relic entry")
   continue
  var valid:=true
  for effect: Variant in entry.effects:
   if not RelicEffects.valid_recipe(effect): valid=false
  if not valid:
   push_error("Invalid relic recipe: "+str(entry.id))
   continue
  ids[entry.id]=true
  data.append(entry)
 return data
static func definition(id: String) -> Dictionary:
 for entry: Dictionary in DATA:
  if entry.id == id: return entry
 return {}
static func icon(id: String) -> Texture2D:
 if definition(id).is_empty(): return null
 if not textures.has(id):
  var entry:=definition(id)
  var texture: Texture2D=load(entry.icon)
  if entry.has("icon_region"):
   var atlas:=AtlasTexture.new()
   atlas.atlas=texture
   atlas.region=Rect2(entry.icon_region[0],entry.icon_region[1],entry.icon_region[2],entry.icon_region[3])
   texture=atlas
  textures[id]=texture
 return textures[id]
static func roll(rng: RandomNumberGenerator, floor_id: int = 0, context: String="base") -> String:
 return Economy.roll_relic(rng,floor_id,context)

static func available(id: String) -> bool:
 var entry:=definition(id)
 if entry.get("unlock","")!="main_ending": return not entry.is_empty()
 var progress:=CharacterCatalog.progress_node()
 return progress!=null and (progress.data.bonds.universal or progress.amount("endings")>0)

static func valid_entry(entry: Variant) -> bool:
 if not entry is Dictionary: return false
 if not entry.get("id") is String or not entry.id.is_valid_identifier() or entry.id.length()>64: return false
 if not entry.get("name") is String or entry.name.is_empty() or not entry.get("description") is String or entry.description.is_empty(): return false
 if not entry.get("modifiers") is Dictionary or not entry.get("effects") is Array or (entry.modifiers.is_empty() and entry.effects.is_empty()): return false
 for key in ["rarity","max_stack"]:
  var number: Variant=entry.get(key)
  if not (number is int or number is float) or not is_finite(float(number)) or float(number)!=floorf(float(number)): return false
 if int(entry.rarity) not in range(6) or int(entry.max_stack)<1 or int(entry.max_stack)>5: return false
 if entry.get("category") not in ["pasivo","activo","consumible","reliquia","elemental","especial"]: return false
 for field in entry.modifiers:
  var value: Variant=entry.modifiers[field]
  if field not in ["max_health","damage","speed","attack_interval","attack_range","projectile_speed","defense","luck","effect_chance"] or not (value is int or value is float) or not is_finite(float(value)): return false
 if not entry.get("icon") is String or not entry.icon.begins_with("res://assets/"): return false
 if entry.category=="activo":
  var duration: Variant=entry.get("cooldown")
  if not (duration is int or duration is float) or not is_finite(float(duration)) or float(duration)<5 or float(duration)>120: return false
 var region: Variant=entry.get("icon_region")
 if region!=null:
  if not region is Array or region.size()!=4: return false
  for number in region:
   if not (number is int or number is float) or not is_finite(float(number)): return false
  if region[0]<0 or region[1]<0 or region[2]<=0 or region[3]<=0 or region[0]+region[2]>960 or region[1]+region[3]>864: return false
 for recipe: Variant in entry.effects:
  if not RelicEffects.valid_recipe(recipe): return false
 return true
