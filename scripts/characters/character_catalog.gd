class_name CharacterCatalog
extends RefCounted

# Keep neris as the stable ID of the original protagonist.
const CHARACTER_RARITIES := ["Común","Raro","Épico","Legendario","Mítico"]
const DATA = [
 {
  "id": "neris",
  "animation_rate": 1,
  "icon": "res://assets/characters/neris_skill.svg",
  "name": "Neris · El Errante",
  "ability": "Impulso Astral",
  "cooldown": 12,
  "duration": 0.22,
  "requirement": "Disponible desde el inicio",
  "counter": "",
  "target": 0,
  "difficulty": "Accesible",
  "advantages": "Versátil y equilibrado",
  "drawbacks": "Sin especialización",
  "story": "Una pequeña luz que busca el camino a casa.",
  "modifiers": {
   "max_health": 0.0,
   "damage": 0.0,
   "attack_interval": 0.11714285714285716,
   "speed": 0.0,
   "attack_range": 0.0,
   "luck": 0,
   "defense": 0.0
  },
  "color": "83dcf0",
  "rarity": 0,
  "passive": "Espíritu Explorador",
  "passive_description": "La primera sala especial de cada piso concede velocidad breve."
 },
 {
  "id": "nyra",
  "animation_rate": 1.3,
  "icon": "res://assets/characters/nyra_skill.svg",
  "sprite": "res://assets/characters/nyra.svg",
  "name": "Nyra, la Sombra",
  "ability": "Paso Umbrío",
  "cooldown": 18,
  "duration": 4,
  "requirement": "Completa tres pisos con El Errante",
  "counter": "wanderer_floors",
  "target": 3,
  "difficulty": "Media",
  "advantages": "Movilidad y señuelo",
  "drawbacks": "Menor vida y daño",
  "story": "Guarda los recuerdos que las sombras olvidan.",
  "modifiers": {
   "max_health": -1.5,
   "damage": -0.11428571428571421,
   "attack_interval": 0.07250000000000001,
   "speed": 53.95833333333334,
   "attack_range": -49.090909090909065,
   "luck": 1,
   "defense": 0.0
  },
  "color": "b28cfa",
  "rarity": 1,
  "passive": "Movimiento Silencioso",
  "passive_description": "Esquivar durante Paso Umbrío concede velocidad breve."
 },
 {
  "id": "kael",
  "animation_rate": 0.85,
  "icon": "res://assets/characters/kael_skill.svg",
  "sprite": "res://assets/characters/kael.svg",
  "name": "Kael, el Fracturado",
  "ability": "Ruptura",
  "cooldown": 16,
  "duration": 1,
  "requirement": "Derrota a un jefe principal",
  "counter": "bosses",
  "target": 1,
  "difficulty": "Media",
  "advantages": "Daño elevado",
  "drawbacks": "Movimiento y cadencia menores",
  "story": "Su armadura rota todavía sostiene una promesa.",
  "modifiers": {
   "max_health": 1.5,
   "damage": 0.48571428571428577,
   "attack_interval": 0.3155555555555556,
   "speed": -26.979166666666686,
   "attack_range": 49.09090909090912,
   "luck": -1,
   "defense": 0.15
  },
  "color": "f5b485",
  "rarity": 1,
  "passive": "Fragmentación",
  "passive_description": "Cada cuarto impacto genera dos fragmentos limitados."
 },
 {
  "id": "lumi",
  "animation_rate": 0.9,
  "icon": "res://assets/characters/lumi_skill.svg",
  "sprite": "res://assets/characters/lumi.svg",
  "name": "Lumi, la Luminosa",
  "ability": "Luz Restauradora",
  "cooldown": 35,
  "duration": 4,
  "requirement": "Completa cinco salas seguidas sin daño",
  "counter": "best_clean_streak",
  "target": 5,
  "difficulty": "Accesible",
  "advantages": "Vida y defensa",
  "drawbacks": "Menor daño y cadencia",
  "story": "Cultiva amaneceres donde nunca llega el sol.",
  "modifiers": {
   "max_health": 3.0,
   "damage": -0.17142857142857149,
   "attack_interval": 0.21454545454545454,
   "speed": -11.5625,
   "attack_range": -29.45454545454544,
   "luck": 0,
   "defense": 0.3
  },
  "color": "f8e7aa",
  "rarity": 1,
  "passive": "Resplandor Protector",
  "passive_description": "Tras recibir daño, reduce el próximo impacto durante 3 s."
 },
 {
  "id": "vex",
  "animation_rate": 1.1,
  "icon": "res://assets/characters/vex_skill.svg",
  "sprite": "res://assets/characters/vex.svg",
  "name": "Vex, el Alquimista",
  "ability": "Mezcla Inestable",
  "cooldown": 20,
  "duration": 4,
  "requirement": "Descubre veinte objetos diferentes",
  "counter": "items",
  "target": 20,
  "difficulty": "Media",
  "advantages": "Elementos alternos",
  "drawbacks": "Menor daño directo",
  "story": "Anota cada reacción en un cuaderno chamuscado.",
  "modifiers": {
   "max_health": 0.0,
   "damage": -0.1428571428571429,
   "attack_interval": 0.11714285714285716,
   "speed": -3.854166666666657,
   "attack_range": 29.454545454545496,
   "luck": 1,
   "defense": 0.0
  },
  "color": "9ce4ac",
  "rarity": 2,
  "passive": "Reacción Alquímica",
  "passive_description": "Dos elementos diferentes pueden producir una reacción limitada."
 },
 {
  "id": "orin",
  "animation_rate": 0.75,
  "icon": "res://assets/characters/orin_skill.svg",
  "sprite": "res://assets/characters/orin.svg",
  "name": "Orin, el Guardián",
  "ability": "Barrera Antigua",
  "cooldown": 24,
  "duration": 3,
  "requirement": "Derrota a un minijefe",
  "counter": "minibosses",
  "target": 1,
  "difficulty": "Accesible",
  "advantages": "Defensa y barrera",
  "drawbacks": "Lento y de alcance corto",
  "story": "Protege una puerta cuyo reino ya no existe.",
  "modifiers": {
   "max_health": 4.5,
   "damage": 0.028571428571428692,
   "attack_interval": 0.26,
   "speed": -46.25,
   "attack_range": -98.18181818181819,
   "luck": -1,
   "defense": 0.44999999999999996
  },
  "color": "75d8ce",
  "rarity": 2,
  "passive": "Fortaleza",
  "passive_description": "Reduce moderadamente el daño de contacto."
 },
 {
  "id": "eira",
  "animation_rate": 0.92,
  "icon": "res://assets/characters/eira_skill.svg",
  "sprite": "res://assets/characters/eira.svg",
  "name": "Eira, la Glacial",
  "ability": "Prisión de Escarcha",
  "cooldown": 22,
  "duration": 3,
  "requirement": "Derrota a cien enemigos",
  "counter": "enemies",
  "target": 100,
  "difficulty": "Media",
  "advantages": "Alcance y control",
  "drawbacks": "Menor cadencia",
  "story": "Lleva el último copo de un invierno perdido.",
  "modifiers": {
   "max_health": 0.0,
   "damage": 0.0,
   "attack_interval": 0.21454545454545454,
   "speed": 0.0,
   "attack_range": 98.18181818181813,
   "luck": 0,
   "defense": 0.0
  },
  "color": "b4ebff",
  "rarity": 2,
  "passive": "Frío Persistente",
  "passive_description": "Golpes consecutivos acumulan frío hasta un límite."
 },
 {
  "id": "solen",
  "animation_rate": 1.16,
  "icon": "res://assets/characters/solen_skill.svg",
  "sprite": "res://assets/characters/solen.svg",
  "name": "Solen, el Incandescente",
  "ability": "Explosión Solar",
  "cooldown": 19,
  "duration": 0.7,
  "requirement": "Derrota a un jefe con un objeto elemental",
  "counter": "elemental_bosses",
  "target": 1,
  "difficulty": "Difícil",
  "advantages": "Quemadura en cada ataque",
  "drawbacks": "Defensa y alcance menores",
  "story": "Esconde una brasa obstinada bajo la capa.",
  "modifiers": {
   "max_health": 0.0,
   "damage": 0.19999999999999996,
   "attack_interval": 0.1446153846153846,
   "speed": 7.708333333333343,
   "attack_range": -68.72727272727275,
   "luck": 0,
   "defense": -0.15
  },
  "color": "ffab71",
  "rarity": 2,
  "passive": "Brasas",
  "passive_description": "Un 35% de ataques quema; menor efecto contra núcleos resistentes."
 },
 {
  "id": "mira",
  "animation_rate": 1.03,
  "icon": "res://assets/characters/mira_skill.svg",
  "sprite": "res://assets/characters/mira.svg",
  "name": "Mira, la Ilusionista",
  "ability": "Reflejo Viviente",
  "cooldown": 28,
  "duration": 7,
  "requirement": "Descubre un secreto y supera la Prueba de Ilusiones",
  "counter": "illusion_path",
  "target": 2,
  "difficulty": "Difícil",
  "advantages": "Copia temporal ofensiva",
  "drawbacks": "Menor vida y daño",
  "story": "En sus espejos se reflejan caminos posibles.",
  "modifiers": {
   "max_health": -1.5,
   "damage": -0.1428571428571429,
   "attack_interval": 0.09333333333333332,
   "speed": 15.416666666666686,
   "attack_range": 29.454545454545496,
   "luck": 2,
   "defense": 0.0
  },
  "color": "c1c4ff",
  "rarity": 3,
  "passive": "Espejismo",
  "passive_description": "Una evasión verificada puede dejar una ilusión breve."
 },
 {
  "id": "nox",
  "animation_rate": 1.2,
  "icon": "res://assets/characters/nox_skill.svg",
  "sprite": "res://assets/characters/nox.svg",
  "name": "Nox, Heredero del Abismo",
  "ability": "Poder del Abismo",
  "cooldown": 30,
  "duration": 4,
  "requirement": "Completa el final principal",
  "counter": "endings",
  "target": 1,
  "difficulty": "Experta",
  "advantages": "Daño y velocidad",
  "drawbacks": "Vida baja; fatiga tras la habilidad",
  "story": "Aprende a llevar una corona que no eligió.",
  "modifiers": {
   "max_health": -1.5,
   "damage": 0.5714285714285714,
   "attack_interval": 0.06303030303030305,
   "speed": 34.6875,
   "attack_range": 0.0,
   "luck": -1,
   "defense": -0.15
  },
  "color": "ce9fff",
  "rarity": 3,
  "passive": "Energía Oscura",
  "passive_description": "Las bajas conceden poder breve, máximo tres acumulaciones."
 },
 {
  "id": "shader",
  "name": "Shader, Heredero de la Determinación",
  "rarity": 4,
  "animation_rate": 1.12,
  "icon": "res://assets/characters/shader_skill.svg",
  "sprite": "res://assets/characters/shader_front.svg",
  "ability": "Instinto de Supervivencia",
  "second_ability": "Despertar del Abismo",
  "cooldown": 24,
  "duration": 6,
  "passive": "Voluntad Inquebrantable",
  "passive_description": "Con vida crítica obtiene daño y velocidad; la Determinación permite despertar.",
  "requirement": "El Camino de la Determinación",
  "counter": "shader_path",
  "target": 7,
  "difficulty": "Mítica",
  "advantages": "Determinación, despertar y supervivencia",
  "drawbacks": "Desafío exclusivo; necesita completar encuentros",
  "story": "El protagonista de «Cuando dejé de ser un adolescente» se niega a rendirse.",
  "color": "cf9cff",
  "modifiers": {
   "max_health": 3,
   "damage": 0.5,
   "attack_interval": 0.04571428571428571,
   "speed": 38.541666666666686,
   "attack_range": 98.18181818181813,
   "luck": 2,
   "defense": 0.15
  }
 }
]

