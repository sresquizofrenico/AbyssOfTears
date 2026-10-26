class_name MenuCharacter
extends Node2D

const BODY = preload("res://assets/characters/neris_body.svg")
var body_texture: Texture2D = BODY
var clock := 0.0
var moving := false
var look := Vector2.RIGHT
var pose := "rest"
var previous := Vector2.ZERO

func animate(delta: float, destination: Vector2, next_pose: String, direction: Vector2) -> void:
 clock += delta
 previous = position
 position = position.lerp(destination,1.0-exp(-delta*7.0))
 moving = previous.distance_to(position)>0.08
 pose = next_pose
 look = look.lerp(direction,1.0-exp(-delta*8.0)).normalized()
 queue_redraw()

func _draw() -> void:
 draw_set_transform(Vector2(0,45),0,Vector2(1,0.24))
 draw_circle(Vector2.ZERO,48,Color(0,0,0,0.35))
 var stride := sin(clock*10)*3 if moving else 0.0
 var bob := absf(sin(clock*10))*1.5 if moving else sin(clock*2)*0.5
 draw_set_transform(Vector2(0,bob),sin(clock*2)*0.015,Vector2(2.25,2.25))
 for side in [-1,1]:
  var foot := Vector2(side*9,20+stride*side)
  draw_line(Vector2(side*7,4),foot,Color("344860"),5,true)
  draw_line(foot-Vector2(2,0),foot+Vector2(4,0),Color("9eb9bd"),4,true)
  var hand := Vector2(side*18,-3+stride*side*0.7)
  if pose == "present": hand.y = -28
  elif pose == "attack" or pose == "light": hand += look * 7
  draw_line(Vector2(side*10,-16),hand,Color("7d9fa8"),4,true)
  draw_circle(hand,3,Color("cad9c6"))
  if side == 1:
   draw_rect(Rect2(hand+Vector2(-3,4),Vector2(7,10)),Color("c4ae7b"))
   draw_rect(Rect2(hand+Vector2(-1,6),Vector2(3,6)),Color("91e8ce"))
 draw_texture_rect(body_texture,Rect2(-24,-40,48,64),false)
 draw_circle(Vector2(-5,-23)+look,1,Color("e2f6d6"))
 draw_circle(Vector2(6,-23)+look,1,Color("e2f6d6"))
 draw_set_transform(Vector2.ZERO)
