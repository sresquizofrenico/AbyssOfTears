class_name CharacterCatalog
extends RefCounted

# Initial stats are created here for both the preview and the actual player.
# No invented unlocks or abilities: Neris is the only implemented character.
const DATA = [{"id":"neris", "name":"Neris", "unlocked":true,
 "requirement":"Disponible desde el inicio", "ability":"Lágrimas del faro · disparo en cuatro direcciones",
 "starting_items":[], "modifiers":{}}]

static func definition(id: String) -> Dictionary:
 for entry: Dictionary in DATA:
  if entry.id == id: return entry.duplicate(true)
 return {}

static func playable(id: String) -> bool:
 var entry := definition(id)
 return not entry.is_empty() and entry.get("unlocked",false)

static func initial_stats(id: String) -> ActorStats:
 if not playable(id): return null
 var stats := ActorStats.new()
 stats.modify(definition(id).modifiers)
 stats.health = stats.max_health
 return stats
