class_name TideWarden
extends AbyssEnemy
signal health_report(current: float, maximum: float, phase: int)
const ART = preload("res://assets/characters/tide_warden.svg")
var floor_level := 0
var phase := 1
var pattern := 0
var aim := Vector2.DOWN
var announced := false
var attacks := [0,0,0]

func _ready() -> void:
 kind=11
 super._ready()
 definition={"id":"tide_warden","name":"Custodio de la Marea","health":28+floor_level*9,"damage":1,"resistance":0.0,"interval":2.5,"reward":12+floor_level*4}
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
  pattern=(pattern+1)%3
  attack_timer=2.5 if phase==1 else 2.0
  announced=false
 if position.distance_to(target.position)<43: target.take_damage(1)
 queue_redraw()

func perform_pattern() -> void:
 attacks[pattern]+=1
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
 draw_texture_rect(ART,Rect2(-42,-54,84,98),false,Color(1.5,1.5,1.5) if flash>0 else Color.WHITE)
 draw_set_transform(Vector2.ZERO)
 if telegraph:
  draw_arc(Vector2.ZERO,48,0,TAU,32,Color("f2d09b"),2)
  if pattern==0: draw_line(aim*40,aim*110,Color("f2d09b"),3)
  if pattern==1: draw_arc(Vector2.ZERO,64,aim.angle()-0.55,aim.angle()+0.55,12,Color("a9e8c7"),3)
  if pattern==2 and is_instance_valid(target): draw_arc(target.position-position,34,0,TAU,24,Color("e3ca90"),2)
 if phase==2: draw_arc(Vector2.ZERO,43,clock,clock+PI,20,Color("b7b4ed"),2)
 if burning>0: draw_circle(Vector2(0,20),8,Color(1,0.5,0.2,0.7))
 if slowed>0: draw_arc(Vector2.ZERO,46,0,TAU,24,Color("a1e4f5"),2)
