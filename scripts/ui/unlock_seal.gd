class_name UnlockSeal
extends Control
var reveal:=0.0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
 var color:=Color("c4c9cf").lerp(Color("b9ffe5"),reveal)
 draw_style_box(make_style(Color("354459")),Rect2(6,16,28,22))
 # The shackle opens as the pending unlock is revealed in selection.
 draw_set_transform(Vector2(20,16),-reveal*1.1)
 draw_arc(Vector2(0,-4),10,PI,TAU,18,color,3,true)
 draw_line(Vector2(-10,-4),Vector2(-10,5),color,3,true)
 draw_line(Vector2(10,-4),Vector2(10,5),color,3,true)
 draw_set_transform(Vector2.ZERO)
 draw_circle(Vector2(20,25),3,color)
 draw_line(Vector2(20,26),Vector2(20,31),color,3,true)
func make_style(color: Color) -> StyleBoxFlat:
 var box:=StyleBoxFlat.new()
 box.bg_color=color
 box.set_corner_radius_all(5)
 return box
