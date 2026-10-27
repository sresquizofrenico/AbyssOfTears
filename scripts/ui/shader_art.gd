class_name ShaderArt
extends RefCounted
# Directional art is original and provisional, authored from the description.
const PATHS={"front":"res://assets/characters/shader_front.svg","back":"res://assets/characters/shader_back.svg","left":"res://assets/characters/shader_left.svg","right":"res://assets/characters/shader_right.svg"}
static var textures: Dictionary={}
static func direction_texture(direction: String) -> Texture2D:
 if not textures.has(direction): textures[direction]=load(PATHS[direction])
 return textures[direction]
static func paint(node: CanvasItem, clock: float, moving: bool, pose: String, facing: Vector2, origin: Vector2, tilt: float, scale_value: float, state: int=0, tint_multiplier:=Color.WHITE) -> void:
 var direction: String="front"
 if absf(facing.y)>absf(facing.x): direction="back" if facing.y<0 else "front"
 elif absf(facing.x)>0.2: direction="left" if facing.x<0 else "right"
 var stride:=sin(clock*12)*1.4 if moving else sin(clock*2.2)*0.4
 var lean:=tilt+(sin(clock*12)*0.035 if moving else 0.0)
 if pose=="defeat": lean+=0.8
 node.draw_set_transform(origin+Vector2(0,stride)*scale_value,lean,Vector2.ONE*scale_value)
 if state>0:
  node.draw_arc(Vector2(0,-7),31,clock,clock+PI*1.7,28,Color("bc94f2") if state==1 else Color("f1d1ff"),2.0,true)
 var tint:=Color.WHITE if state==0 else Color(1.1,1,1.2) if state==1 else Color(1.15,1,1.35)
 node.draw_texture_rect(direction_texture(direction),Rect2(-24,-42,48,66),false,tint*tint_multiplier)
 if pose in ["attack","present","victory","pickup"]:
  node.draw_arc(Vector2(14,-15),10,clock*4,clock*4+PI,12,Color("d2b0ff"),2,true)
 node.draw_set_transform(Vector2.ZERO)
