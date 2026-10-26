class_name DungeonMap
extends Control

var layout: FloorLayout
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
 if layout == null: return
 draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,0.04,0.08,0.92))
 var center := size * 0.5
 var visible_ids := layout.visible_rooms()
 var low := Vector2(layout.rooms[layout.current].cell)
 var high := low
 for id in visible_ids:
  low = low.min(Vector2(layout.rooms[id].cell))
  high = high.max(Vector2(layout.rooms[id].cell))
 var middle := (low+high)*0.5
 var span := high-low+Vector2.ONE
 var step := minf(20.0,minf((size.x-16)/span.x,(size.y-16)/span.y))
 for id in visible_ids:
  var room: Dictionary = layout.rooms[id]
  var point := center + (Vector2(room.cell)-middle) * step
  for other: int in room.links:
   if visible_ids.has(other):
    var end := center + (Vector2(layout.rooms[other].cell)-middle)*step
    draw_line(point,end,Color("577d8d"),2)
 for id in visible_ids:
  var room: Dictionary = layout.rooms[id]
  var point := center + (Vector2(room.cell)-middle) * step
  var color := Color("537082") if not room.visited else Color("9bc9bc")
  if id == layout.current: color = Color("ffdd9b")
  draw_rect(Rect2(point-Vector2(4,4),Vector2(8,8)),color)
  if room.kind in ["treasure","descent"]:
   draw_circle(point,1.5,Color("172538"))
