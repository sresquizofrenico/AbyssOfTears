class_name GuestRules
extends RefCounted
# Mechanics are adaptations of personality, not claims of canonical powers.
static func fresh() -> Dictionary:
 return {"guest_timer":0.0,"guest_stationary":0.0,"guest_flavor":0,"guest_power":0,"guest_guard":0.5,"guest_clean":0,"guest_reserve":2.0,"guest_heal":0.0,"guest_charging":false,"guest_secret_floor":-1,"guest_artifacts":0}
static func activate(p) -> void:
 match GuestRoster.role(p):
  "performer": p.character_state.guest_timer=0.3
  "tempest":
   p.character_state.bond_dash=0
   p.character_state.guest_flavor=(int(p.character_state.guest_flavor)+1)%3
  "analyst": p.character_state.guest_stationary=1.5
  "seer": p.character_state.guest_power=3
  "automaton": p.character_state.guest_charging=true
  "naturalist": p.character_state.guest_heal=minf(0.25,float(p.character_state.guest_reserve))
static func tick(p, delta: float) -> void:
 var role:=GuestRoster.role(p)
 if role.is_empty(): return
 var s: Dictionary=p.character_state
 s.guest_timer=maxf(0,float(s.guest_timer)-delta)
 s.guest_stationary=minf(3,float(s.guest_stationary)+delta) if p.velocity.length()<15 else 0.0
 p.stats.clear_temporary("guest_identity")
 if role=="tempest" and p.ability_active>0: p.stats.set_temporary("guest_identity",{"attack_interval":-p.stats._attack_interval*0.25})
 if role=="seer" and p.stats.health<p.stats.max_health*0.4: p.stats.set_temporary("guest_identity",{"damage":p.stats._damage*0.1,"defense":-0.1})
 if role=="scholar" and s.guest_stationary>1.5: p.stats.set_temporary("guest_identity",{"defense":0.1})
 if role=="automaton":
  if s.guest_charging and not s.beam_pending:
   s.guest_charging=false
   s.guest_timer=2.0
  if s.guest_timer>0: p.stats.set_temporary("guest_identity",{"speed":-30.0,"attack_interval":0.1})
 if role=="naturalist" and p.ability_active>0 and p.position.distance_to(p.skill_origin)<120 and s.guest_heal>0 and s.guest_reserve>0:
  var amount:=minf(delta*0.1,minf(float(s.guest_heal),p.stats.max_health-p.stats.health))
  s.guest_heal-=amount
  s.guest_reserve-=amount
  p.stats.health+=amount
  if amount>0: p.health_changed.emit(p.stats.health,p.stats.max_health)
static func reduce(p, amount: float, source: String) -> float:
 var role:=GuestRoster.role(p)
 if role=="performer" and p.ability_active>0 and p.character_state.guest_timer>0:
  # A short repositioning window, not invincibility throughout the decoy.
  p.character_state.guest_timer=0
  return amount*0.5
 if role=="tempest" and source=="contact" and p.character_state.guest_guard>0:
  var block:=minf(amount,float(p.character_state.guest_guard))
  p.character_state.guest_guard-=block
  amount-=block
 if role=="naturalist" and source in ["acid","cold"]: amount*=0.75
 return amount
static func packet(p, value: Dictionary) -> Dictionary:
 match GuestRoster.role(p):
  "tempest":
   if p.ability_active>0:
    var element: String=["fire","ice","electric"][int(p.character_state.guest_flavor)]
    if not value.elements.has(element): value.elements.append(element)
  "analyst":
   if p.character_state.guest_stationary>=1.5: value.power*=1.1; value.velocity+=0.12
  "seer":
   if p.ability_active>0 and p.character_state.guest_power>0:
    p.character_state.guest_power-=1
    value.homing=1
    value.mark=1
  "automaton": value.reach+=70; value.push+=12
 return value
static func room(p, clean: bool) -> void:
 match GuestRoster.role(p):
  "tempest": p.character_state.guest_guard=0.5
  "athlete":
   if clean:
    p.character_state.guest_clean+=1
    if int(p.character_state.guest_clean)%5==0:
     p.stats.health=minf(p.stats.max_health,p.stats.health+0.5)
     p.health_changed.emit(p.stats.health,p.stats.max_health)
static func new_room(p) -> void:
 if GuestRoster.role(p)!="explorer" or not is_instance_valid(p.bond_arena): return
 var game=p.bond_arena.game
 if game.dungeon_mode and game.layout.rooms[game.layout.current].kind=="secret" and p.character_state.guest_secret_floor!=game.layout.floor_index:
  p.character_state.guest_secret_floor=game.layout.floor_index
  p.character_state.family_ward=maxf(float(p.character_state.family_ward),0.5)
static func artifact(p, known: bool) -> void:
 if known or GuestRoster.role(p)!="explorer" or p.character_state.guest_artifacts>=3: return
 p.character_state.guest_artifacts+=1
 p.ability_remaining=maxf(0,p.ability_remaining-3.0)
static func pickup_radius(p) -> float:
 return 16.0 if GuestRoster.role(p)=="explorer" and p.ability_active>0 else 0.0
static func heal_bonus(p) -> float:
 return 0.5 if GuestRoster.role(p)=="scholar" else 0.0
