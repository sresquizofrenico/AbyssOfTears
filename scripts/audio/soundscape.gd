extends Node

signal effect_played(id: String)
const MUSIC_BUS := "AbyssMusic"
const EFFECT_BUS := "AbyssSFX"
const VOICE_LIMIT := 6
const CROSSFADE := 0.7
var music: Array[AudioStreamPlayer]=[]
var voices: Array[AudioStreamPlayer]=[]
var gains: Array[float]=[0.0,0.0]
var fade_from: Array[float]=[0.0,0.0]
var active_slot:=0
var fade_age:=CROSSFADE
var current_track: String=""
var paused_mix:=false
var backgrounded:=false
var clock:=0.0
var last_effect: Dictionary={}
var effects: Dictionary={}
var transition_count:=0
var owned_buses: Array[String]=[]

func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 for bus in [MUSIC_BUS,EFFECT_BUS]:
  if AudioServer.get_bus_index(bus)<0:
   AudioServer.add_bus()
   AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
   AudioServer.set_bus_send(AudioServer.bus_count-1,"Master")
   owned_buses.append(bus)
 for i in range(2):
  var voice:=AudioStreamPlayer.new()
  voice.bus=MUSIC_BUS
  voice.volume_db=-80
  add_child(voice)
  music.append(voice)
 for i in range(VOICE_LIMIT):
  var voice:=AudioStreamPlayer.new()
  voice.bus=EFFECT_BUS
  voice.volume_db=-7
  add_child(voice)
  voices.append(voice)
 apply_settings()

func apply_settings() -> void:
 var settings:=get_node_or_null("/root/Settings")
 if settings==null: return
 for pair in [[MUSIC_BUS,"music_volume"],[EFFECT_BUS,"sfx_volume"]]:
  var index:=AudioServer.get_bus_index(pair[0])
  if index<0: continue
  var value: float=clampf(float(settings.values.get(pair[1],0.55 if pair[0]==MUSIC_BUS else 0.8)),0,1)
  AudioServer.set_bus_mute(index,value<=0.0001)
  AudioServer.set_bus_volume_db(index,linear_to_db(maxf(value,0.0001)))

func set_context(id: String, quiet: bool=false) -> bool:
 paused_mix=quiet
 if id==current_track: return false
 if not AbyssAudioCatalog.tracks().has(id): return false
 var entry: Dictionary=AbyssAudioCatalog.tracks()[id]
 # Ignore global resource cache: only two streamed scores remain resident.
 var stream:=ResourceLoader.load(str(entry.path),"AudioStreamOggVorbis",ResourceLoader.CACHE_MODE_IGNORE) as AudioStreamOggVorbis
 if stream==null: return false
 stream.loop=true
 # Keep the louder side when a third request interrupts a fade.
 var previous:=0 if gains[0]>=gains[1] else 1
 active_slot=1-previous
 music[active_slot].stop()
 music[active_slot].stream=stream
 gains[active_slot]=0.0
 fade_from=gains.duplicate()
 fade_age=0
 music[active_slot].volume_db=-80
 music[active_slot].play()
 music[active_slot].stream_paused=backgrounded
 current_track=id
 transition_count+=1
 return true

func _process(delta: float) -> void:
 if backgrounded: return
 clock+=delta
 if current_track.is_empty(): return
 fade_age=minf(CROSSFADE,fade_age+delta)
 var t:=smoothstep(0,CROSSFADE,fade_age)
 for i in range(music.size()):
  gains[i]=lerpf(fade_from[i],1.0 if i==active_slot else 0.0,t)
  music[i].volume_db=linear_to_db(maxf(0.0001,gains[i]*(0.4 if paused_mix else 1.0)))-9
  if i!=active_slot and fade_age>=CROSSFADE and music[i].stream!=null:
   music[i].stop()
   music[i].stream=null

func play_effect(id: String) -> bool:
 if backgrounded or id not in AbyssAudioCatalog.EFFECTS: return false
 var bus:=AudioServer.get_bus_index(EFFECT_BUS)
 if bus>=0 and AudioServer.is_bus_mute(bus): return false
 if clock-float(last_effect.get(id,-100.0))< (0.11 if id in ["hit","enemy"] else 0.065): return false
 var free: AudioStreamPlayer
 for voice in voices:
  if not voice.playing: free=voice; break
 if free==null: return false # Drop excess cues; never cut critical music/controls.
 if not effects.has(id): effects[id]=load(AbyssAudioCatalog.EFFECT_DIR+id+".wav") as AudioStreamWAV
 if effects[id]==null: return false
 free.stop()
 free.stream=effects[id]
 free.play()
 last_effect[id]=clock
 effect_played.emit(id)
 return true

func set_backgrounded(value: bool) -> void:
 backgrounded=value
 for voice in music: voice.stream_paused=value
 if value:
  for voice in voices: voice.stop(); voice.stream=null

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: set_backgrounded(true)
 elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]: set_backgrounded(false)

func stop_all() -> void:
 for voice in music+voices: voice.stop(); voice.stream=null
 effects.clear()
 gains=[0.0,0.0]
 fade_from=[0.0,0.0]
 current_track=""

func _exit_tree() -> void:
 stop_all()
 for bus in owned_buses:
  var index:=AudioServer.get_bus_index(bus)
  if index>=0: AudioServer.remove_bus(index)
