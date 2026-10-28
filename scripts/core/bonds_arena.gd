class_name BondsArena
extends Node2D
var game
var mode: String=""
var variant:=0
var stage:=0
var running:=false
var timer:=0.0
var age:=0.0
var failed:=false
var finished:=false
var clean:=true
var env_clean:=true
var healed:=false
var last_health:=0.0
var solved:=false
var crafted:=0
var used_antidotes:=0
var antidote_time:=0.0
var checkpoint:=0
var falls:=0
var core:=10.0
var stations: Array[Dictionary]=[]
var checkpoints: Array[Vector2]=[]
var fields: Array[Dictionary]=[]
var hazard_clock:=0.0
var selected_station: Dictionary={}
var panel: PanelContainer
var caption: Label
var action: Button
var room_origin:=Vector2.ZERO
var observation_clock:=0.0
var family_clock:=0.0
var family_textures: Array[Texture2D]=[]
var theater_reward: Dictionary={}
var gate_body: StaticBody2D
var gate_open:=false
const COMPONENTS := ["c0","c1","c2","c3","c4","c5","c0","c1"]
const MACHINES := ["lift","gate","generator","station"]
const RECIPES := [["c0","c1"],["c2","c3"],["c4","c5"],["c0","c1"]]
const SYMBOLS := ["SOL","LUNA","RAÍZ"]

func _ready() -> void:
 panel=PanelContainer.new()
 panel.position=Vector2(game.ui.size.x*0.5-215,405)
 panel.size=Vector2(430,120)
 var style:=StyleBoxFlat.new()
 style.bg_color=Color(0.06,0.13,0.19,0.96)
 style.set_content_margin_all(10)
 style.border_color=Color("90b8b4")
 style.set_border_width_all(1)
 panel.add_theme_stylebox_override("panel",style)
 var box:=VBoxContainer.new()
 panel.add_child(box)
 caption=Label.new()
 caption.custom_minimum_size=Vector2(408,44)
 caption.add_theme_font_size_override("font_size",15)
 caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 caption.max_lines_visible=2
 box.add_child(caption)
 action=AbyssTouchButton.new()
 action.custom_minimum_size=Vector2(400,48)
 action.add_theme_font_size_override("font_size",18)
 action.pressed.connect(interact)
 box.add_child(action)
 game.ui.add_child(panel)
 panel.hide()

func setup(value: String, index: int) -> void:
 mode=value
 variant=index
 running=true
 last_health=game.player.stats.health
 timer=40.0 if mode=="race" else 60.0 if mode=="circuit" else 20.0 if mode=="endurance" else 10.0 if mode=="ecology" else 0.0
 if mode=="engineering":
  add_gate()
  for i in range(4): stations.append({"kind":"machine","id":MACHINES[i],"recipe":RECIPES[i],"point":game.safe_point(Vector2(180 if i%2==0 else 780,170 if i<2 else 375)),"used":false})
  for i in range(8): spawn_resource("component",COMPONENTS[i],Vector2(220+(i%4)*170,245+(i/4)*85))
 elif mode=="ecology":
  stations.append({"kind":"antidote","point":game.safe_point(Vector2(480,190)),"used":false})
  for i in range(2): spawn_resource("sample","biomass",Vector2(270+i*420,285))
  for i in range(2): game.spawn_enemy(10+variant*2+i,Vector2(250+i*430,150))
 elif mode=="future": setup_future()
 elif mode=="theater":
  stations.append({"kind":"puzzle","point":Vector2(480,270),"used":false})
 elif mode in ["race","circuit"]:
  var path: Array[Vector2]=[Vector2(160,130),Vector2(480,115),Vector2(790,130),Vector2(800,410),Vector2(480,430),Vector2(150,405)]
  for i in range(path.size()): checkpoints.append(game.safe_point(path[posmod(i+variant,path.size())]))
 elif mode=="tactics":
  stations.append({"kind":"puzzle","point":Vector2(480,270),"used":false})
  stations.append({"kind":"analysis","point":Vector2(210,375),"used":false})
  for i in range(2): game.spawn_enemy(variant*2+i,Vector2(250+i*430,150))
 elif mode=="endurance":
  for i in range(3): game.spawn_enemy((variant*3+i)%20,Vector2(200+i*260,150))
 elif mode=="family":
  for id in BondCatalog.SISTERS: family_textures.append(CharacterCatalog.texture(id))
  for i in range(3): game.spawn_enemy([6,9,18][i],Vector2(200+i*260,150),false,"elite" if i==0 else "normal")
 observe_species()

