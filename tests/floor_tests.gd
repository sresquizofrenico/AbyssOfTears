extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("TEST FAILED: " + message)
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 for seed_id in range(200):
  for floor_id in range(3):
   var map := FloorLayout.new()
   map.generate(seed_id,floor_id)
   check(map.rooms.size()==8 and map.distances_from_start().size()==8,"Eight accessible rooms")
   var treasure := 0
   var exit_count := 0
   for i in range(map.rooms.size()):
    var room: Dictionary = map.rooms[i]
    if room.kind == "treasure": treasure+=1
    if room.kind == "descent": exit_count+=1
    for neighbor: int in room.links:
     check(map.rooms[neighbor].links.has(i),"Bidirectional doors")
   check(treasure==1 and exit_count==1,"Treasure and descent exist")
   var same := FloorLayout.new()
   same.generate(seed_id,floor_id)
   check(same.rooms==map.rooms,"Reproducible generation")
 var game = load("res://scenes/main.tscn").instantiate()
 root.size=Vector2i(960,540)
 root.add_child(game)
 await process_frame
 game.start_dungeon()
 check(game.layout.floor_index==0 and game.enemies.is_empty(),"Start room safe")
 var map: FloorLayout = game.layout
 var neighbor: int = map.rooms[0].links[0]
 game.player.stats.health=4
 game.coins=12
 game.travel_to(neighbor)
 check(game.layout.current==neighbor and game.player.stats.health==4 and game.coins>=12,"Travel preserves health and currency")
 if not map.rooms[neighbor].cleared:
  check(not map.can_enter(0),"Combat locks doors")
  for enemy in game.enemies: enemy.queue_free()
  game.enemies.clear()
  game.clear_wave()
  check(map.rooms[neighbor].cleared,"Clear unlocks doors")
 var coins: int=game.coins
 game.reward_room()
 game.reward_room()
 check(game.coins==coins,"Rewards cannot be farmed")
 game.travel_to(0)
 check(game.enemies.is_empty(),"Cleared rooms do not respawn")
 # Exercise descent guards and run completion without bypassing production room logic.
 for floor_id in range(3):
  check(game.layout.floor_index==floor_id,"Floor order")
  var exit_id := 0
  for i in range(8):
   if game.layout.rooms[i].kind=="descent": exit_id=i
  game.layout.current=exit_id
  game.layout.rooms[exit_id].cleared=false
  game.start_game(true)
  check(game.enemies.size()==4+floor_id,"Exit encounters grow by floor")
  for enemy in game.enemies: enemy.queue_free()
  game.enemies.clear()
  game.clear_wave()
  game.show_doors()
  check(game.state=="doors","Touch navigation available")
  game.descend()
 check(game.state=="victory","Third descent completes run")
 game.restart_game()
 check(game.state=="playing" and game.layout.floor_index==0 and game.coins==0,"Restart resets whole dungeon")
 game.pause_game()
 check(game.state=="paused","Dungeon still pauses")
 game.show_main_menu()
 check(not game.dungeon_mode and not game.dungeon_map.visible,"Menu disposes dungeon UI")
 game.queue_free()
 await process_frame
 print("FLOOR RESULT: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
