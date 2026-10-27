class_name Economy
extends RefCounted

const CONFIG_PATH := "res://data/balance.json"
const COIN_NAMES := {1:"Óbolo pequeño",3:"Óbolo antiguo",5:"Óbolo dorado",10:"Óbolo oscuro"}
static var loaded: Dictionary={}

static func config() -> Dictionary:
 if loaded.is_empty():
  var source: Variant=JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
  var errors:=validate_config(source)
  if not errors.is_empty():
   push_error("Balance configuration invalid: "+"; ".join(errors))
   return {}
  loaded=source
 return loaded

static func weights_valid(values: Variant, count: int) -> bool:
 if not values is Array or values.size()!=count: return false
 var total:=0.0
 for value: Variant in values:
  if not (value is float or value is int) or not is_finite(float(value)) or float(value)<0: return false
  total+=float(value)
 return total>0

static func validate_config(value: Variant) -> Array[String]:
 var errors: Array[String]=[]
 if not value is Dictionary: return ["Root must be a dictionary"]
 if value.get("version")!=2: errors.append("Unsupported version")
 for key: String in ["room_coin_chance","normal_item_chance","normal_chest_chance"]:
  var chance: Variant=value.get(key)
  if not (chance is float or chance is int) or not is_finite(float(chance)) or float(chance)<0 or float(chance)>1: errors.append("Invalid chance "+key)
 if not value.get("enemy_drop_chance") is Dictionary: errors.append("Missing enemy probabilities")
 else:
  for key: String in ["normal","resistant","elite"]:
   var chance: Variant=value.enemy_drop_chance.get(key)
   if not (chance is float or chance is int) or not is_finite(float(chance)) or float(chance)<0 or float(chance)>1: errors.append("Invalid enemy chance "+key)
 if not value.get("coin_values") is Array or value.coin_values.size()!=4: errors.append("Four coin denominations required")
 else:
  for i in range(4):
   var coin: Variant=value.coin_values[i]
   if not (coin is int or coin is float) or float(coin)!=float([1,3,5,10][i]): errors.append("Coin denominations must be 1, 3, 5 and 10")
 for key: String in ["coin_weights","room_coin_weights"]:
  if not weights_valid(value.get(key),4): errors.append("Invalid weights "+key)
 for key: String in ["barrel_weights","chest_contents"]:
  if not weights_valid(value.get(key),3): errors.append("Invalid weights "+key)
 for key: String in ["duplicate_compensation","key_price","price_cap"]:
  var amount: Variant=value.get(key)
  if not (amount is int or amount is float) or not is_finite(float(amount)) or amount<0 or amount>200: errors.append("Invalid amount "+key)
 for key: String in ["key_price","price_cap"]:
  if (value.get(key) is float or value.get(key) is int) and float(value[key])<1: errors.append("Nonpositive shop amount "+key)
 if not value.get("boss_coins") is Array or value.boss_coins.size()!=6: errors.append("Boss reward table requires six rows")
 else:
  for amount: Variant in value.boss_coins:
   if not (amount is int or amount is float) or not is_finite(float(amount)) or amount<0 or amount>20: errors.append("Boss reward outside controlled range")
 if not value.get("prices") is Array or value.prices.size()!=5: errors.append("Prices require five floors")
 else:
  for floor_table: Variant in value.prices:
   if not floor_table is Array or floor_table.size()!=6: errors.append("Price floor requires six rarities"); continue
   for limits: Variant in floor_table:
    if not limits is Array or limits.size()!=2: errors.append("Invalid price range"); continue
    if not (limits[0] is float or limits[0] is int) or not (limits[1] is float or limits[1] is int): errors.append("Non-numeric price"); continue
    if not is_finite(float(limits[0])) or not is_finite(float(limits[1])) or limits[0]<1 or limits[1]<limits[0] or limits[1]>200: errors.append("Invalid price bounds")
 if not value.get("item_value_factors") is Dictionary: errors.append("Missing item value factors")
 else:
  for factor: Variant in value.item_value_factors.values():
   if not (factor is int or factor is float) or not is_finite(float(factor)) or factor<0.5 or factor>1.5: errors.append("Invalid item value factor")
 if not value.get("rarity") is Dictionary: errors.append("Missing rarity tables")
 else:
  for context: String in ["base","treasure","shop","chest","secret","boss"]:
   var table: Variant=value.rarity.get(context)
   if not table is Array or table.size()!=6: errors.append("Six rarity rows required: "+context); continue
   for row: Variant in table:
    if not weights_valid(row,6): errors.append("Invalid rarity weights: "+context); continue
    var sum:=0.0
    for weight: Variant in row: sum+=float(weight)
    if not is_equal_approx(sum,100.0): errors.append("Rarity weights must sum to 100: "+context)
 return errors

