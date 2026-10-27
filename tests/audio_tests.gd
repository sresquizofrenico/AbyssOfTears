extends SceneTree
var checks:=0
var failures:=0
var heard: Array[String]=[]

func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)

func _initialize() -> void: run.call_deferred()

func touch_button(button: Button) -> void:
 for pressed in [true,false]:
  var event:=InputEventScreenTouch.new()
  event.position=button.get_global_rect().get_center()
  event.index=44
  event.pressed=pressed
  root.push_input(event,true)

func sliders(node: Node, output: Dictionary) -> void:
 if node is HSlider: output[str(node.name)]=node
 for child in node.get_children(): sliders(child,output)

func reset_cues(audio) -> void:
 heard.clear()
 audio.last_effect.clear()
 for voice in audio.voices: voice.stop(); voice.stream=null

func run() -> void:
 root.size=Vector2i(960,540)
 var settings=root.get_node("Settings")
 var previous: Dictionary=settings.values.duplicate(true)
 var progress=root.get_node("Progress")
 var progress_before: Dictionary=progress.data.duplicate(true)
 var old_path: String=progress.storage_path
 progress.storage_path="user://audio-tests-progress.json"
 var audio=root.get_node("Soundscape")
 audio.effect_played.connect(func(id: String): heard.append(id))
 check(audio.music.size()==2 and audio.voices.size()==6,"Fixed music and sound voice budgets")
 var tracks:=AbyssAudioCatalog.tracks()
 check(tracks.size()==13,"Thirteen real original compositions")
 var hashes: Dictionary={}
 var total_bytes:=0
 for id: String in tracks:
  var entry: Dictionary=tracks[id]
  check(FileAccess.file_exists(entry.path),"Real score file: "+id)
  check(FileAccess.get_sha256(entry.path)==entry.sha256,"Score matches recorded source checksum: "+id)
  check(not hashes.has(entry.sha256),"Every score has distinct audio bytes: "+id)
  hashes[entry.sha256]=true
  var stream:=load(entry.path) as AudioStreamOggVorbis
  check(stream!=null and stream.get_length()>15,"Ogg score decodes and has musical length: "+id)
  if stream:
   check(absf(stream.get_length()-float(entry.seconds))<0.1,"Decoded duration matches score: "+id)
  total_bytes+=FileAccess.get_file_as_bytes(entry.path).size()
  check(audio.set_context(id),"Every composition enters actual director: "+id)
  check(audio.music[audio.active_slot].stream is AudioStreamOggVorbis and audio.music[audio.active_slot].stream.loop,"Stream loops without restarting scene: "+id)
  audio._process(0.8)
  check(audio.music[1-audio.active_slot].stream==null,"Previous score released after fade: "+id)
 check(total_bytes<4000000,"Compressed score bank under 4 MB without padding")
 for id: String in AbyssAudioCatalog.EFFECTS:
  var stream:=load(AbyssAudioCatalog.EFFECT_DIR+id+".wav") as AudioStreamWAV
  check(stream!=null and stream.get_length()>0.03 and stream.get_length()<0.5,"Short original effect decodes: "+id)
  if stream: check(not stream.data.is_empty() and stream.mix_rate==22050,"Bounded PCM cue: "+id)
 check(not audio.set_context("nonexistent"),"Unknown track rejected safely")
 audio.set_context("salt_combat")
 audio._process(0.8)
 var count: int=audio.transition_count
 var stream_before: AudioStream=audio.music[audio.active_slot].stream
 for i in range(100): audio.set_context("salt_combat",true)
 check(audio.transition_count==count and is_same(stream_before,audio.music[audio.active_slot].stream),"Repeated context and pause never restart music or reload resources")
 audio._process(0.1)
 check(audio.music[audio.active_slot].volume_db<-16,"Pause reduces music level without restarting it")
 audio.set_context("salt_combat",false)
 audio._process(0.1)
 check(audio.music[audio.active_slot].volume_db>-10,"Resume restores mix")
 for i in range(31):
  audio.set_context("garden_combat" if i%2==0 else "crystal_boss")
  audio._process(0.02)
  check(audio.music.size()==2,"Rapid transitions retain at most two decoders")
 audio._process(0.8)
 check(audio.music[1-audio.active_slot].stream==null,"Interrupted fade still cleans old decoder")
 reset_cues(audio)
 check(audio.play_effect("hit") and not audio.play_effect("hit"),"Repeated impact cues are throttled")
 reset_cues(audio)
 for id in AbyssAudioCatalog.EFFECTS: audio.play_effect(id)
 check(heard.size()==6,"Sound overload drops excess cues within six-voice budget")
 check(not audio.play_effect("unknown"),"Unknown effect ignored")
 audio.set_backgrounded(true)
 check(audio.music.all(func(v): return v.stream==null or v.stream_paused),"Android background pauses every loaded stream")
 check(audio.voices.all(func(v): return not v.playing) and not audio.play_effect("relic"),"Background stops effects and blocks new ones")
 var clock_before: float=audio.clock
 audio._process(2)
 check(audio.clock==clock_before,"Background does not advance crossfade")
 audio.set_backgrounded(false)
 check(audio.music.all(func(v): return not v.stream_paused),"Foreground releases stream pause")
 var clean: Dictionary=settings.validate({"version":1,"quality":2,"left_handed":true,"music_volume":NAN,"sfx_volume":INF})
 check(clean.music_volume==0.55 and clean.sfx_volume==0.8 and clean.quality==2 and clean.left_handed,"Old preferences survive missing or corrupt audio fields")
 clean=settings.validate({"version":1,"music_volume":-10,"sfx_volume":40})
 check(clean.music_volume==0 and clean.sfx_volume==1,"Volumes clamp safely")
 settings.values.music_volume=0
 settings.values.sfx_volume=0.6
 audio.apply_settings()
 check(AudioServer.is_bus_mute(AudioServer.get_bus_index(audio.MUSIC_BUS)),"Music can be independently muted")
 check(not AudioServer.is_bus_mute(AudioServer.get_bus_index(audio.EFFECT_BUS)),"Music mute preserves effects")
 settings.values.music_volume=0.4
 settings.values.sfx_volume=0
 audio.apply_settings()
 check(not AudioServer.is_bus_mute(AudioServer.get_bus_index(audio.MUSIC_BUS)) and not audio.play_effect("relic"),"Effects mute preserves music and suppresses playback")
 settings.values=previous.duplicate(true)
 audio.apply_settings()
 # Real scene paths: score follows encounters, not save/progression callbacks.
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game._process(0)
 check(audio.current_track=="menu","Main menu selects its original theme")
 check(game.character_audio.bus==audio.EFFECT_BUS,"Existing character ability and unlock sounds obey effects volume")
 game.show_options("menu")
 game.show_audio_options()
 await process_frame
 var controls: Dictionary={}
 sliders(game.panel,controls)
 check(controls.size()==2,"Two independent touch volume sliders")
 controls.music_volume.value=0.21
 controls.sfx_volume.value=0.67
 check(is_equal_approx(settings.values.music_volume,0.21) and is_equal_approx(settings.values.sfx_volume,0.67),"Slider closures affect the correct settings")
 check(settings.save_settings()==OK,"Audio preferences save")
 settings.values=settings.DEFAULTS.duplicate()
 settings.load_settings()
 check(is_equal_approx(settings.values.music_volume,0.21) and is_equal_approx(settings.values.sfx_volume,0.67),"Independent volumes reload from actual settings file")
 for dimensions in [Vector2i(960,540),Vector2i(1280,540),Vector2i(960,600)]:
  root.size=dimensions
  await process_frame
  var rect: Rect2=game.panel.get_global_rect()
  check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=dimensions.x+1 and rect.end.y<=dimensions.y+1,"Audio options fit supported landscape sizes")
  for slider: HSlider in controls.values(): check(slider.size.y>=44,"Volume slider is large enough for touch")
 root.size=Vector2i(960,540)
 game.start_dungeon(10020)
 game._process(0)
 check(audio.current_track=="salt_explore","First floor starts with exploration music")
 for floor_index in range(3):
  game.layout.generate(10020,floor_index,true)
  game.layout.current=1
  game.start_game()
  game._process(0)
  check(audio.current_track==AbyssAudioCatalog.BIOME_KEYS[floor_index]+"_combat","Floor-specific combat score")
  game.pause_game()
  count=audio.transition_count
  var current: String=audio.current_track
  game._process(0)
  check(audio.current_track==current and audio.transition_count==count and audio.paused_mix,"Pause retains combat position")
  game.show_options("paused")
  game.show_audio_options()
  game._process(0)
  check(audio.current_track==current,"Paused audio options preserve encounter score")
  game.resume_game()
  game.layout.current=game.layout.boss_room
  game.start_game()
  game._process(0)
  check(audio.current_track==AbyssAudioCatalog.BIOME_KEYS[floor_index]+"_boss","Each existing boss has its own score")
 game.show_main_menu()
 game.start_dungeon(10020)
 game.layout.current=8 # Existing shop index, same common pickup transaction.
 game.start_game()
 game._process(0)
 check(audio.current_track=="special","Peaceful shop selects special event music")
 var product: RelicPickup=game.pickups[0]
 game.coins=0
 reset_cues(audio)
 check(not game.purchase_pickup(product) and heard==["error"],"Failed purchase emits only failure cue")
 game.coins=100
 reset_cues(audio)
 check(game.purchase_pickup(product) and heard==["buy"],"Accepted purchase emits exactly one purchase cue")
 reset_cues(audio)
 check(not game.purchase_pickup(product) and heard.is_empty(),"Repeated sold purchase emits no reward sound")
 var chest: RelicPickup=game.spawn_pickup({"id":"boots","position":Vector2(480,274),"chest":true,"collected":false})
 game.player.position=chest.position
 chest.cooldown=0
 reset_cues(audio)
 check(chest.open_chest() and heard==["chest"],"True chest state transition emits opening cue")
 reset_cues(audio)
 check(not chest.open_chest() and heard.is_empty(),"Opened chest cannot replay opening cue")
 chest.cooldown=0
 chest.open_age=1
 check(chest.claim() and heard==["relic"],"Chest pickup cue fires after actual accepted reward")
 reset_cues(audio)
 check(not chest.claim() and heard.is_empty(),"No duplicate pickup cue")
 var key: RelicPickup=game.spawn_pickup({"id":"crystal","reward_kind":"coins","amount":1,"position":Vector2(650,300),"chest":false,"collected":false})
 reset_cues(audio)
 check(key.claim() and heard==["coin"],"Physical coin collection emits correct cue")
 game.player.stats.health=4
 game.player.immunity=0
 reset_cues(audio)
 game.player.take_damage(1)
 check(heard==["hurt"],"Damage sound follows actual hurt signal")
 game.finish(false)
 game._process(0)
 check(audio.current_track=="defeat","Defeat selects original ending theme")
 game.show_main_menu()
 game.start_game()
 game.finish(true)
 game._process(0)
 check(audio.current_track=="victory","Victory selects original ending theme")
 game.show_main_menu()
 game._process(0)
 check(audio.current_track=="menu","Menu return restores title theme")
 check(CharacterCatalog.DATA.size()==11 and RelicCatalog.DATA.size()==100 and EnemyCatalog.DATA.size()==20,"Existing content preserved without fictitious travelers")
 game.queue_free()
 await process_frame
 await create_timer(0.4).timeout
 settings.values=previous
 settings.save_settings()
 audio.apply_settings()
 progress.data=progress_before
 progress.storage_path=old_path
 print("AUDIO RESULT: %d checks, %d failures" % [checks,failures])
 await AudioTestCleanup.drain(self)
 quit(1 if failures else 0)
