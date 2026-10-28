class_name IllustratedNeris
extends RefCounted

const SHADOW = preload("res://assets/illustrated/shadow.svg")
const BODY = preload("res://assets/illustrated/neris_body.svg")
const ARM = preload("res://assets/illustrated/arm.svg")
const BOOT = preload("res://assets/illustrated/boot.svg")
const LANTERN = preload("res://assets/illustrated/lantern.svg")

# Shared layer animation: menu, selection and playable Neris use the same art.
# Transform coordinates are purely visual; no collision or stats are changed.
static func paint(node: CanvasItem, clock: float, moving: bool, pose: String, look: Vector2, origin:=Vector2.ZERO, tilt:=0.0, magnification:=1.0, tint:=Color.WHITE, body: Texture2D=BODY, pose_weight: float=-1.0) -> void:
 var stride:=sin(clock*11)*3.0 if moving else 0.0
 var breath:=sin(clock*2.5)*0.45
 for side in [-1,1]:
  var boot_origin:=origin+Vector2(side*9,13+stride*side)*magnification
  node.draw_set_transform(boot_origin,tilt+stride*side*0.015,Vector2.ONE*magnification)
  node.draw_texture_rect(BOOT,Rect2(-6,-7,13,22),false,tint)
 var raised:=pose in ["present","victory","pickup"]
 var lift:=clampf(pose_weight,0,1) if pose_weight>=0 else (1.0 if raised else 0.0)
 for side in [-1,1]:
  var angle: float=side*lerpf(0.1,-0.55,lift)+stride*side*0.015
  if pose in ["attack","light"]: angle += look.x*0.35
  node.draw_set_transform(origin+Vector2(side*17,-14+breath)*magnification,angle+tilt,Vector2(side,1)*magnification)
  node.draw_texture_rect(ARM,Rect2(-5,0,10,24),false,tint)
  if side==1: node.draw_texture_rect(LANTERN,Rect2(-4,18,13,18),false,tint)
 node.draw_set_transform(origin+Vector2(0,breath)*magnification,tilt,Vector2.ONE*magnification)
 node.draw_texture_rect(body,Rect2(-24,-40,48,64),false,tint)
 if pose=="defeat":
  node.draw_rect(Rect2(-4,-17,9,5),Color("9dbfba"))
  node.draw_polyline(PackedVector2Array([Vector2(-3,-13),Vector2(0,-15),Vector2(3,-13)]),Color("3a535e"),1.1,true)
  for side in [-1,1]:
   node.draw_line(Vector2(side*5.5-2,-24),Vector2(side*5.5+2,-21),Color("223b50"),1.5,true)
   node.draw_line(Vector2(side*5.5-2,-21),Vector2(side*5.5+2,-24),Color("223b50"),1.5,true)
 # Occasional blink; pupils remain expressive without changing game state.
 if fmod(clock,5.3)>5.15:
  for side in [-1,1]: node.draw_line(Vector2(side*5.5-2.5,-22),Vector2(side*5.5+2.5,-22),Color("304e60"),1.6,true)
 node.draw_set_transform(Vector2.ZERO)