static func weighted_index(rng: RandomNumberGenerator, weights: Array) -> int:
 var total:=0.0
 for weight: Variant in weights: total+=float(weight)
 var roll:=rng.randf()*total
 for i in range(weights.size()):
  if float(weights[i])<=0: continue
  roll-=float(weights[i])
  if roll<0: return i
 for i in range(weights.size()-1,-1,-1):
  if float(weights[i])>0: return i
 return -1

static func enemy_chance(kind: int, elite:=false) -> float:
 return float(config().enemy_drop_chance["elite" if elite else "resistant" if kind in [6,18] else "normal"])

static func coin_value(rng: RandomNumberGenerator, room_reward:=false) -> int:
 return int(config().coin_values[weighted_index(rng,config().room_coin_weights if room_reward else config().coin_weights)])

static func enemy_coin(rng: RandomNumberGenerator, kind: int, summoned:=false, elite:=false) -> int:
 if summoned or rng.randf()>=enemy_chance(kind,elite): return 0
 return coin_value(rng)

static func room_coin(rng: RandomNumberGenerator) -> int:
 return coin_value(rng,true) if rng.randf()<float(config().room_coin_chance) else 0

static func boss_coin_total(floor_index: int) -> int:
 return int(config().boss_coins[clampi(floor_index,0,5)])

static func split_coins(total: int) -> Array[int]:
 var result: Array[int]=[]
 for amount: int in [5,3,1]:
  while total>=amount:
   result.append(amount)
   total-=amount
 return result

static func coin_data(amount: int, position: Vector2) -> Dictionary:
 return {"id":"obol_%d" % amount,"position":position,"reward_kind":"coins","amount":amount,"collected":false,"chest":false}

static func amount(data: Dictionary) -> int:
 # Legacy pickups without a denomination retain their former +5 reward.
 var value:=int(data.get("amount",5))
 return value if value in [1,3,5,10] else 0

static func price_for(rarity: int, floor_index: int, rng: RandomNumberGenerator) -> int:
 var limits: Array=config().prices[clampi(floor_index,0,4)][clampi(rarity,0,5)]
 var multiplier:=1.0+minf(0.75,maxi(0,floor_index-4)*0.08)
 return mini(int(config().price_cap),roundi(rng.randi_range(int(limits[0]),int(limits[1]))*multiplier))

static func item_price(id: String, floor_index: int, rng: RandomNumberGenerator) -> int:
 var price:=price_for(int(RelicCatalog.definition(id).rarity),floor_index,rng)
 return clampi(roundi(price*float(config().item_value_factors.get(id,1.0))),1,int(config().price_cap))

static func roll_relic(rng: RandomNumberGenerator, floor_index: int, context: String="base") -> String:
 var tables: Dictionary=config().rarity
 var table: Array=tables.get(context,tables.base)[clampi(floor_index,0,5)]
 var rarity:=weighted_index(rng,table)
 var candidates: Array[String]=[]
 for definition: Dictionary in RelicCatalog.DATA:
  if int(definition.rarity)==rarity and RelicCatalog.available(definition.id): candidates.append(definition.id)
 if candidates.is_empty():
  for definition: Dictionary in RelicCatalog.DATA:
   if int(definition.rarity)==maxi(0,rarity-1) and RelicCatalog.available(definition.id): candidates.append(definition.id)
 return candidates[rng.randi_range(0,candidates.size()-1)]

static func room_rewards(rng: RandomNumberGenerator, floor_index: int, kind: String) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 if kind not in ["combat","descent","treasure","boss"]: return result
 var amount:=room_coin(rng) if kind in ["combat","descent"] else 0
 var coins: Array[int]=[]
 if kind=="boss": coins=split_coins(boss_coin_total(floor_index))
 elif amount>0: coins.append(amount)
 for i in range(coins.size()): result.append(coin_data(coins[i],Vector2(430+i*45,330)))
 if kind not in ["treasure","boss"] and rng.randf()>=float(config().normal_item_chance): return result
 var context: String="boss" if kind=="boss" else "treasure" if kind=="treasure" else "base"
 var data: Dictionary={"id":RelicCatalog.roll(rng,floor_index,context),"position":Vector2(480,274),"chest":kind not in ["treasure","boss"] and rng.randf()<float(config().normal_chest_chance),"collected":false}
 if data.chest:
  var content:=weighted_index(rng,config().chest_contents)
  data.reward_kind=["relic","coins","heal"][content]
  if content==1: data.amount=coin_value(rng)
  elif content==0: data.id=RelicCatalog.roll(rng,floor_index,"chest")
 result.append(data)
 return result

static func context_allows(id: String, floor_index: int, context: String) -> bool:
 var table: Array=config().rarity.get(context,config().rarity.base)[clampi(floor_index,0,5)]
 var entry:=RelicCatalog.definition(id)
 return not entry.is_empty() and RelicCatalog.available(id) and float(table[int(entry.rarity)])>0
