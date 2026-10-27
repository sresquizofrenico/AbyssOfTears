class_name RelicPickup
extends Node2D

signal unlock_requested(pickup: RelicPickup)
signal claimed(pickup: RelicPickup)
signal opened
const GLOW = preload("res://assets/illustrated/glow.svg")
const KEY = preload("res://assets/relics/key.svg")
const COINS = preload("res://assets/relics/coins.svg")
const HEAL = preload("res://assets/relics/heal.svg")
const PEDESTAL = preload("res://assets/illustrated/pedestal.svg")
const CHEST = preload("res://assets/illustrated/chest.svg")
const COIN_ICONS = {1:preload("res://assets/currency/coin_1.svg"),3:preload("res://assets/currency/coin_3.svg"),5:preload("res://assets/currency/coin_5.svg"),10:preload("res://assets/currency/coin_10.svg")}
enum ChestState { CLOSED, AVAILABLE, OPENING, OPEN, DELIVERED }
const PICKUP_RADIUS := 44.0
const INTERACTION_RADIUS := 92.0
var data: Dictionary = {}
var player: AbyssPlayer
# Returns true only after the current run has accepted and applied the reward.
var accept_claim: Callable
var clock := 0.0
var taking := false
var take_age := 0.0
var open_age := 1.0
var cooldown := 0.5
var quality := 1

func valid_reward() -> bool:
 var kind: String = data.get("reward_kind","relic")
 if kind=="coins": return Economy.amount(data)>0
 if kind in ["heal","key"]: return true
 return kind=="relic" and not RelicCatalog.definition(str(data.get("id",""))).is_empty()

func near_player(radius: float) -> bool:
 return is_instance_valid(player) and player.active and player.global_position.distance_to(global_position)<=radius

func _physics_process(delta: float) -> void:
 clock += delta
 open_age += delta
 cooldown -= delta
 if taking:
  take_age += delta
  if take_age > 0.3: queue_free()
 elif not data.get("collected",false) and cooldown<=0 and int(data.get("price",0))<=0 and near_player(PICKUP_RADIUS+(player.relics.effects.value("pickup_radius") if is_instance_valid(player) else 0)):
  if data.get("chest",false): open_chest()
  elif data.get("reward_kind","")!="heal" or player.stats.health<player.stats.max_health: claim()
 queue_redraw()

func open_chest() -> bool:
 if chest_state() not in [ChestState.CLOSED,ChestState.AVAILABLE] or taking or data.get("collected",false) or not data.get("chest",false) or cooldown>0 or not near_player(INTERACTION_RADIUS) or not valid_reward(): return false
 if data.get("locked",false):
  unlock_requested.emit(self)
  if data.get("locked",false):
   cooldown=0.8
   return false
 data.locked=false
 data.chest=false
 data.opened=true
 cooldown=0.35
 open_age=0
 opened.emit()
 queue_redraw()
 return true

func claim() -> bool:
 if taking or data.get("collected",false) or data.get("claiming",false) or int(data.get("price",0))>0 or data.get("locked",false) or data.get("chest",false) or not valid_reward(): return false
 if data.get("opened",false) and cooldown>0 and open_age<0.35: return false
 if not accept_claim.is_valid(): return false
 # Reject reentrant requests; never consume a reward that the run did not deliver.
 data.claiming=true
 var accepted: bool=accept_claim.call(self)
 data.erase("claiming")
 if not accepted: return false
 data.collected=true
 taking=true
 take_age=0
 claimed.emit(self)
 queue_redraw()
 return true

func icon() -> Texture2D:
 match data.get("reward_kind","relic"):
  "key": return KEY
  "coins": return COIN_ICONS.get(Economy.amount(data),COINS)
  "heal": return HEAL
 if not valid_reward(): return null
 return RelicCatalog.icon(data.id)

func display_name() -> String:
 match data.get("reward_kind","relic"):
  "key": return "Llave del faro"
  "coins": return Economy.COIN_NAMES.get(Economy.amount(data),"Óbolo no válido")
  "heal": return "Tónico de sal"
 var definition := RelicCatalog.definition(str(data.get("id","")))
 return str(definition.get("name","Recompensa no válida"))

func description() -> String:
 match data.get("reward_kind","relic"):
  "key": return "Abre una cerradura opcional."
  "coins": return "+%d monedas para gastar en tiendas." % Economy.amount(data)
  "heal": return "Recupera hasta 2 de vida; espera si tienes la vida completa."
 return str(RelicCatalog.definition(str(data.get("id",""))).get("description",""))

func _draw() -> void:
 if data.is_empty(): return
 if data.get("collected",false) and not taking: return
 if data.get("chest",false):
  draw_texture_rect(CHEST,Rect2(-25,-30,50,50),false)
  if data.get("locked",false): draw_texture_rect(KEY,Rect2(-9,-12,18,18),false)
  return
 if open_age<0.35:
  draw_texture_rect(CHEST,Rect2(-25,-30,50,50),false,Color(1,1,1,1-open_age/0.35))
  draw_line(Vector2(-22,-27-open_age*25),Vector2(22,-27-open_age*25),Color("e6c58c"),4)
 elif data.get("reward_kind","")=="coins": draw_texture_rect(IllustratedNeris.SHADOW,Rect2(-18,0,36,15),false)
 else: draw_texture_rect(PEDESTAL,Rect2(-24,-3,48,38),false)
 var bob := sin(clock*3)*3
 var alpha := 1.0-take_age/0.3 if taking else minf(1,clock*3)
 if quality>0: draw_texture_rect(GLOW,Rect2(-31,-50+bob,62,62),false,Color(0.5,0.8,0.9,0.25*alpha))
 var texture := icon()
 if int(data.get("price",0))>0: draw_string(ThemeDB.fallback_font,Vector2(-14,31),"%d ób." % int(data.price),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f3d2a0"))
 if texture!=null: draw_texture_rect(texture,Rect2(-19,-45+bob-take_age*75,38,38),false,Color(1,1,1,alpha))
 if data.get("reward_kind","")=="coins": draw_string(ThemeDB.fallback_font,Vector2(-5,15),str(Economy.amount(data)),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f3d2a0"))
 if quality>0 and valid_reward() and data.get("reward_kind","relic")=="relic" and int(RelicCatalog.definition(data.id).rarity)==4:
  draw_arc(Vector2(0,-22+bob),26,clock*2,clock*2+PI,18,Color(0.9,0.75,1,alpha*0.7),1.5)

func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func chest_state() -> ChestState:
 if data.get("collected",false): return ChestState.DELIVERED
 if data.get("opened",false): return ChestState.OPENING if cooldown>0 and open_age<0.35 else ChestState.OPEN
 if data.get("chest",false) and cooldown<=0 and near_player(INTERACTION_RADIUS): return ChestState.AVAILABLE
 return ChestState.CLOSED

func rarity_label() -> String:
 if data.get("reward_kind","relic")!="relic" or not valid_reward(): return ""
 return RelicCatalog.RARITIES[int(RelicCatalog.definition(data.id).rarity)]

func at_stack_limit() -> bool:
 if data.get("reward_kind","relic")!="relic" or not valid_reward() or not is_instance_valid(player): return false
 return int(player.relics.owned.get(data.id,0))>=int(RelicCatalog.definition(data.id).max_stack)
