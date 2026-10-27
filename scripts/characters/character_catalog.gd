class_name CharacterCatalog
extends RefCounted

# Keep neris as the stable ID of the original protagonist.
const DATA = [
 {"id":"neris","animation_rate":1,"icon":"res://assets/characters/neris_skill.svg","name":"Neris · El Errante","ability":"Impulso Astral","cooldown":5.0,"duration":0.22,"requirement":"Disponible desde el inicio","counter":"","target":0,"difficulty":"Accesible","advantages":"Versátil y equilibrado","drawbacks":"Sin especialización","story":"Una pequeña luz que busca el camino a casa.","modifiers":{},"color":"83dcf0"},
 {"id":"nyra","animation_rate":1.3,"icon":"res://assets/characters/nyra_skill.svg","sprite":"res://assets/characters/nyra.svg","name":"Nyra, la Sombra","ability":"Paso Umbrío","cooldown":9.0,"duration":3.0,"requirement":"Completa tres pisos con El Errante","counter":"wanderer_floors","target":3,"difficulty":"Media","advantages":"Movilidad y señuelo","drawbacks":"Menor vida y daño","story":"Guarda los recuerdos que las sombras olvidan.","modifiers":{"max_health":-2.0,"damage":-0.15,"speed":40.0},"color":"b28cfa"},
 {"id":"kael","animation_rate":0.85,"icon":"res://assets/characters/kael_skill.svg","sprite":"res://assets/characters/kael.svg","name":"Kael, el Fracturado","ability":"Ruptura","cooldown":8.0,"duration":0.5,"requirement":"Derrota a un jefe principal","counter":"bosses","target":1,"difficulty":"Media","advantages":"Daño elevado","drawbacks":"Movimiento y cadencia menores","story":"Su armadura rota todavía sostiene una promesa.","modifiers":{"damage":0.45,"speed":-25.0,"attack_interval":0.07},"color":"f5b485"},
 {"id":"lumi","animation_rate":0.9,"icon":"res://assets/characters/lumi_skill.svg","sprite":"res://assets/characters/lumi.svg","name":"Lumi, la Luminosa","ability":"Luz Restauradora","cooldown":24.0,"duration":4.0,"requirement":"Completa cinco salas seguidas sin daño","counter":"best_clean_streak","target":5,"difficulty":"Accesible","advantages":"Vida y defensa","drawbacks":"Menor daño y cadencia","story":"Cultiva amaneceres donde nunca llega el sol.","modifiers":{"max_health":2.0,"defense":0.25,"damage":-0.2,"attack_interval":0.04},"color":"f8e7aa"},
 {"id":"vex","animation_rate":1.1,"icon":"res://assets/characters/vex_skill.svg","sprite":"res://assets/characters/vex.svg","name":"Vex, el Alquimista","ability":"Mezcla Inestable","cooldown":10.0,"duration":4.0,"requirement":"Descubre veinte objetos diferentes","counter":"items","target":20,"difficulty":"Media","advantages":"Elementos alternos","drawbacks":"Menor daño directo","story":"Anota cada reacción en un cuaderno chamuscado.","modifiers":{"damage":-0.2,"luck":0.5},"color":"9ce4ac"},
 {"id":"orin","animation_rate":0.75,"icon":"res://assets/characters/orin_skill.svg","sprite":"res://assets/characters/orin.svg","name":"Orin, el Guardián","ability":"Barrera Antigua","cooldown":12.0,"duration":3.0,"requirement":"Derrota a un minijefe","counter":"minibosses","target":1,"difficulty":"Accesible","advantages":"Defensa y barrera","drawbacks":"Lento y de alcance corto","story":"Protege una puerta cuyo reino ya no existe.","modifiers":{"defense":0.5,"speed":-30.0,"attack_range":-100.0},"color":"75d8ce"},
 {"id":"eira","animation_rate":0.92,"icon":"res://assets/characters/eira_skill.svg","sprite":"res://assets/characters/eira.svg","name":"Eira, la Glacial","ability":"Prisión de Escarcha","cooldown":10.0,"duration":3.0,"requirement":"Derrota a cien enemigos","counter":"enemies","target":100,"difficulty":"Media","advantages":"Alcance y control","drawbacks":"Menor cadencia","story":"Lleva el último copo de un invierno perdido.","modifiers":{"attack_range":100.0,"attack_interval":0.05},"color":"b4ebff"},
 {"id":"solen","animation_rate":1.16,"icon":"res://assets/characters/solen_skill.svg","sprite":"res://assets/characters/solen.svg","name":"Solen, el Incandescente","ability":"Explosión Solar","cooldown":11.0,"duration":0.7,"requirement":"Derrota a un jefe con un objeto elemental","counter":"elemental_bosses","target":1,"difficulty":"Difícil","advantages":"Quemadura en cada ataque","drawbacks":"Defensa y alcance menores","story":"Esconde una brasa obstinada bajo la capa.","modifiers":{"defense":-0.2,"attack_range":-60.0},"color":"ffab71"},
 {"id":"mira","animation_rate":1.03,"icon":"res://assets/characters/mira_skill.svg","sprite":"res://assets/characters/mira.svg","name":"Mira, la Ilusionista","ability":"Reflejo Viviente","cooldown":12.0,"duration":4.0,"requirement":"Descubre una habitación secreta","counter":"secrets","target":1,"difficulty":"Difícil","advantages":"Copia temporal ofensiva","drawbacks":"Menor vida y daño","story":"En sus espejos se reflejan caminos posibles.","modifiers":{"max_health":-2.0,"damage":-0.2},"color":"c1c4ff"},
 {"id":"nox","animation_rate":1.2,"icon":"res://assets/characters/nox_skill.svg","sprite":"res://assets/characters/nox.svg","name":"Nox, Heredero del Abismo","ability":"Poder del Abismo","cooldown":16.0,"duration":4.0,"requirement":"Completa el final principal","counter":"endings","target":1,"difficulty":"Experta","advantages":"Daño y velocidad","drawbacks":"Vida baja; fatiga tras la habilidad","story":"Aprende a llevar una corona que no eligió.","modifiers":{"max_health":-3.0,"damage":0.25,"speed":25.0,"defense":-0.1},"color":"ce9fff"}
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
