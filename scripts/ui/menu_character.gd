class_name MenuCharacter
extends Node2D

const BODY = IllustratedNeris.BODY
var body_texture: Texture2D = BODY
var character_id: String="neris"
var clock := 0.0
var animation_rate := 1.0
var moving := false
var look := Vector2.RIGHT
var pose := "rest"
var previous := Vector2.ZERO
var pose_weight:=0.0
var selection_preview:=false

func animate(delta: float, destination: Vector2, next_pose: String, direction: Vector2) -> void:
 clock += delta
 previous = position
 position = position.lerp(destination,1.0-exp(-delta*7.0))
 moving = previous.distance_to(position)>0.08
 pose = next_pose
 update_pose(delta)
 look = look.lerp(direction,1.0-exp(-delta*8.0)).normalized()
 queue_redraw()

func _draw() -> void:
 draw_texture_rect(IllustratedNeris.SHADOW,Rect2(-62,28,124,33),false)
 var bob := absf(sin(clock*11))*1.2 if moving else sin(clock*2)*0.3
 if not GuestRoster.definition(character_id).is_empty(): GuestArt.paint(self,body_texture,clock,moving,pose,look,Vector2(0,bob),2.25)
 elif character_id=="shader": ShaderArt.paint(self,clock,moving,pose,look,Vector2(0,bob),sin(clock*2)*0.007,2.25)
 elif character_id in BondCatalog.IDS: BondArt.paint(self,character_id,body_texture,clock*animation_rate,moving,pose,look,Vector2(0,bob),sin(clock*2)*0.007,2.25,Color.WHITE,pose_weight)
 else: IllustratedNeris.paint(self,clock*animation_rate,moving,pose,look,Vector2(0,bob),sin(clock*2)*0.007,2.25,Color.WHITE,body_texture,pose_weight)

func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func update_pose(delta: float) -> void:
 var target:=1.0 if pose in ["present","victory","pickup"] else 0.0
 pose_weight=lerpf(pose_weight,target,1.0-exp(-delta*9.0))