func setup_field() -> void:
 if not game.dungeon_mode: return
 var room: Dictionary=game.layout.rooms[game.layout.current]
 var floor_index: int=game.layout.floor_index
 if room.kind!="special" and not (floor_index==2 and room.kind=="secret"): return
 mode="field"
 last_health=game.player.stats.health
 var machine_index: int=3 if room.kind=="secret" else floor_index
 if machine_index==1 and not room.get("machine_done",false): add_gate()
 stations.append({"kind":"machine","id":MACHINES[machine_index],"recipe":RECIPES[machine_index],"point":game.safe_point(Vector2(760,190)),"used":room.get("machine_done",false)})
 stations.append({"kind":"antidote","point":game.safe_point(Vector2(210,375)),"used":false})
 if not room.get("bond_resources",false):
  room.bond_resources=true
  for i in range(2):
   var data: Dictionary={"id":"c%d" % ((floor_index*2+i)%6),"reward_kind":"component","position":Vector2(240+i*460,150),"chest":false,"collected":false}
   game.room_pickups.append(data)
   game.spawn_pickup(data)
  if floor_index==1:
   for i in range(2):
    var data: Dictionary={"id":"biomass","reward_kind":"sample","position":Vector2(300+i*360,360),"chest":false,"collected":false}
    game.room_pickups.append(data)
    game.spawn_pickup(data)

func setup_future() -> void:
 solved=false
 age=0
 clean=true
 env_clean=true
 if stage<3:
  stations=[{"kind":"puzzle","point":Vector2(480,270),"used":false}]
  for i in range(2): game.spawn_enemy([1,4,11][stage],Vector2(250+i*430,150))
  for i in range(2):
   var number:=stage*2+i
   if number<5: spawn_resource("fragment","t%d" % number,Vector2(250+i*430,350))
 else:
  stations.clear()
  if stage!=3: stations.append({"kind":"puzzle","point":Vector2(480,360),"used":false})
  game.spawn_guardian(2)
  var guardian: TideWarden=game.enemies.back()
  guardian.sequence.assign([0,2,1,2,0,1] if stage==3 else [1,0,2,0,1,2])
  guardian.pattern=guardian.sequence[0]
  guardian.display_name="Oráculo de los instantes"
  game.boss_name.text=guardian.display_name+" · Variante de desafío"
 observe_species()

func spawn_resource(kind: String, id: String, point: Vector2) -> void:
 game.spawn_pickup({"id":id,"reward_kind":kind,"position":point,"chest":false,"collected":false})

func observe_species() -> void:
 var ids: Array=[]
 for enemy in game.enemies:
  if not enemy is TideWarden and not ids.has(enemy.definition.id): ids.append(enemy.definition.id)
 if not ids.is_empty(): game.progress.discover({"creatures":ids})

func collect(pickup: RelicPickup) -> bool:
 if game.lab_mode or (not game.dungeon_mode and not game.trial_kind.begins_with("bonds:")): return false
 var p=game.player
 var kind: String=pickup.data.reward_kind
 var id: String=pickup.data.id
 if kind=="component":
  if not game.progress.data.bonds.sets.components.has(id) and not game.progress.record_bond("components",id): return false
  p.character_state.component_stock[id]=mini(12,int(p.character_state.component_stock.get(id,0))+1)
 elif kind=="sample": p.character_state.samples=mini(8,int(p.character_state.samples)+1)
 elif kind=="fragment":
  if not game.progress.data.bonds.sets.fragments.has(id) and not game.progress.record_bond("fragments",id): return false
 else: return false
 game.show_notice(pickup.display_name(),pickup.icon())
 p.pickup_pose=1.0
 return true

