extends SceneTree
var checks:=0
var failures:=0

func _initialize() -> void: run.call_deferred()

func measure(capture: AudioEffectCapture, name: String) -> void:
 var samples:=capture.get_buffer(capture.get_frames_available())
 var peak:=0.0
 for sample: Vector2 in samples: peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
 checks+=1
 if samples.size()<256 or peak<=0.0001 or peak>=0.98:
  failures+=1
  push_error("TEST FAILED: non-silent unclipped mixer output "+name)

func run() -> void:
 var director=root.get_node("Soundscape")
 var settings=root.get_node("Settings")
 var original: Dictionary=settings.values.duplicate(true)
 settings.values.music_volume=1.0
 settings.values.sfx_volume=1.0
 director.apply_settings()
 for bus in ["AbyssMusic","AbyssSFX"]:
  var index:=AudioServer.get_bus_index(bus)
  var capture:=AudioEffectCapture.new()
  capture.buffer_length=1
  AudioServer.add_bus_effect(index,capture)
  if bus=="AbyssMusic":
   for id: String in AbyssAudioCatalog.tracks():
    director.set_context(id)
    director._process(0.8)
    capture.clear_buffer()
    await create_timer(0.2).timeout
    measure(capture,id)
  else:
   for id: String in AbyssAudioCatalog.EFFECTS:
    capture.clear_buffer()
    director.play_effect(id)
    await create_timer(0.2).timeout
    measure(capture,id)
  AudioServer.remove_bus_effect(index,0)
 settings.values=original
 director.apply_settings()
 await AudioTestCleanup.drain(self)
 print("AUDIO MIXER RESULT: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
