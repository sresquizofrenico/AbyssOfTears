extends SceneTree
var checks:=0
var failures:=0
func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
 root.size=Vector2i(960,540)
 var textures: Array[Texture2D]=[IllustratedNeris.BODY,IllustratedNeris.ARM,IllustratedNeris.BOOT,IllustratedNeris.LANTERN,IllustratedNeris.SHADOW,RelicPickup.GLOW,RelicPickup.CHEST,RelicPickup.PEDESTAL,AbyssProjectile.TEAR,EnemyArt.TEXTURES[0],RelicCatalog.icon("crystal")]
 for texture in textures:
  check(texture!=null and texture.get_width()>0 and texture.get_width()<=1024 and texture.get_height()<=1024,"Illustration imports with bounded texture dimensions")
 check(IllustratedNeris.BODY.get_size()==Vector2(384,512),"Shared character art supports enlarged selection without pixel-art scaling")
 check(EnemyArt.TEXTURES.size()==20 and EnemyCatalog.DATA.size()==20,"All enemy content retained")
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.show_character_selection()
 var selection: CharacterSelection=game.panel
 await process_frame
 check(selection.character.body_texture==IllustratedNeris.BODY,"Selection shares the exact illustrated Neris texture")
 check(game.backdrop.character.BODY==IllustratedNeris.BODY,"Animated main menu shares Neris art")
 game.start_art_sample()
 game.update_pickup_interaction()
 await process_frame
 check(game.pickup_interaction.position.y>game.player.position.y+28,"Free reward tooltip does not cover protagonist in sample")
 check(game.state=="playing" and game.enemies.size()==1 and game.enemies[0].kind==0,"Functional art sample contains the real pursuer enemy")
 check(game.player.stats.health==6 and game.player.stats.damage==1 and game.player.stats.speed==185,"Art does not change player stats")
 var enemy: AbyssEnemy=game.enemies[0]
 enemy._physics_process(0.1)
 check(enemy.events.has("pursue") and enemy.velocity.length()>0,"Redesigned enemy retains real pursuit AI")
 enemy.take_damage(0.5)
 check(enemy.flash>0 and enemy.health<enemy.max_health,"Damage reaction retains actual damage")
 var crystal: RelicPickup=game.pickups[0]
 game.player.position=crystal.position
 crystal.cooldown=0
 crystal._physics_process(0.016)
 check(crystal.data.collected and game.player.relics.has("crystal") and game.player.stats.damage>1,"Illustrated crystal remains collectible with real effect")
 var chest: RelicPickup=game.pickups[1]
 game.player.position=chest.position+Vector2(65,0)
 chest.cooldown=0
 check(game.interact_with_pickup(chest),"Illustrated chest uses existing tactile interaction")
 game.player.position=chest.position
 chest.cooldown=0
 chest._physics_process(0.016)
 check(chest.data.collected and game.player.relics.has("shield"),"Illustrated chest delivers its real reward")
 check(game.player.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS,"Art uses smooth downsampling")
 # Pose changes only affect drawing and clocks; no stats, money or save mutations.
 game.backdrop.show()
 game.backdrop.set_process(false)
 var snapshot: Array=[game.player.stats.health,game.player.stats.damage,game.player.stats.speed,game.coins]
 for pose in ["rest","walk","attack","light","pickup","victory","defeat","present"]:
  var actor: MenuCharacter=game.backdrop.character
  actor.animate(0.1,actor.position,pose,Vector2.RIGHT)
  await process_frame
  check(actor.pose==pose and [game.player.stats.health,game.player.stats.damage,game.player.stats.speed,game.coins]==snapshot,"Visual pose does not mutate run: "+pose)
 for floor_index in range(3):
  game.start_dungeon(12345)
  game.layout.generate(12345,floor_index,true)
  game.start_game()
  check(game.chamber.biome==floor_index,"Existing floor selects corresponding illustrated room")
  check(game.chamber.FLOORS[floor_index].get_size()==Vector2(1024,512),"Floor art is one bounded shared texture")
  var collision_before: Array=[game.chamber.blocks(Vector2(320,200)),game.chamber.blocks(Vector2(480,274))]
  for quality in range(3):
   game.chamber.quality=quality
   game.chamber.queue_redraw()
   check([game.chamber.blocks(Vector2(320,200)),game.chamber.blocks(Vector2(480,274))]==collision_before,"Graphics profiles retain identical collision geometry")
 game.start_game()
 game.player.stats.health=1
 game.player.immunity=0
 game.player.take_damage(999)
 check(game.state=="defeat","Illustrated player retains defeat transition")
 game.show_main_menu()
 check(game.panel.buttons.size()==3,"Simplified animated main menu retained")
 game.queue_free()
 await process_frame
 print("ILLUSTRATED ART RESULT: %d checks, %d failures" % [checks,failures])
 await AudioTestCleanup.drain(self)
 quit(1 if failures else 0)
