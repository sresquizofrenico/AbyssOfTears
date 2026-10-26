class_name RelicPickup
extends Node2D
signal unlock_requested(pickup: RelicPickup)
signal claimed(pickup: RelicPickup)
const KEY = preload("res://assets/relics/key.svg")
const COINS = preload("res://assets/relics/coins.svg")
const HEAL = preload("res://assets/relics/heal.svg")
const PEDESTAL = preload("res://assets/relics/pedestal.svg")
const CHEST = preload("res://assets/relics/chest.svg")
var data: Dictionary
var player: AbyssPlayer
var clock := 0.0
var taking := false
var take_age := 0.0
var cooldown := 0.5
var quality := 1

func _physics_process(delta: float) -> void:
 clock += delta
 cooldown -= delta
 if taking:
  take_age += delta
  if take_age > 0.3: queue_free()
 elif cooldown <= 0 and int(data.get("price",0))<=0 and is_instance_valid(player) and player.active and player.position.distance_to(position) < 30:
  if data.get("chest",false):
   if data.get("locked",false):
    unlock_requested.emit(self)
    if data.get("locked",false):
     cooldown=0.8
     return
   data.chest = false
   cooldown = 0.35
  elif data.get("reward_kind","") != "heal" or player.stats.health<player.stats.max_health: claim()
 queue_redraw()

func claim() -> bool:
 if taking or data.get("collected",false) or int(data.get("price",0))>0 or data.get("locked",false) or data.get("chest",false): return false
 data.collected = true
 taking = true
 claimed.emit(self)
 return true

func _draw() -> void:
 if data.is_empty(): return
 if data.get("chest",false):
  draw_texture_rect(CHEST,Rect2(-25,-30,50,50),false)
  if data.get("locked",false): draw_texture_rect(KEY,Rect2(-9,-12,18,18),false)
  return
 draw_texture_rect(PEDESTAL,Rect2(-24,-3,48,38),false)
 var bob := sin(clock*3)*3
 var alpha := 1.0 - take_age / 0.3 if taking else minf(1,clock*3)
 if quality > 0:
  draw_circle(Vector2(0,-19+bob),26,Color(0.5,0.8,0.9,0.07*alpha))
 var icon: Texture2D = KEY if data.get("reward_kind","")=="key" else COINS if data.get("reward_kind","")=="coins" else HEAL if data.get("reward_kind","")=="heal" else RelicCatalog.icon(data.id)
 if int(data.get("price",0))>0: draw_string(ThemeDB.fallback_font,Vector2(-14,31),"%d ób." % int(data.price),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f3d2a0"))
 draw_texture_rect(icon,Rect2(-19,-45+bob-take_age*75,38,38),false,Color(1,1,1,alpha))
 if quality>0 and data.get("reward_kind","relic")=="relic" and int(RelicCatalog.definition(data.id).rarity)==4:
  draw_arc(Vector2(0,-22+bob),26,clock*2,clock*2+PI,18,Color(0.9,0.75,1,alpha*0.7),1.5)