func note_health(current: float) -> void:
 if running and current>last_health+0.001: healed=true
 last_health=current
func note_damage(source: String) -> void:
 clean=false
 if source in ["acid","lightning","heat","cold"]: env_clean=false
func environment_protected() -> bool:
 return antidote_time>0

func tick(delta: float) -> void:
 if game.state!="playing" or not is_instance_valid(game.player): return
 var p=game.player
 p.character_state.ward_near=false
 age+=delta
 antidote_time=maxf(0,antidote_time-delta)
 p.character_state.antidote_time=antidote_time
 if running and not failed: timer=maxf(0,timer-delta)
 tick_abilities(delta)
 for i in range(fields.size()-1,-1,-1):
  fields[i].life-=delta
  fields[i].tick-=delta
  if fields[i].life<=0: fields.remove_at(i); continue
  if fields[i].kind=="flame" and fields[i].tick<=0:
   fields[i].tick=0.4
   for enemy in game.enemies:
    if not enemy.dead and enemy.position.distance_to(fields[i].point)<42: enemy.burning=maxf(enemy.burning,1.4)
  if fields[i].kind=="ward" and p.position.distance_to(fields[i].point)<65 and p.character_state.field_budget>0:
   p.character_state.ward_near=true
 if running and not finished and not failed:
  if mode in ["race","circuit"]:
   if checkpoint<checkpoints.size() and p.position.distance_to(checkpoints[checkpoint])<32: checkpoint+=1
   if mode=="circuit" and p.position.distance_to(Vector2(480,274))<48:
    falls+=1
    failed=true
    p.position=checkpoints[maxi(0,checkpoint-1)]
   if timer<=0: failed=true
  if mode=="ecology":
   hazard_clock-=delta
   if hazard_clock<=0:
    hazard_clock=2.4
    game.spawn_hazard(Vector2(380 if int(age)%2==0 else 580,280),["acid","lightning","cold"][variant])
  if mode=="endurance":
   for enemy in game.enemies:
    if enemy.position.distance_to(Vector2(480,274))<80: core=maxf(0,core-delta*0.7)
   if core<=0: failed=true
  if mode=="family":
   family_clock-=delta
   if family_clock<=0 and not game.enemies.is_empty():
    family_clock=1.5
    for i in range(5):
     var origin:=Vector2(150+i*165,130)
     var target=game.enemies[i%game.enemies.size()]
     var before: int=game.bullets.size()
     game.spawn_bullet(origin,(target.position-origin).normalized(),300,0.18,600,false)
     if game.bullets.size()>before: game.bullets.back().generation=1
 refresh_panel()
 queue_redraw()

func tick_abilities(delta: float) -> void:
 var p=game.player
 var s: Dictionary=p.character_state
 if p.character_id=="kairon" and s.beam_pending and p.ability_age>=0.45:
  s.beam_pending=false
  var end: Vector2=p.position+p.facing*700
  for step in range(1,141):
   var at: Vector2=p.position+p.facing*step*5
   if game.projectile_blocked(at): end=at; break
   var blocked:=false
   for prop in game.props:
    if is_instance_valid(prop) and prop.data.kind=="barrel" and not prop.data.get("used",false) and prop.position.distance_to(at)<20:
     prop.take_damage(p.stats.damage*2.4)
     if not prop.data.get("used",false): blocked=true
     break
   if blocked: end=at; break
  var hits:=0
  for enemy in game.enemies.duplicate():
   if not is_instance_valid(enemy) or enemy.dead: continue
   if Geometry2D.get_closest_point_to_segment(enemy.position,p.position,end).distance_to(enemy.position)<enemy.hit_radius+5:
    enemy.take_damage(p.stats.damage*2.4,p.facing)
    hits+=1
    if hits>=4: break
  if game.sparks.size()<8: game.sparks.append({"from":p.position,"to":end,"life":0.18})
 if p.character_id=="nami" and p.ability_active>0:
  for enemy in game.enemies:
   if not enemy.dead and enemy.position.distance_to(p.skill_origin)<120: enemy.slowed=maxf(enemy.slowed,0.4)
 if p.character_id=="beren" and s.bond_dash>0:
  s.trail_time-=delta
  if s.trail_time<=0 and fields.size()<8:
   s.trail_time=0.08
   fields.append({"point":p.position,"life":2.0,"tick":0.0,"kind":"flame"})
 if p.character_id=="dalia" and p.ability_active<=0 and s.field_pending:
  s.field_pending=false
  fields.append({"point":p.position,"life":3.6 if NineBonds.resonance(p) else 3.0,"tick":0.0,"kind":"ward"})
 if p.character_id=="elora" and s.counter_pending and p.ability_active<=0:
  s.counter_pending=false
  if s.blocked>0:
   for enemy in game.enemies.duplicate():
    if is_instance_valid(enemy) and not enemy.dead and enemy.position.distance_to(p.position)<150: enemy.take_damage(p.stats.damage*minf(1.5,float(s.blocked)*0.5))

