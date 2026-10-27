extends SceneTree
const Simulator = preload("res://tools/economy_simulation.gd")
var checks:=0
var failures:=0
func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var original:=Economy.config().duplicate(true)
 var progress:=CharacterCatalog.progress_node()
 var previous_ending: int=progress.amount("endings")
 progress.data.counters.endings=1
 check(Economy.validate_config(original).is_empty(),"Shipped JSON balance is valid")
 var bad:=original.duplicate(true)
 bad.enemy_drop_chance.normal=-1
 check(not Economy.validate_config(bad).is_empty(),"Negative drop rate rejected")
 bad=original.duplicate(true)
 bad.rarity.base[0]=[0,0,0,0,0,0]
 check(not Economy.validate_config(bad).is_empty(),"Empty rarity distribution rejected")
 bad=original.duplicate(true)
 bad.prices[0][0]=[9,6]
 check(not Economy.validate_config(bad).is_empty(),"Reversed price range rejected")
 bad=original.duplicate(true)
 bad.boss_coins[0]=NAN
 check(not Economy.validate_config(bad).is_empty(),"Non-finite boss reward rejected")
 var all_owned: Dictionary={}
 for definition: Dictionary in RelicCatalog.DATA: all_owned[definition.id]=int(definition.max_stack)
 var stock_layout:=FloorLayout.new()
 stock_layout.generate(12345,0,true)
 stock_layout.current=8
 RoomContent.prepare(stock_layout,all_owned)
 check(stock_layout.rooms[8].pickups.size()==1 and stock_layout.rooms[8].pickups[0].reward_kind=="key","New shop stock excludes relics already at their stack limit")
 var bundle:=Economy.split_coins(20)
 check(not bundle.has(10) and bundle.reduce(func(a,b): return a+b,0)==20,"Boss budgets do not guarantee ultra-rare dark denomination")
 var rng:=RandomNumberGenerator.new()
 rng.seed=10017
 var normal:=0
 var tank:=0
 var elite:=0
 var dark:=0
 for i in range(50000):
  if Economy.enemy_coin(rng,0)>0: normal+=1
  if Economy.enemy_coin(rng,6)>0: tank+=1
  if Economy.enemy_coin(rng,0,false,true)>0: elite+=1
  if Economy.coin_value(rng)==10: dark+=1
 check(absf(normal/50000.0-0.03)<0.004,"Empirical normal enemy chance is 3 percent")
 check(absf(tank/50000.0-0.05)<0.005,"Empirical resistant enemy chance is 5 percent")
 check(absf(elite/50000.0-0.15)<0.007,"Prepared elite drop API uses configured 15 percent")
 check(dark>0 and dark<100,"Dark obols are exceptionally rare")
 for floor_index in range(6):
  var counts: Array[int]=[0,0,0,0,0,0]
  for i in range(10000): counts[int(RelicCatalog.definition(RelicCatalog.roll(rng,floor_index)).rarity)]+=1
  var expected: Array=original.rarity.base[floor_index]
  for rarity in range(6):
   check(absf(counts[rarity]/10000.0-float(expected[rarity])/100.0)<0.025,"Base rarity frequencies match configured floor table")
   if float(expected[rarity])==0: check(counts[rarity]==0,"Zero-weight rarity never appears")
 for floor_index in range(5):
  for rarity in range(6):
   var limits: Array=original.prices[floor_index][rarity]
   for i in range(15):
    var price:=Economy.price_for(rarity,floor_index,rng)
    check(price>=int(limits[0]) and price<=int(limits[1]),"Shop price respects actual floor and rarity range")
 check(Economy.price_for(4,100,rng)<=160,"Future floor price escalation is bounded")
 for context in ["treasure","shop","chest","secret","boss"]:
  for floor_index in range(3):
   var counts: Array[int]=[0,0,0,0,0,0]
   for i in range(1000): counts[int(RelicCatalog.definition(RelicCatalog.roll(rng,floor_index,context)).rarity)]+=1
   check(counts.reduce(func(a,b): return a+b,0)==1000,"Independent context table produces valid functional relic IDs")
 # Changing the real cached data changes production functions, not a parallel test model.
 Economy.loaded.enemy_drop_chance.normal=0.0
 check(Economy.enemy_coin(rng,0)==0,"Zero configured enemy chance disables drop")
 Economy.loaded.enemy_drop_chance.normal=1.0
 check(Economy.enemy_coin(rng,0)>0 and Economy.enemy_coin(rng,0,true)==0,"Guaranteed gate still excludes summoned creatures")
 Economy.loaded.rarity.base[0]=[0,0,100,0,0,0]
 check(int(RelicCatalog.definition(RelicCatalog.roll(rng,0)).rarity)==2,"Edited rarity table influences actual catalog roll")
 Economy.loaded.prices[0][0]=[31,31]
 check(Economy.price_for(0,0,rng)==31,"Changing shop price data changes actual price function")
 Economy.loaded=original.duplicate(true)
 root.size=Vector2i(960,540)
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_dungeon(12345)
 game.layout.current=1
 game.layout.rooms[1].kind="combat"
 game.start_game()
 Economy.loaded.enemy_drop_chance.normal=1.0
 var enemy: AbyssEnemy=game.enemies[0]
 enemy.kind=0
 var before: int=game.pickups.size()
 var money: int=game.coins
 game.on_enemy_defeated(enemy,enemy.position,999)
 check(game.enemies.has(enemy) and game.pickups.size()==before and game.coins==money,"Alive enemy cannot be paid through a premature defeat callback")
 enemy.take_damage(999)
 check(game.coins==money and game.pickups.size()==before+1,"Enemy death drops a real coin instead of automatic balance increment")
 var coin: RelicPickup=game.pickups.back()
 var amount:=Economy.amount(coin.data)
 game.on_enemy_defeated(enemy,enemy.position,999)
 check(game.pickups.size()==before+1 and game.coins==money,"Repeated death callback cannot duplicate currency")
 check(coin.claim() and game.coins==money+amount and game.hud.coins_label.text==str(game.coins),"Physical coin collection credits exact value and updates HUD")
 check(not coin.claim() and game.coins==money+amount,"Coin cannot be collected twice")
 var minion: AbyssEnemy
 game.spawn_enemy(0,Vector2(480,140),true)
 minion=game.enemies.back()
 before=game.pickups.size()
 minion.take_damage(999)
 check(game.pickups.size()==before,"Summoned enemy cannot farm coins even at 100 percent chance")
 for value: int in [1,3,5,10]:
  var data:=Economy.coin_data(value,Vector2(480,300))
  var pickup: RelicPickup=game.spawn_pickup(data)
  money=game.coins
  check(pickup.icon()!=null and pickup.claim() and game.coins==money+value,"Each denomination has a real icon and exact amount")
 var invalid: RelicPickup=game.spawn_pickup(Economy.coin_data(-10,Vector2(480,300)))
 money=game.coins
 check(not invalid.claim() and game.coins==money,"Negative currency payload is rejected")
 # Empty and coin-bearing barrels both have one-shot processing.
 for prop: RoomProp in game.props:
  if prop.data.kind!="barrel": continue
  prop.data.drop_type=1
  prop.data.coin_amount=1
  before=game.pickups.size()
  prop.take_damage(999)
  game.activate_prop(prop)
  check(game.pickups.size()==before+1,"Barrel reward cannot be delivered twice")
 game.start_dungeon(12345)
 game.layout.current=1
 game.layout.rooms[1].kind="combat"
 game.start_game()
 for prop: RoomProp in game.props:
  if prop.data.kind!="barrel": continue
  prop.data.drop_type=0
  before=game.pickups.size()
  money=game.coins
  prop.take_damage(999)
  game.activate_prop(prop)
  check(game.pickups.size()==before and game.coins==money,"Empty barrel and repeated activation never mint currency")
 game.layout.current=8
 game.start_game(true)
 var product: RelicPickup=game.pickups[0]
 game.player.position=product.position+Vector2(0,65)
 game.update_pickup_interaction()
 check(game.pickup_interaction.text.text.contains(product.rarity_label()),"Nearby shop information includes real rarity")
 game.coins=0
 check(not game.purchase_pickup(product) and game.coins==0 and not product.data.collected,"Shop refuses insufficient funds without negative balance")
 game.coins=100
 var price:=int(product.data.price)
 check(game.purchase_pickup(product) and game.coins==100-price and game.player.relics.has(product.data.id),"Newly priced product delivers and charges once")
 check(not game.purchase_pickup(product) and game.coins==100-price,"Repeated purchase cannot charge again")
 var stock: Dictionary=product.data
 game.start_game(true)
 check(stock.collected and not game.pickups.any(func(p): return is_same(p.data,stock)),"Paid shop stock remains sold after room reload")
 game.layout.current=1
 game.layout.rooms[1].cleared=true
 game.layout.rooms[1].rewarded=false
 game.start_game(true)
 var data_count: int=game.room_pickups.size()
 game.reward_room()
 game.reward_room()
 check(game.room_pickups.size()==data_count,"Room rewards cannot be farmed by repeated clear callback")
 var chest: RelicPickup=game.spawn_pickup({"id":"crystal","position":Vector2(480,274),"chest":true,"collected":false})
 check(chest.chest_state()==RelicPickup.ChestState.CLOSED,"Chest begins closed")
 game.player.position=chest.position+Vector2(65,0)
 chest.cooldown=0
 check(chest.chest_state()==RelicPickup.ChestState.AVAILABLE and chest.open_chest(),"Chest becomes available and opens through real range check")
 check(chest.chest_state()==RelicPickup.ChestState.OPENING and not chest.claim(),"Opening state blocks premature reward claim")
 chest._physics_process(0.36)
 check(chest.chest_state()==RelicPickup.ChestState.OPEN,"Opening finishes without giving repeated reward")
 check(chest.claim() and chest.chest_state()==RelicPickup.ChestState.DELIVERED and not chest.open_chest(),"Delivered chest cannot reopen")
 Economy.loaded=original.duplicate(true)
 game.queue_free()
 await process_frame
 var simulation:=Simulator.run(1000)
 check(float(simulation[0].gross)>6 and float(simulation[0].gross)<20,"Simulated first-floor income remains useful but limited")
 check(float(simulation[0].gross)+float(simulation[1].gross)<50,"Simulated income by floor two is far below former 163-obol example")
 check(float(simulation[0].both_affordable)<0.65,"First-floor budget does not routinely buy both relics")
 check(float(simulation[0].purchases)>0.4 and float(simulation[0].purchases)<1.8,"Simulation permits occasional purchases without trivial full stock")
 print("ECONOMY SIMULATION TEST ",JSON.stringify(simulation))
 progress.data.counters.endings=previous_ending
 print("ECONOMY RESULT: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
