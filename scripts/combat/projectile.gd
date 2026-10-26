class_name AbyssProjectile
extends Node2D

const TEAR = preload("res://assets/illustrated/tear.svg")

var direction := Vector2.RIGHT
var speed := 410.0
var damage := 1.0
var remaining := 540.0
var hostile := false
var expired := false
var pierce := 0
var bounces := 0
var elements: Array[String] = []
var hits: Dictionary = {}
var clock := 0.0

func advance(delta: float) -> void:
 clock += delta
 var distance := minf(speed * delta, remaining)
 position += direction * distance
 remaining -= distance
 if remaining <= 0.0:
  expire()
 queue_redraw()

func expire() -> void:
 if expired: return
 expired = true
 queue_free()

func _draw() -> void:
 var color := Color("f6a58f") if hostile else Color("91ffeb")
 if "fire" in elements: color = Color("ffb26b")
 if "ice" in elements: color = Color("a1e4f5")
 if "electric" in elements: color = Color("d5c2ff")
 if elements.size()>1: draw_arc(Vector2.ZERO,9,clock*8,clock*8+PI,10,Color("ffd7a0"),2)
 draw_line(-direction * 12, Vector2.ZERO, Color(color, 0.25), 7)
 draw_set_transform(Vector2.ZERO,direction.angle()+PI*0.5,Vector2.ONE)
 draw_texture_rect(TEAR,Rect2(-6,-10,12,18),false,color)
 draw_set_transform(Vector2.ZERO)
