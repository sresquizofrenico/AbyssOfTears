class_name RelicInventory
extends RefCounted

var owned: Dictionary = {}
var shield_timer := 0.0
var clock := 0.0
var impacts := 0

func has(id: String) -> bool:
 return int(owned.get(id,0)) > 0

func add(id: String, stats: ActorStats) -> bool:
 var definition := RelicCatalog.definition(id)
 if definition.is_empty() or int(owned.get(id,0)) >= int(definition.max_stack): return false
 owned[id] = int(owned.get(id,0))+1
 stats.modify(definition.modifiers)
 if id == "heart": stats.health = minf(stats.max_health,stats.health+1)
 return true

func tick(delta: float) -> void:
 clock += delta
 shield_timer = maxf(0,shield_timer-delta)

func block_hit() -> bool:
 if has("shield") and shield_timer <= 0:
  shield_timer = 8.0
  return true
 return false

func mirror_active() -> bool:
 return has("mirror") and fmod(clock,10.0)<3.0

func orbital_point(origin: Vector2) -> Vector2:
 return origin + Vector2.from_angle(clock*2.8)*40
