extends SceneTree
var checks:=0
var failures:=0
var game
func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
 for i in range(count): await physics_frame
func touch(index: int, point: Vector2, pressed: bool) -> void:
 var event:=InputEventScreenTouch.new()
 event.index=index
 event.position=point
 event.pressed=pressed
 root.push_input(event,true)
func click(button: Button) -> void:
 # A separate real touch finger must work even while finger 0 holds the joystick.
 var point:=button.get_global_rect().get_center()
 touch(3,point,true)
 touch(3,point,false)
func pickup(id: String, position: Vector2, extra: Dictionary={}) -> RelicPickup:
 var data: Dictionary={"id":id,"position":position,"collected":false,"chest":false}
 data.merge(extra,true)
 return game.spawn_pickup(data)
func shop() -> void:
 game.start_dungeon(12345)
 game.layout.current=8
 game.start_game()
 game.player.position=Vector2(480,400)
func run() -> void:
 root.size=Vector2i(960,540)
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 # Actual movement via a touch finger; no direct call to claim or collect.
 game.start_dungeon(12345)
 var item:=pickup("boots",Vector2(480,300))
 game.player.position=item.position+Vector2(0,110)
 item.cooldown=0
 var joystick: Vector2=game.controls.joystick_center()
 touch(0,joystick+Vector2(0,-55),true)
 var fire: Vector2=game.controls.attack_positions()[1]
 touch(1,fire,true)
 await frames(30)
 touch(0,joystick,false)
 touch(1,fire,false)
 check(item.data.collected and game.player.relics.has("boots"),"Touch movement automatically collects a normal physical relic")
 check(game.player.stats.speed==205,"Picked-up relic modifies real stats")
 check(game.bullets.size()>0,"Movement, firing and pickup coexist")
 check(not item.claim(),"Repeated claim cannot duplicate a free relic")
 # Full-health consumable remains available; a failed delivery never consumes it.
 var tonic:=pickup("crystal",Vector2(480,300),{"reward_kind":"heal"})
 check(not tonic.claim() and not tonic.data.collected,"Full-health tonic is not consumed")
 game.player.stats.health=3
 game.player.position=tonic.position
 tonic.cooldown=0
 tonic._physics_process(0.016)
 check(tonic.taking and game.player.stats.health==5,"Waiting tonic heals after damage")
 var invalid:=pickup("not_a_real_item",Vector2(480,300))
 var cash: int=game.coins
 check(not invalid.claim() and not invalid.data.collected and game.coins==cash,"Invalid reward rejected without errors or phantom compensation")
 invalid.queue_redraw()
 await process_frame
 # Shop product is visible and purchasable directly in the room.
 shop()
 var product: RelicPickup=game.pickups[0]
 var price:=int(product.data.price)
 var id: String=product.data.id
 game.player.position=product.position+Vector2(0,65)
 game.update_pickup_interaction()
 await process_frame
 check(game.pickup_interaction.visible and game.pickup_interaction.target==product,"Approaching shop product reveals local interaction")
 check(game.pickup_interaction.action.text=="COMPRAR" and game.pickup_interaction.text.text.contains(str(price)) and game.pickup_interaction.text.text.contains(product.display_name()),"Shop shows actual name, description, price and buy button")
 game.coins=price-1
 click(game.pickup_interaction.action)
 check(game.coins==price-1 and not product.data.collected and int(product.data.price)==price,"Insufficient purchase neither charges nor consumes product")
 check(game.toast_label.text=="MONEDAS INSUFICIENTES","Insufficient purchase provides required message")
 game.coins=price+10
 touch(0,game.controls.joystick_center()+Vector2(0,-20),true)
 check(game.controls.joystick_finger==0,"Joystick is held before independent purchase tap")
 click(game.pickup_interaction.action)
 check(game.controls.joystick_finger==0,"Purchase touch does not release movement finger")
 touch(0,game.controls.joystick_center(),false)
 check(game.coins==10 and product.data.collected and product.taking and game.player.relics.has(id),"GUI purchase immediately delivers item and deducts exact cost")
 check(not game.purchase_pickup(product) and game.coins==10,"Repeated purchase cannot charge twice")
 check(not game.pickup_interaction.visible,"Sold product leaves interaction UI")
 check(game.state=="playing" and game.controls.enabled,"Shop purchase does not require modal doors or disable controls")
 var sold_data: Dictionary=product.data
 game.start_game(true)
 check(sold_data.collected and not game.pickups.any(func(p): return is_same(p.data,sold_data)),"Sold product does not respawn on room reload")
 # Cheap and expensive products use the same transaction; rare price is not hardcoded.
 shop()
 game.coins=100
 var key: RelicPickup=game.pickups[2]
 var key_price:=int(key.data.price)
 game.player.position=key.position+Vector2(0,60)
 game.update_pickup_interaction()
 await process_frame
 click(game.pickup_interaction.action)
 check(game.keys==1 and game.coins==100-key_price and key.data.collected,"Cheap key is delivered on touch-compatible button confirmation")
 var expensive: RelicPickup=game.pickups[1]
 expensive.data.price=60
 cash=game.coins
 game.player.position=expensive.position+Vector2(0,65)
 check(game.interact_with_pickup(expensive) and game.coins==cash-60 and game.player.relics.has(expensive.data.id),"Expensive item delivers at exact configured price")
 check(not game.interact_with_pickup(expensive),"Sold expensive item cannot be delivered again")
 # Reject a product capped in inventory, preserving both stock and money.
 shop()
 product=game.pickups[0]
 var definition:=RelicCatalog.definition(product.data.id)
 for i in range(int(definition.max_stack)): game.player.relics.add(product.data.id,game.player.stats)
 game.coins=100
 check(not game.purchase_pickup(product) and game.coins==100 and not product.data.collected,"Capped shop relic does not charge or consume stock")
 # If delivery fails after validation, transaction rolls back price and paid state.
 var full_key: RelicPickup=game.pickups[2]
 game.keys=99
 check(not game.purchase_pickup(full_key) and game.coins==100 and int(full_key.data.price)==4 and not full_key.data.get("paid",false),"Rejected key delivery rolls back purchase")
 # A claim callback cannot spend the same balance on a second product.
 shop()
 var first: RelicPickup=game.pickups[0]
 var other: RelicPickup=game.pickups[1]
 game.coins=int(first.data.price)
 var reentrant: Array[bool]=[]
 first.claimed.connect(func(_pickup): reentrant.append(game.purchase_pickup(other)))
 check(game.purchase_pickup(first) and game.coins==0 and reentrant==[false] and not other.data.collected,"Reserved wallet balance prevents reentrant overspending")
 # Modal shop remains usable for players who use the existing door navigation.
 shop()
 game.coins=20
 game.show_doors()
 game.show_shop()
 check(game.buy_offer(2) and game.keys==1 and game.coins==16 and game.room_pickups[2].collected,"Legacy shop menu now delivers purchase immediately")
 game.resume_game()
 # Explicit chest interaction, including lock and release animation.
 game.start_dungeon(12345)
 var chest:=pickup("crystal",Vector2(480,274),{"chest":true,"locked":true})
 game.player.position=chest.position+Vector2(70,0)
 chest.cooldown=0
 game.keys=0
 game.update_pickup_interaction()
 await process_frame
 check(game.pickup_interaction.action.text.contains("ABRIR COFRE"),"Nearby chest exposes a large opening button")
 click(game.pickup_interaction.action)
 check(chest.data.chest and not chest.data.collected,"Locked chest stays closed without a key")
 game.keys=1
 chest.cooldown=0
 game.update_pickup_interaction()
 click(game.pickup_interaction.action)
 check(not chest.data.chest and chest.data.opened and not chest.data.locked and game.keys==0,"Button opens chest and consumes one key")
 check(not chest.open_chest() and game.keys==0,"Repeated opening cannot consume another key")
 game.player.position=chest.position
 await frames(26)
 check(chest.data.collected and game.player.relics.has("crystal"),"Opened chest reward is collected by proximity after its animation")
 check(not chest.claim(),"Chest cannot deliver twice")
 # Treasure and post-boss rewards are real dynamic pickups, not direct stats.
 game.start_dungeon(54321)
 var treasure:=0
 for i in range(game.layout.rooms.size()):
  if game.layout.rooms[i].kind=="treasure": treasure=i
 game.layout.current=treasure
 game.start_game()
 var reward: RelicPickup=game.pickups[0]
 game.player.position=reward.position
 reward.cooldown=0
 reward._physics_process(0.016)
 check(reward.data.collected and game.player.relics.has(reward.data.id),"Treasure-room physical item can be collected")
 game.layout.current=game.layout.boss_room
 game.start_game(true)
 var boss: TideWarden=game.enemies[0]
 boss.take_damage(999)
 await frames(3)
 check(game.pickups.size()>0,"Defeated boss spawns a real reward")
 reward=game.pickups.back()
 game.player.position=reward.position
 reward.cooldown=0
 reward._physics_process(0.016)
 check(reward.data.collected and game.player.relics.has(reward.data.id),"Post-boss reward applies through ordinary pickup path")
 # Placement checks cover pillars, barrels, temporary obstacles and existing pedestals.
 game.start_dungeon(12345)
 var doorway: Vector2=game.door_point(game.layout.rooms[0].links[0])
 var near_door:=pickup("shield",doorway)
 check(near_door.position.distance_to(doorway)>=65,"Reward avoids an automatic door-transition zone")
 var pillar_pickup:=pickup("fire",Vector2(320,200))
 check(not game.chamber.blocks(pillar_pickup.position,32),"Reward placed outside pillars and walls")
 var barrel:=RoomProp.new()
 barrel.data={"kind":"barrel","position":Vector2(480,274),"used":false}
 barrel.position=Vector2(480,274)
 barrel.player=game.player
 game.world.add_child(barrel)
 game.props.append(barrel)
 var blocked:=pickup("ice",barrel.position)
 check(blocked.position.distance_to(barrel.position)>=50,"Reward avoids solid barrel")
 var second:=pickup("electric",blocked.position)
 check(second.position.distance_to(blocked.position)>=56,"Two rewards never share one pedestal")
 game.player.position=Vector2(700,400)
 game.spawn_hazard(Vector2(480,150),"wall")
 var wall: EnemyHazard=game.hazards.back()
 var after_wall:=pickup("double",wall.position)
 check(after_wall.position.distance_to(wall.position)>=58,"New reward avoids an existing temporary wall")
 var hazards_before: int=game.hazards.size()
 game.spawn_hazard(second.position,"wall")
 check(game.hazards.size()==hazards_before+1,"Weaver still creates its distinct wall attack")
 check(game.hazards.back().position.distance_to(second.position)>=65,"New wall relocates away from existing reward")
 # Wide displays use global positions; room offset must not break pickup range.
 root.size=Vector2i(1280,540)
 await process_frame
 game.start_game()
 var wide:=pickup("pierce",Vector2(480,300))
 game.player.position=wide.position
 wide.cooldown=0
 wide._physics_process(0.016)
 check(wide.data.collected and game.player.relics.has("pierce"),"Pickup works with centered room on a wider display")
 for dimensions in [Vector2i(960,540),Vector2i(1280,540),Vector2i(960,600)]:
  root.size=dimensions
  await process_frame
  var nearby:=pickup("bounce",Vector2(480,274),{"chest":true})
  game.player.position=nearby.position+Vector2(0,65)
  game.update_pickup_interaction()
  await process_frame
  var rect: Rect2=game.pickup_interaction.get_global_rect()
  check(rect.position.x>=220 and rect.end.x<=dimensions.x-220 and rect.end.y<=dimensions.y,"Interaction panel stays onscreen between touch controls")
  check(game.pickup_interaction.action.size.y>=48,"Interaction button remains large enough for touch")
  game.pause_game()
  check(not game.pickup_interaction.visible and not game.interact_with_pickup(nearby),"Pause hides and blocks contextual interaction")
  game.resume_game()
 check(CharacterCatalog.DATA.size()==11 and CharacterCatalog.playable("neris"),"Eleven-character catalog preserves the original playable ID")
 game.queue_free()
 await process_frame
 print("PICKUP INTERACTION RESULT: %d checks, %d failures" % [checks,failures])
 await AudioTestCleanup.drain(self)
 quit(1 if failures else 0)