func layout_panel(with_action: bool) -> void:
 panel.position=Vector2(game.ui.size.x*0.5-215,405 if with_action else 455)
 panel.custom_minimum_size=Vector2(430,120 if with_action else 70)
 panel.size=panel.custom_minimum_size

func refresh_panel() -> void:
 selected_station={}
 if failed:
  caption.text="Prueba fallida · vuelve a intentarlo"
  action.text="REINTENTAR"
  layout_panel(true)
  action.show()
  panel.show()
  game.sync_control_exclusions()
  return
 var p=game.player
 for station in stations:
  if station.get("used",false): continue
  if p.position.distance_to(station.point)<90: selected_station=station; break
 panel.position=Vector2(game.ui.size.x*0.5-215,405)
 if not selected_station.is_empty():
  var kind: String=selected_station.kind
  caption.text="Mecanismo antiguo · requiere %d componente(s)" % (1 if p.character_id=="kairon" else 2) if kind=="machine" else "Biomasa: %d · antídotos: %d" % [p.character_state.samples,p.character_state.antidotes] if kind=="antidote" else "Observa el patrón y elige una respuesta" if kind=="puzzle" else "Analiza criaturas observadas y sus comportamientos"
  action.text="REPARAR" if kind=="machine" else "PREPARAR / USAR ANTÍDOTO" if kind=="antidote" else "RESOLVER" if kind=="puzzle" else "ANALIZAR"
  action.show()
  layout_panel(true)
  panel.show()
 elif running:
  caption.text=("Prueba fallida · vuelve a intentarlo" if failed else "Tiempo %.0f · puntos %d/%d" % [timer,checkpoint,checkpoints.size()] if mode in ["race","circuit"] else "Protege el núcleo · %.0f s · energía %.1f" % [timer,core] if mode=="endurance" else "Taller · máquinas %d/4" % stations.filter(func(s): return s.get("used",false)).size() if mode=="engineering" else "Supera el encuentro · antidotos %d" % p.character_state.antidotes)
  action.text="REINTENTAR"
  action.visible=failed
  layout_panel(action.visible)
  panel.show()
 else: panel.hide()
 game.sync_control_exclusions()

