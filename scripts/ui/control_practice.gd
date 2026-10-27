class_name ControlPractice
extends Control
signal back_requested
var controls: TouchControls
var hero:=Vector2(480,275)
var clock:=0.0
var direction:=Vector2.DOWN
var cooldown:=0.0
var shots: Array[Dictionary]=[]
var message: Label
var back: Button
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 controls=TouchControls.new()
 controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(controls)
 controls.configure(get_tree().root.get_node("Settings").values)
 controls.item_visible=true
 controls.awaken_visible=true
 controls.determination=100
 controls.ability_icon=CharacterCatalog.ability_icon("neris")
 controls.ability_requested.connect(func(): message.text="Habilidad detectada · Sigue moviéndote y disparando")
 controls.item_requested.connect(func(): message.text="Objeto detectado · Cada dedo conserva su acción")
 controls.awaken_requested.connect(func(): message.text="Despertar detectado · Sin modificar tu partida")
 controls.set_enabled(true)
 message=Label.new()
 message.text="PRUEBA DE CONTROLES · No modifica tu partida"
 message.position=Vector2(24,24)
 message.add_theme_font_size_override("font_size",18)
 message.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(message)
 back=Button.new()
 back.text="VOLVER"
 back.custom_minimum_size=Vector2(150,52)
 back.pressed.connect(func(): controls.release_all(); back_requested.emit())
 add_child(back)
 resized.connect(layout_preview)
 layout_preview()
func layout_preview() -> void:
 if not is_instance_valid(back): return
 back.position=Vector2(size.x-174,18)
 back.size=Vector2(150,52)
 controls.excluded_regions=[back.get_global_rect()]
func _process(delta: float) -> void:
 clock+=delta
 hero=(hero+controls.move_vector*180*delta).clamp(Vector2(70,140),size-Vector2(70,100))
 cooldown=maxf(0,cooldown-delta)
 if controls.fire_vector!=Vector2.ZERO:
  direction=controls.fire_vector
  if cooldown<=0 and shots.size()<24:
   cooldown=0.2
   shots.append({"position":hero,"direction":direction,"life":0.6})
 for i in range(shots.size()-1,-1,-1):
  shots[i].position+=shots[i].direction*280*delta
  shots[i].life-=delta
  if shots[i].life<=0: shots.remove_at(i)
 queue_redraw()
func _draw() -> void:
 draw_texture_rect(MenuBackdrop.FLOOR,Rect2(Vector2.ZERO,size),false,Color(0.4,0.48,0.58))
 IllustratedNeris.paint(self,clock,controls.move_vector.length()>0.1,"attack" if controls.fire_vector!=Vector2.ZERO else "rest",direction,hero)
 for shot: Dictionary in shots: draw_circle(shot.position,4,Color("b1e6de"))
