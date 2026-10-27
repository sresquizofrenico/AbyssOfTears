class_name TideWarden
extends AbyssEnemy
signal health_report(current: float, maximum: float, phase: int)
const ART = preload("res://assets/characters/tide_warden.svg")
const BOSS_IDS := ["tide_warden","root_matron","prism_regent"]
const BOSS_NAMES := ["Custodio de la Marea","Matriarca de Raíces","Regente Prismático"]
const ROOT_ART=preload("res://assets/characters/root_matron.svg")
const PRISM_ART=preload("res://assets/characters/prism_regent.svg")
var display_name: String=""
var sequence: Array[int]=[]
var sequence_step:=0
var floor_level := 0
var phase := 1
var pattern := 0
var aim := Vector2.DOWN
var announced := false
var attacks := [0,0,0]

func _ready() -> void:
 kind=11
 rank="boss"
 super._ready()
 definition={"id":BOSS_IDS[floor_level],"name":BOSS_NAMES[floor_level],"health":28+floor_level*9,"damage":1,"resistance":0.0,"interval":2.5,"reward":12+floor_level*4}
 health=float(definition.health)
 max_health=health
 hit_radius=31
 var collision: CollisionShape2D=get_node("Collision")
 collision.shape=collision.shape.duplicate()
 collision.shape.radius=26
 attack_timer=2.5
 health_report.emit(health,max_health,phase)

func _physics_process(delta: float) -> void:
 if dead or not is_instance_valid(target) or not target.active: return
 if not step_conditions(delta): return
 phase=2 if health<=max_health*0.5 else 1
 attack_timer-=delta
 telegraph=attack_timer<0.75
 if telegraph and not announced:
  aim=(target.position-position).normalized()
  announced=true
 velocity=Vector2.ZERO if telegraph else (target.position-position).normalized()*[25.0,40.0][phase-1]
 if slowed>0: velocity*=0.6
 move_and_slide()
 if attack_timer<=0:
  perform_pattern()
  if sequence.is_empty(): pattern=(pattern+1)%3
  else:
   sequence_step=(sequence_step+1)%sequence.size()
   pattern=sequence[sequence_step]
  attack_timer=2.5 if phase==1 else 2.0
  announced=false
 if position.distance_to(target.position)<43: target.take_damage(1,"contact")
 queue_redraw()

func perform_pattern() -> void:
 attacks[pattern]+=1
 if floor_level==1:
  match pattern:
   0:
    hazard.emit(target.position+Vector2(-100,0),"wall")
    hazard.emit(target.position+Vector2(100,0),"wall")
   1:
    for side in [-1,1]:
     var source:=position+Vector2(side*65,0)
     for angle in [-0.25,0.0,0.25]: shot.emit(source,aim.rotated(angle))
   2:
    summon.emit(3,position+Vector2(-55,0),true)
    if phase==2: summon.emit(3,position+Vector2(55,0),true)
  return
 if floor_level==2:
  match pattern:
   0:
    for i in range(4):
     var direction:=Vector2.from_angle(aim.angle()+PI/4+i*TAU/4)
     shot.emit(position+direction*35,direction)
     if phase==2: shot.emit(position-direction*35,direction.rotated(0.18))
   1: hazard.emit(target.position,"lightning")
   2:
    for side in [-1,1]:
     var direction:=aim.rotated(side*0.6)
     shot.emit(position+direction*35,direction)
     shot.emit(position+direction*35,direction.rotated(side*0.2))
  return
 match pattern:
  0:
   var count:=3 if phase==1 else 5
   for i in range(count):
    var direction:=aim.rotated((i-(count-1)*0.5)*0.24)
    shot.emit(position+direction*34,direction)
  1:
   var count:=8 if phase==1 else 10
   # Guaranteed angular refuge centred on the announced player direction.
   for i in range(count):
    var direction:=Vector2.from_angle(aim.angle()+i*TAU/count)
    if absf(wrapf(direction.angle()-aim.angle(),-PI,PI))<0.55: continue
    shot.emit(position+direction*34,direction)
  2: hazard.emit(target.position,"lightning")

func take_damage(amount: float, incoming := Vector2.ZERO) -> void:
 super.take_damage(amount,incoming)
 phase=2 if health<=max_health*0.5 else 1
 health_report.emit(maxf(0,health),max_health,phase)

func _draw() -> void:
 draw_set_transform(Vector2(0,24),0,Vector2(1,0.3))
 draw_circle(Vector2.ZERO,35,Color(0,0,0,0.35))
 draw_set_transform(Vector2(0,sin(clock*2)*2))
 draw_texture_rect(ROOT_ART if floor_level==1 else PRISM_ART if floor_level==2 else ART,Rect2(-42,-54,84,98),false,Color(1.5,1.5,1.5) if flash>0 else Color.WHITE)
 draw_set_transform(Vector2.ZERO)
 if telegraph:
  draw_arc(Vector2.ZERO,48,0,TAU,32,Color("f2d09b"),2)
  if pattern==0: draw_line(aim*40,aim*110,Color("f2d09b"),3)
  if pattern==1: draw_arc(Vector2.ZERO,64,aim.angle()-0.55,aim.angle()+0.55,12,Color("a9e8c7"),3)
  if pattern==2 and is_instance_valid(target): draw_arc(target.position-position,34,0,TAU,24,Color("e3ca90"),2)
 if phase==2: draw_arc(Vector2.ZERO,43,clock,clock+PI,20,Color("b7b4ed"),2)
 if burning>0: draw_circle(Vector2(0,20),8,Color(1,0.5,0.2,0.7))
 if slowed>0: draw_arc(Vector2.ZERO,46,0,TAU,24,Color("a1e4f5"),2)