func interact() -> void:
 if game.state!="playing": return
 if failed:
  game.start_bond_challenge(mode,variant)
  return
 if selected_station.is_empty(): return
 var station: Dictionary=selected_station
 var p=game.player
 match station.kind:
  "machine":
   var recipe: Array=station.recipe.duplicate()
   if p.character_id=="kairon": recipe.resize(1)
   for id in recipe:
    if int(p.character_state.component_stock.get(id,0))<1:
     game.show_notice("Necesitas: "+", ".join(recipe),BondPickup.ICONS.component)
     return
   if not game.progress.data.bonds.sets.machines.has(station.id) and not game.progress.record_bond("machines",station.id): return
   station.used=true
   apply_machine(station.id)
   for id in recipe: p.character_state.component_stock[id]-=1
   if mode=="field": game.layout.rooms[game.layout.current].machine_done=true
   game.show_notice("Máquina reparada",BondPickup.ICONS.component)
  "antidote":
   if p.character_state.antidotes>0:
    p.character_state.antidotes-=1
    antidote_time=6.0
    p.character_state.antidote_time=6.0
    used_antidotes+=1
    game.show_notice("Antídoto activo · 6 s",BondPickup.ICONS.sample)
   else:
    var cost:=1 if p.character_id=="nami" else 2
    if p.character_state.samples<cost:
     game.show_notice("Necesitas %d muestras" % cost,BondPickup.ICONS.sample)
     return
    var token: String="%d:%s:%d:%d" % [game.progress.data.serial,mode,stage,crafted]
    if mode=="field": token="%d:field:%d:%d:%d" % [game.run_serial,game.layout.floor_index,game.layout.current,crafted]
    if not game.progress.record_bond("antidote","",token): return
    p.character_state.samples-=cost
    p.character_state.antidotes=mini(3,int(p.character_state.antidotes)+1)
    crafted+=1
    game.show_notice("Antídoto preparado · pulsa de nuevo para usar",BondPickup.ICONS.sample)
  "puzzle": show_puzzle()
  "analysis": game.show_bond_analysis()
 game.queue_checkpoint()

func show_puzzle() -> void:
 game.set_world_active(false)
 game.state="bond_puzzle"
 var index: int=stage if mode=="future" else variant
 var answer:=posmod(index+1,3)
 var prompt: String=["Ciclo: SOL → LUNA → RAÍZ → SOL → ¿?","Alternancia: RAÍZ → SOL → RAÍZ → SOL → ¿?","Espejo: SOL → LUNA → RAÍZ → LUNA → ¿?"][index%3]
 if mode=="future" and stage==4:
  answer=0
  prompt="Ciclo con salto de dos: SOL → RAÍZ → LUNA → ¿?"
 if mode=="theater": prompt="¿Qué sello brillaba en dorado al entrar? Los otros dos son reflejos."
 if mode=="tactics":
  var questions: Array=["El perseguidor no dispara: ¿qué conserva una ruta de escape?","Un enemigo veloz cambia de rumbo: ¿qué ayuda a esquivarlo?","El centinela apunta antes de disparar: ¿qué aprovechas?","El blindado resiste de frente: ¿dónde atacas?","La baba deja ácido: ¿qué zona es segura?"]
  var choices: Array=[["Distancia","Quedarse quieto","Acercarse"],["Un giro lateral","Correr hacia él","Ignorar el aviso"],["Cobertura","Contacto","Esperar inmóvil"],["Su espalda","Su frente","Su armadura"],["Suelo limpio","Charco verde","Centro del ácido"]]
  var box=game.menu("Prueba táctica",questions[index])
  for i in range(3): box.add_child(game.button(choices[index][i],func(): answer_puzzle(i==0)))
  return
 var box=game.menu("Teatro de los Ecos" if mode=="theater" else "Predicción temporal",prompt)
 for i in range(3): box.add_child(game.button(SYMBOLS[i],func(): answer_puzzle(i==answer)))
 if mode=="theater": box.add_child(game.button("Repetir la pista",func(): age=0; game.resume_game()))

func answer_puzzle(correct: bool) -> void:
 if game.state!="bond_puzzle": return
 game.resume_game()
 if not correct:
  game.show_notice("No coincide. Revisa la pista y vuelve a probar",BondPickup.ICONS.fragment)
  return
 solved=true
 for station in stations:
  if station.kind=="puzzle": station.used=true
 if mode=="future" and stage<3: game.progress.record_bond("prediction",str(stage))
 if mode=="theater":
  game.spawn_enemy(9+variant,Vector2(480,150))
  if variant==1:
   theater_reward={"id":"boots","position":Vector2(480,270),"chest":true,"collected":false}
   game.spawn_pickup(theater_reward)
  elif variant==2: game.show_notice("La salida auténtica brilla. Acércate tras vencer al enemigo",BondPickup.ICONS.fragment)
 game.show_notice("Patrón resuelto",BondPickup.ICONS.fragment)

