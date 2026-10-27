class_name CharacterVFX
extends RefCounted

# Small immediate-mode signatures; no per-particle nodes or dynamic lights.
static func paint(player) -> void:
 var color: Color=player.character_color
 var active: bool=player.ability_active>0
 var clock: float=player.clock
 var amount:=1 if player.quality==0 else 3 if player.quality==1 else 5
 match player.character_id:
  "neris","nyra":
   if active and (player.character_id=="neris" or player.character_state.dash>0):
    for i in range(amount):
     var point: Vector2=-player.dash_direction*(14+i*9)-Vector2(0,6)
     player.draw_line(point,point-player.dash_direction*10,Color(color,0.5/(i+1)),4,true)
  "kael":
   if active:
    for side in [-1,1]:
     var point:=Vector2(side*(23+sin(clock*10)*2),-19)
     player.draw_colored_polygon(PackedVector2Array([point+Vector2(0,-7),point+Vector2(5,2),point+Vector2(-3,7)]),color)
    if player.character_state.windup>0: player.draw_arc(Vector2(0,-4),36,-PI/2,-PI/2+TAU*(1.0-float(player.character_state.windup)/0.35),24,color,2,true)
  "lumi":
   if active or player.character_state.guard_charge:
    for i in range(amount):
     var point:=Vector2.from_angle(clock+i*TAU/amount)*27-Vector2(0,10)
     player.draw_line(point-Vector2(3,0),point+Vector2(3,0),color,2,true)
     player.draw_line(point-Vector2(0,3),point+Vector2(0,3),color,2,true)
  "vex":
   if active:
    var palette: Array[Color]=[Color("f4b079"),Color("bce8ff"),Color("d6bcff"),Color("b5df72")]
    for i in range(mini(4,amount+1)):
     var point:=Vector2.from_angle(clock*2+i*TAU/4)*25-Vector2(0,13)
     player.draw_circle(point,3,palette[(i+player.mixture)%4])
  "orin":
   if active:
    var facing: Vector2=player.facing
    var point:=facing*22-Vector2(0,6)
    player.draw_arc(point,20,facing.angle()-1.2,facing.angle()+1.2,16,Color(color,0.3+float(player.character_state.shield_budget)/3.0),4,true)
  "eira":
   if active:
    for i in range(amount+1):
     var point:=Vector2.from_angle(-clock+i*TAU/(amount+1))*30-Vector2(0,9)
     player.draw_line(point-Vector2(3,0),point+Vector2(3,0),color,2,true)
     player.draw_line(point-Vector2(0,3),point+Vector2(0,3),color,2,true)
  "solen":
   if active or player.cooldown>player.stats.attack_interval*0.7:
    for i in range(amount):
     var point:=Vector2((i-float(amount-1)/2)*10,18-sin(clock*10+i)*3)
     player.draw_colored_polygon(PackedVector2Array([point+Vector2(-3,2),point+Vector2(0,-8),point+Vector2(4,2)]),color)
  "mira":
   if active or player.character_state.shadow_timer>0:
    player.draw_arc(Vector2(44,-9),30,clock,clock+PI,20,Color(color,0.6),2,true)
  "nox":
   for i in range(int(player.character_state.kill_stacks)):
    var point:=Vector2(-8+i*8,-43)
    player.draw_circle(point,2.5,color)
   if player.fatigue>0: player.draw_arc(Vector2(0,14),20,0,TAU,20,Color("d4959e"),2,true)
  "shader":
   if player.awakened>0:
    for i in range(amount):
     var point:=Vector2.from_angle(clock*1.5+i*TAU/amount)*35-Vector2(0,12)
     player.draw_line(point,point-Vector2(0,5),Color(color,0.7),2,true)
