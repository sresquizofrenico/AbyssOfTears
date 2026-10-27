class_name CharacterSounds
extends RefCounted

# Original short synthesized motifs, mono 22.05 kHz. Generated on demand;
# no third-party samples and no permanently resident ten-character audio bank.
static func melody(notes: Array, duration: float) -> AudioStreamWAV:
 var sound:=AudioStreamWAV.new()
 sound.format=AudioStreamWAV.FORMAT_16_BITS
 sound.mix_rate=22050
 var count:=int(duration*sound.mix_rate)
 var bytes:=PackedByteArray()
 bytes.resize(count*2)
 for i in range(count):
  var time:=float(i)/sound.mix_rate
  var note:=float(notes[mini(notes.size()-1,int(time/duration*notes.size()))])
  var phase:=fmod(time,duration/notes.size())/(duration/notes.size())
  var envelope:=sin(phase*PI)*exp(-phase*2.0)
  var sample: int=int((sin(TAU*note*time)+sin(TAU*note*2*time)*0.2)*envelope*11000)
  bytes.encode_s16(i*2,sample)
 sound.data=bytes
 return sound

static func ability_sound(id: String) -> AudioStreamWAV:
 var index:=0
 for i in range(CharacterCatalog.DATA.size()):
  if CharacterCatalog.DATA[i].id==id: index=i
 return melody([220.0+index*29,330.0+index*23],0.18)

static func unlock_sound() -> AudioStreamWAV:
 return melody([330.0,440.0,554.37,659.25],0.65)
