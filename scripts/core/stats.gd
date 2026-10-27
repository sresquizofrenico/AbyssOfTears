class_name ActorStats
extends RefCounted

var max_health: float = 6.0
var health: float = 6.0
var _damage: float = 1.0
var damage: float:
 get: return clampf(_damage+temporary_sum("damage"),0.1,1000.0)
 set(value): _damage=value-temporary_sum("damage")
var _speed: float = 185.0
var speed: float:
 get: return clampf(_speed+temporary_sum("speed"),40.0,400.0)
 set(value): _speed=value-temporary_sum("speed")
var _attack_interval: float = 0.24
var attack_interval: float:
 get: return clampf(_attack_interval+temporary_sum("attack_interval"),0.08,3.0)
 set(value): _attack_interval=value-temporary_sum("attack_interval")
var attack_range: float = 540.0
var projectile_speed: float = 410.0
var _defense: float = 0.0
var defense: float:
 get: return clampf(_defense+temporary_sum("defense"),-2.0,20.0)
 set(value): _defense=value-temporary_sum("defense")
var luck: float = 0.0
var effect_chance: float = 0.0

func apply_damage(amount: float) -> float:
 var dealt := maxf(0.25, amount - defense)
 health = maxf(0.0, health - dealt)
 return dealt

func modify(values: Dictionary) -> void:
 # Explicit allowlist prevents accidental assignment of methods or invalid fields.
 for key in values:
  if key in ["max_health", "damage", "speed", "attack_interval", "attack_range", "projectile_speed", "defense", "luck", "effect_chance"]:
   var value = values[key]
   if (value is float or value is int) and is_finite(float(value)):
    set(key, float(get(key)) + float(value))
 max_health = clampf(max_health, 1.0, 100.0)
 health = clampf(health, 0.0, max_health)
 speed = clampf(speed, 40.0, 400.0)
 attack_interval = clampf(attack_interval, 0.08, 3.0)
 attack_range = clampf(attack_range, 40.0, 1400.0)
 projectile_speed = clampf(projectile_speed, 50.0, 900.0)
 effect_chance = clampf(effect_chance, 0.0, 1.0)

# Source-scoped temporary effects never mutate permanent item upgrades.
var temporary: Dictionary = {}
func temporary_sum(field: String) -> float:
 var total:=0.0
 for values: Dictionary in temporary.values(): total+=float(values.get(field,0.0))
 return total
func set_temporary(source: String, values: Dictionary) -> void:
 temporary[source]=values.duplicate()
func clear_temporary(source: String) -> void:
 temporary.erase(source)