func resolve() -> void:
 if not running or failed or finished: return
 for hazard in game.hazards:
  if is_instance_valid(hazard) and hazard.kind=="explosion" and hazard.age<1.15: return
 var done:=false
 match mode:
  "engineering": done=stations.all(func(s): return s.get("used",false))
  "ecology": done=timer<=0 and used_antidotes>0
  "theater":
   done=solved
   if variant==1: done=done and theater_reward.get("collected",false)
   elif variant==2: done=done and game.player.position.distance_to(Vector2(260+((variant+1)%3)*220,190))<36
  "tactics": done=solved
  "race","circuit": done=checkpoint==checkpoints.size() and falls==0
  "endurance": done=timer<=0 and core>0
  "family": done=true
  "future":
   if stage<3 and not solved: return
   if stage<3:
    for i in range(stage*2,mini(5,stage*2+2)):
     if not game.progress.data.bonds.sets.fragments.has("t%d" % i): return
   if stage==4 and not solved: return
   if stage<4 and clean: game.progress.record_bond("future_clean",str(stage))
   if stage==3: game.progress.record_bond("future_boss","done")
   if stage<4:
    stage+=1
    for bullet in game.bullets:
     if is_instance_valid(bullet): bullet.expire()
    game.bullets.clear()
    for pickup in game.pickups:
     if is_instance_valid(pickup): pickup.queue_free()
    game.pickups.clear()
    game.player.position=Vector2(480,390)
    setup_future()
    return
   game.progress.record_bond("future_final","done")
   done=true
 if not done: return
 finished=true
 match mode:
  "engineering": game.progress.record_bond("engineering_done","done")
  "ecology":
   if env_clean: game.progress.record_bond("clean_contaminated",str(variant))
  "theater": game.progress.record_bond("theater",str(variant))
  "race": game.progress.record_bond("races",str(variant))
  "circuit": game.progress.record_bond("circuits",str(variant))
  "tactics": game.progress.record_bond("tactics",str(variant))
  "endurance":
   game.progress.record_bond("endurance",str(variant))
   if not healed: game.progress.record_bond("no_heal","done")
  "family": game.progress.record_bond("family_done","done")
 NineBonds.room(game.player,clean,mode in ["race","circuit"])
 game.finish(true)

func add_gate() -> void:
 gate_body=StaticBody2D.new()
 gate_body.position=Vector2(480,274)
 gate_body.collision_layer=1
 gate_body.collision_mask=0
 var collider:=CollisionShape2D.new()
 var shape:=RectangleShape2D.new()
 shape.size=Vector2(120,18)
 collider.shape=shape
 gate_body.add_child(collider)
 add_child(gate_body)

func blocks(point: Vector2) -> bool:
 return is_instance_valid(gate_body) and not gate_open and Rect2(420,265,120,18).grow(5).has_point(point)

func apply_machine(id: String) -> void:
 match id:
  "lift":
   game.player.position=game.safe_point(Vector2(480,390))
   game.player.immunity=maxf(game.player.immunity,0.3)
  "gate":
   gate_open=true
   if is_instance_valid(gate_body):
    gate_body.collision_layer=0
    gate_body.get_child(0).set_deferred("disabled",true)
   if game.dungeon_mode: game.layout.reveal_secret(); game.dungeon_map.queue_redraw()
  "generator": game.player.ability_remaining=maxf(0,game.player.ability_remaining-8)
  "station": game.player.character_state.samples=mini(8,int(game.player.character_state.samples)+2)

