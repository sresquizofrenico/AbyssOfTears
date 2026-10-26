class_name RelicCatalog
extends RefCounted

const DROP_SETTINGS := {"room_chance":0.45,"chest_chance":0.5,"chest_coins":0.3,"chest_heal":0.2}
const RARITIES := ["Común","Poco común","Raro","Épico","Legendario"]
const DATA: Array = [
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
  "icon": "res://assets/relics/crystal.svg"
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
static var textures: Dictionary = {}
static func definition(id: String) -> Dictionary:
 for entry: Dictionary in DATA:
  if entry.id == id: return entry
 return {}
static func icon(id: String) -> Texture2D:
 if not textures.has(id): textures[id] = load(definition(id).icon)
 return textures[id]
static func roll(rng: RandomNumberGenerator, floor_id: int = 0) -> String:
 var weights: Array[float] = []
 var total := 0.0
 for entry: Dictionary in DATA:
  var weight: float = [50.0,28.0,14.0,6.0,2.0][int(entry.rarity)]
  weight *= 1.0 + floor_id * float(entry.rarity) * 0.15
  weights.append(weight)
  total += weight
 var value := rng.randf() * total
 for i in range(DATA.size()):
  value -= weights[i]
  if value <= 0: return DATA[i].id
 return DATA[0].id