static func definition(id: String) -> Dictionary:
 for entry: Dictionary in DATA:
  if entry.id == id: return entry.duplicate(true)
 return {}

static func progress_node() -> Node:
 var tree := Engine.get_main_loop() as SceneTree
 return tree.root.get_node_or_null("Progress") if tree else null

static func playable(id: String) -> bool:
 if definition(id).is_empty(): return false
 if id == "neris": return true
 var progress := progress_node()
 return progress != null and progress.is_unlocked(id)

static func preview_stats(id: String) -> ActorStats:
 var entry := definition(id)
 if entry.is_empty(): return null
 var stats := ActorStats.new()
 stats.modify(entry.modifiers)
 stats.health = stats.max_health
 stats.base_critical=0.08 if id=="shader" else 0.0
 stats.critical_chance=stats.base_critical
 return stats

static func initial_stats(id: String) -> ActorStats:
 return preview_stats(id) if playable(id) else null

static func texture(id: String) -> Texture2D:
 if id == "neris": return IllustratedNeris.BODY
 if definition(id).is_empty(): return IllustratedNeris.BODY
 # Only the displayed/played character is loaded, not ten large textures at startup.
 return load(definition(id).sprite) as Texture2D

static func ability_icon(id: String) -> Texture2D:
 var entry:=definition(id)
 return load(entry.icon) as Texture2D if not entry.is_empty() else null

static func rarity_name(id: String) -> String:
 var entry:=definition(id)
 return CHARACTER_RARITIES[int(entry.get("rarity",0))]