func _draw() -> void:
 if is_instance_valid(gate_body) and not gate_open:
  draw_rect(Rect2(420,265,120,18),Color("496b76"))
  for i in range(6): draw_line(Vector2(426+i*20,266),Vector2(426+i*20,282),Color("c1baa0"),3)
 for station in stations:
  var point: Vector2=station.point
  draw_circle(point,27,Color(0.2,0.5,0.5,0.18))
  draw_arc(point,25,0,TAU,24,Color("647d87") if station.get("used",false) else Color("c8c292"),2)
  draw_texture_rect(BondPickup.ICONS.component if station.kind=="machine" else BondPickup.ICONS.sample if station.kind=="antidote" else BondPickup.ICONS.fragment,Rect2(point-Vector2(18,25),Vector2(36,36)),false)
 for i in range(checkpoints.size()):
  draw_arc(checkpoints[i],24,0,TAU,24,Color("a5dfba") if i==checkpoint else Color("526579"),3 if i==checkpoint else 1)
  draw_string(ThemeDB.fallback_font,checkpoints[i]+Vector2(-4,5),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
 if mode=="theater":
  draw_string(ThemeDB.fallback_font,Vector2(265,115),"MEMORIA: recuerda el sello dorado",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("e1cf9d"))
  for i in range(3):
   var point:=Vector2(260+i*220,190)
   var real: bool=i==(variant+1)%3 and (age<3 or solved)
   draw_circle(point,27,Color("e0c487") if real else Color("40546b"))
   var texture: Texture2D=EnemyArt.TEXTURES[9] if variant==0 else RelicPickup.CHEST if variant==1 else game.DOOR_ART
   draw_texture_rect(texture,Rect2(point-Vector2(18,24),Vector2(36,43)),false,Color.WHITE if real else Color(0.5,0.6,0.8,0.45))
   draw_string(ThemeDB.fallback_font,point+Vector2(-22,48),SYMBOLS[i],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
 if mode=="circuit":
  draw_circle(Vector2(480,274),48,Color("0a1020"))
  draw_arc(Vector2(480,274),50,0,TAU,32,Color("dcae85"),2)
 if mode=="endurance": draw_arc(Vector2(480,274),80,0,TAU,32,Color("b4d8c5"),2)
 if mode=="family":
  for i in range(5):
   var point:=Vector2(150+i*165,130)
   if i<family_textures.size(): BondArt.paint(self,BondCatalog.SISTERS[i],family_textures[i],age,false,"attack",Vector2.DOWN,point,0,0.65,Color(1,1,1,0.6))
   draw_arc(point,16,age,age+PI,16,Color("bd9fcb"),2)
 for field in fields: draw_arc(field.point,42 if field.kind=="flame" else 65,0,TAU,24,Color("e5a575") if field.kind=="flame" else Color("b5dca9"),2)
 var p=game.player
 if not is_instance_valid(p): return
 if p.character_id=="nami":
  for prop in game.props:
   if is_instance_valid(prop) and prop.data.kind=="trap": draw_arc(prop.position,29,0,TAU,20,Color("a9d49b"),2)
 if p.character_id=="nami" and p.ability_active>0: draw_arc(p.skill_origin,120,0,TAU,32,Color(0.6,0.85,0.6,0.6),2)
 if p.character_id=="aria" and p.ability_active>0: IllustratedNeris.paint(self,p.clock,false,"rest",p.facing,p.skill_origin,0,1,Color(0.6,0.7,1,0.4),p.body_texture)
 if p.character_id=="lyra" and p.ability_active>0 and game.dungeon_mode and game.layout.secret_room>=0:
  var cell: Vector2i=game.layout.rooms[game.layout.secret_room].cell-game.layout.rooms[game.layout.current].cell
  var direction:=Vector2(cell).normalized()
  draw_line(p.position,p.position+direction*85,Color("c4dcb4"),2)
  for room: Dictionary in game.layout.rooms:
   if room.kind=="treasure" and not room.visited:
    var treasure_direction:=Vector2(room.cell-game.layout.rooms[game.layout.current].cell).normalized()
    draw_line(p.position,p.position+treasure_direction*65,Color("d8c09a"),1.5)
    break
 if p.character_id=="yura" and p.ability_active>0:
  var count:=0
  for enemy in game.enemies:
   if count>=4: break
   if enemy.attack_timer>1.4: continue
   count+=1
   var direction: Vector2=enemy.aim if enemy is TideWarden and enemy.announced else (p.position-enemy.position).normalized()
   draw_line(enemy.position,enemy.position+direction*140,Color(0.9,0.5,0.7,0.7 if enemy.telegraph else 0.3),2)
   draw_arc(enemy.position,34,0,TAU,24,Color("e9a2c4"),1)

func _exit_tree() -> void:
 if is_instance_valid(panel): panel.queue_free()
