class_name BondArt
extends RefCounted
# Original vector bodies with lightweight, per-character arm/prop signatures.
static func paint(node: CanvasItem, id: String, body: Texture2D, clock: float, moving: bool, pose: String, look: Vector2, origin: Vector2, tilt: float, scale_factor: float, tint: Color=Color.WHITE) -> void:
 var color:=Color(CharacterCatalog.definition(id).color)
 var stride:=sin(clock*(14 if id in ["beren","dalia"] else 10))*3 if moving else 0.0
 var raised:=pose in ["present","victory","pickup"]
 for side in [-1,1]:
  var at:=origin+Vector2(side*18,-10+stride*side*0.5)*scale_factor
  var angle: float=side*(-0.7 if raised else 0.1)+tilt+stride*side*0.025
  if pose=="attack": angle+=look.x*0.4
  node.draw_set_transform(at,angle,Vector2.ONE*scale_factor)
  var sleeve:=Color("a98962") if id=="kairon" else color.darkened(0.45)
  node.draw_style_box(arm_style(sleeve*tint),Rect2(-4,0,8,19))
  node.draw_circle(Vector2(0,18),4,Color("dec4ae")*tint)
  if side==1:
   if id=="lyra":
    node.draw_rect(Rect2(-5,15,11,10),Color("c6be9d")*tint)
    node.draw_line(Vector2(-3,18),Vector2(4,21),Color("537e7e")*tint,1)
   elif id=="kairon": node.draw_circle(Vector2(0,19),5,Color("8ce0af")*tint)
   elif id=="yura": node.draw_arc(Vector2(0,16),8,0,TAU,12,Color(color,0.7)*tint,1.3)
   elif id=="celine": node.draw_rect(Rect2(-5,13,10,13),Color("557d74")*tint)
   elif id=="nami":
    node.draw_circle(Vector2(0,20),5,Color("97c896")*tint)
    node.draw_line(Vector2(0,18),Vector2(0,25),Color("dce8b7")*tint,2)
   elif id=="elora": node.draw_arc(Vector2(0,18),9,-1.2,1.2,12,color*tint,3)
 node.draw_set_transform(origin,tilt+stride*0.004,Vector2.ONE*scale_factor)
 node.draw_texture_rect(body,Rect2(-24,-40,48,64),false,tint)
 if fmod(clock,4.9)>4.76 or pose=="defeat":
  for x in [-5.5,5.5]: node.draw_line(Vector2(x-2.5,-18),Vector2(x+2.5,-18),Color("263746")*tint,1.7)
 if pose=="attack": node.draw_arc(look*24,5,0,TAU,12,color*tint,1)
 node.draw_set_transform(Vector2.ZERO)
static var styles: Dictionary={}
static func arm_style(color: Color) -> StyleBoxFlat:
 var key:=color.to_html()
 if not styles.has(key):
  var style:=StyleBoxFlat.new()
  style.bg_color=color
  style.border_color=Color("1b2c3c")
  style.set_border_width_all(1)
  style.set_corner_radius_all(3)
  styles[key]=style
 return styles[key]
