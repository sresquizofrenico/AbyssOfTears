class_name GuestArt
extends RefCounted
static func paint(node: CanvasItem, body: Texture2D, clock: float, moving: bool, pose: String, facing: Vector2, origin: Vector2, magnification: float, tint:=Color.WHITE) -> void:
 # One shared private atlas, no frame cropping or texture loading per draw.
 var step:=sin(clock*10) if moving else 0.0
 var lift: float=sin(clock*2)*0.3 if not moving else absf(step)*0.9
 var lean: float=step*0.012 if moving else sin(clock*1.7)*0.004
 if pose=="defeat": lean+=0.55
 var flip: float=-1.0 if facing.x< -0.5 else 1.0
 node.draw_set_transform(origin+Vector2(0,lift)*magnification,lean,Vector2(flip,1)*magnification)
 var width:=66.0*body.get_width()/body.get_height()
 node.draw_texture_rect(body,Rect2(-width*0.5,-43,width,66),false,tint)
 if pose in ["attack","present"]: node.draw_arc(Vector2(17,-9),6,clock,clock+PI,12,Color("bddeef"),1.2)
 node.draw_set_transform(Vector2.ZERO)
