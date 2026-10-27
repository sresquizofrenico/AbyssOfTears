class_name MenuCharacter
extends Node2D

const BODY = IllustratedNeris.BODY
var body_texture: Texture2D = BODY
var clock := 0.0
var animation_rate := 1.0
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
 draw_texture_rect(IllustratedNeris.SHADOW,Rect2(-62,28,124,33),false)
 var bob := absf(sin(clock*11))*1.5 if moving else sin(clock*2)*0.5
 IllustratedNeris.paint(self,clock*animation_rate,moving,pose,look,Vector2(0,bob),sin(clock*2)*0.015,2.25,Color.WHITE,body_texture)

func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
