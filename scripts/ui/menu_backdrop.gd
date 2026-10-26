class_name MenuBackdrop
extends Node2D
const HERO = preload("res://assets/characters/neris.svg")
const FLOOR = preload("res://assets/environment/floor.svg")
const COLUMN = preload("res://assets/environment/column.svg")
const CRYSTAL = preload("res://assets/relics/crystal.svg")
var clock := 0.0
func _process(delta: float) -> void:
 if visible:
  clock += delta
  queue_redraw()
func _draw() -> void:
 var size := get_viewport().get_visible_rect().size
 var shift := (size-Vector2(960,540))*0.5
 draw_rect(Rect2(Vector2.ZERO,size),Color("0d1928"))
 draw_texture_rect(FLOOR,Rect2(shift+Vector2(0,330),Vector2(960,210)),true,Color(0.7,0.8,0.9,0.45))
 for x in [90,210,750,870]:
  draw_texture_rect(COLUMN,Rect2(shift+Vector2(x-40,140),Vector2(80,220)),false,Color(0.6,0.75,0.85,0.6))
 for x in [150,810]:
  for radius in [100,70,40]:
   draw_circle(shift+Vector2(x,300),radius,Color(0.2,0.7,0.7,0.025))
 var point := shift+Vector2(155,350+sin(clock*2)*3)
 draw_texture_rect(HERO,Rect2(point-Vector2(44,108),Vector2(88,118)),false)
 var phase := fmod(clock,8.0)
 if phase>2 and phase<4:
  draw_circle(point+Vector2(35+(phase-2)*60,-40),6,Color("b5ebdf"))
 if phase>=4:
  draw_texture_rect(CRYSTAL,Rect2(point+Vector2(-17,-148+sin(clock*4)*3),Vector2(34,34)),false,Color(1,1,1,minf(1,phase-4)))
 draw_texture_rect(EnemyArt.TEXTURES[10],Rect2(shift+Vector2(760,280+sin(clock*2)*5),Vector2(88,88)),false,Color(0.8,0.85,1,0.75))
