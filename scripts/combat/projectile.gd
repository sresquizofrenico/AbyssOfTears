class_name AbyssProjectile
extends Node2D

var direction := Vector2.RIGHT
var speed := 410.0
var damage := 1.0
var remaining := 540.0
var hostile := false
var expired := false
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
 draw_line(-direction * 12, Vector2.ZERO, Color(color, 0.25), 7)
 draw_circle(Vector2.ZERO, 5 + sin(clock * 18) * 0.6, color)
 draw_circle(-direction * 1.5, 2, Color("f4fff4"))
