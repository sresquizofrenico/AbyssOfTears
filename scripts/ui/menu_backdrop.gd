class_name MenuBackdrop
extends Node2D

const CHARACTER = preload("res://scenes/ui/menu_character.tscn")
const FLOOR = preload("res://assets/illustrated/floor_0.svg")
const COLUMN = preload("res://assets/illustrated/column.svg")
const DOOR = preload("res://assets/illustrated/door.svg")
const CRYSTAL = preload("res://assets/relics/crystal.svg")
var character: MenuCharacter
var clock := 0.0
var intro_time := MenuIntro.DURATION
var reaction := ""
var reaction_left := 0.0
var quality := 1
var suspended := false
var safe_left := 0.0
var safe_right := 0.0
var ambient_action := "rest"

func _ready() -> void:
 character = CHARACTER.instantiate()
 add_child(character)
 character.position = center()
 visibility_changed.connect(func(): set_process(is_visible_in_tree()))

func center() -> Vector2:
 var size := get_viewport().get_visible_rect().size
 return Vector2(safe_left+(size.x-360-safe_left-safe_right)*0.52,size.y*0.64)

func door_position() -> Vector2:
 return Vector2(get_viewport().get_visible_rect().size.x-420-safe_right,center().y)

func react(action: String) -> void:
 reaction = action
 reaction_left = 0.48 if action in ["new_game","continue"] else 0.65

func particle_count() -> int:
 return [4,10,18][clampi(quality,0,2)]

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: suspended = true
 elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]: suspended = false

func _process(delta: float) -> void:
 if not visible or suspended: return
 var settings := get_tree().root.get_node_or_null("Settings")
 if settings != null: quality = int(settings.values.quality)
 clock += delta
 reaction_left = maxf(0,reaction_left-delta)
 var destination := center()
 var pose := "rest"
 var look := Vector2.RIGHT
 character.visible = intro_time >= 0.8
 if intro_time < 2.7:
  var fraction := smoothstep(0.8,2.7,intro_time)
  destination = Vector2(-60,center().y).lerp(center(),fraction)
  character.position = destination
  pose = "walk"
 elif intro_time < MenuIntro.DURATION:
  pose = "attack" if intro_time>=3.6 and intro_time<4.4 else "rest"
  look = Vector2.from_angle(sin(intro_time*3)*0.6) if intro_time<3.6 else Vector2.RIGHT
 else:
  var phase := fmod(clock,18.0)
  if phase<4:
   ambient_action = "walk"
   destination += Vector2(sin(phase*1.5)*55,sin(phase*3)*8)
   pose = "walk"
   look = Vector2.RIGHT if cos(phase*1.5)>0 else Vector2.LEFT
  elif phase<7:
   ambient_action = "look"
   look = Vector2.from_angle((phase-4)*TAU/3)
  elif phase<10:
   ambient_action = "attack"
   pose = "attack"
  elif phase<12:
   ambient_action = "dodge"
   destination += Vector2(-45,sin((phase-10)*PI)*24)
   pose = "walk"
  elif phase<15:
   ambient_action = "rest"
   look = Vector2.DOWN
  else:
   ambient_action = "light"
   look = Vector2(0.7,-0.7)
   pose = "light"
 if reaction_left>0:
  match reaction:
   "new_game": destination = door_position(); pose = "walk"; look = Vector2.RIGHT
   "continue": destination = center()+Vector2(110,0); pose = "walk"
   "options": pose = "light"; look = Vector2(0.7,-0.7)
   "characters": pose = "present"; look = Vector2.DOWN
   "credits": look = Vector2.UP
 character.animate(delta,destination,pose,look)
 if intro_time<2.7: character.moving = true
 queue_redraw()

func _draw() -> void:
 var size := get_viewport().get_visible_rect().size
 draw_rect(Rect2(Vector2.ZERO,size),Color("0b1524"))
 draw_texture_rect(FLOOR,Rect2(0,size.y*0.57,size.x,size.y*0.43),false,Color(0.6,0.7,0.85,0.6))
 for x in [55.0,170.0,size.x-430,size.x-80]:
  draw_texture_rect(COLUMN,Rect2(x-34,size.y*0.25,68,size.y*0.44),false,Color(0.55,0.65,0.85,0.7))
 var blue := smoothstep(0,1.4,intro_time)
 var glow := center()+Vector2(0,-12)
 var rings := 2 if quality==0 else 4
 for i in range(rings,0,-1):
  draw_circle(glow,42+i*27,Color(0.16,0.58,0.95,blue*(0.018+sin(clock*1.3)*0.003)))
 if quality>0:
  draw_circle(door_position()+Vector2(0,-20),64,Color(0.4,0.2,0.7,0.035))
 draw_texture_rect(DOOR,Rect2(door_position()-Vector2(26,60),Vector2(52,85)),false,Color(0.65,0.75,0.9))
 var light := center()+Vector2(105,-95+sin(clock*2)*5)
 draw_texture_rect(CRYSTAL,Rect2(light-Vector2(15,15),Vector2(30,30)),false,Color(0.65,0.75,1,0.85))
 for i in range(particle_count()):
  var point := Vector2(fmod(i*113.0+sin(clock+i)*8,size.x-370),fposmod(i*67.0-clock*(5+i%4),size.y))
  draw_circle(point,1.2 if i%3 else 2,Color(0.5,0.7,0.95,0.15+sin(clock+i)*0.08))
 var creature := center()+Vector2(145,15)
 var intro_creature := intro_time>=3 and intro_time<4.4
 var ambient_creature := intro_time>=MenuIntro.DURATION and ambient_action in ["attack","dodge"]
 if intro_creature or ambient_creature:
  creature.y += sin(clock*4)*6
  draw_texture_rect(EnemyArt.TEXTURES[0],Rect2(creature-Vector2(24,35),Vector2(48,48)),false,Color(0.7,0.75,1,0.85))
 if intro_time>=3.6 and intro_time<4.4:
  var t := smoothstep(3.6,4.4,intro_time)
  draw_bolt(center()+Vector2(35,-25),creature,t)
 elif ambient_creature and ambient_action == "attack":
  draw_bolt(character.position+Vector2(35,-25),creature,fmod(clock*1.8,1.0))
 var dissolve := intro_time>=4.4 and intro_time<5.2
 if dissolve:
  var t := (intro_time-4.4)/0.8
  for i in range(6 if quality==0 else 12):
   var point := creature+Vector2.from_angle(i*TAU/12)*t*40
   draw_circle(point,3*(1-t),Color(0.55,0.75,1,1-t))

func draw_bolt(origin: Vector2, destination: Vector2, fraction: float) -> void:
 var point := origin.lerp(destination,fraction)
 draw_line(point-Vector2(14,0),point,Color(0.5,0.9,1,0.3),8)
 draw_circle(point,5,Color("b8f1ed"))
