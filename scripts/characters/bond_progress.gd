class_name BondProgress
extends RefCounted
const SETS := ["machines","components","clean_contaminated","prediction","theater","races","circuits","tactics","weaknesses","endurance","fragments","future_clean"]
const FLAGS := ["universal","future_boss","future_final","no_heal","family_done","engineering_done"]
static func fresh() -> Dictionary:
 var result: Dictionary={"antidotes":0,"sets":{}}
 for key: String in SETS: result.sets[key]=[]
 for key: String in FLAGS: result[key]=false
 return result
static func valid_id(category: String, id: String) -> bool:
 if category=="components": return id in ["c0","c1","c2","c3","c4","c5"]
 if category=="machines": return id in ["lift","gate","generator","station"]
 if category=="fragments": return id in ["t0","t1","t2","t3","t4"]
 if category=="weaknesses":
  for entry: Dictionary in EnemyCatalog.DATA:
   if entry.id==id: return true
  return false
 if category in ["clean_contaminated","prediction","theater","races"]: return id in ["0","1","2"]
 if category=="future_clean": return id in ["0","1","2","3"]
 if category in ["circuits","tactics","endurance"]: return id in ["0","1","2","3","4"]
 return false
static func validate(value: Variant) -> Dictionary:
 if not value is Dictionary: return {}
 var clean:=fresh()
 for key: String in FLAGS:
  if not value.get(key,false) is bool: return {}
  clean[key]=value.get(key,false)
 var count: Variant=value.get("antidotes",0)
 if not (count is int or count is float) or not is_finite(float(count)) or count<0: return {}
 clean.antidotes=clampi(int(count),0,100000)
 var sets: Variant=value.get("sets",{})
 if not sets is Dictionary: return {}
 for key: String in SETS:
  var entries: Variant=sets.get(key,[])
  if not entries is Array or entries.size()>64: return {}
  for id: Variant in entries:
   if not id is String: return {}
   if valid_id(key,id) and not clean.sets[key].has(id): clean.sets[key].append(id)
 return clean
static func requirements(id: String, data: Dictionary) -> Array[Dictionary]:
 var sets: Dictionary=data.bonds.sets
 match id:
  "lyra": return [{"label":"Mapas diferentes completos","current":data.journal.maps.size(),"target":3},{"label":"Rutas secretas","current":data.journal.secrets.size(),"target":5},{"label":"Vestigios arqueológicos","current":data.journal.artifacts.size(),"target":10}]
  "kairon": return [{"label":"Máquinas reparadas","current":sets.machines.size(),"target":4},{"label":"Componentes diferentes","current":sets.components.size(),"target":6},{"label":"Sala de ingeniería","current":int(data.bonds.engineering_done),"target":1}]
  "nami": return [{"label":"Criaturas observadas","current":data.journal.creatures.size(),"target":12},{"label":"Antídotos preparados","current":data.bonds.antidotes,"target":5},{"label":"Salas contaminadas sin daño ambiental","current":sets.clean_contaminated.size(),"target":3}]
  "yura": return [{"label":"Fragmentos temporales","current":sets.fragments.size(),"target":5},{"label":"Acertijos de predicción","current":sets.prediction.size(),"target":3},{"label":"Encuentros temporales sin daño","current":sets.future_clean.size(),"target":4},{"label":"Jefe de patrones alterados","current":int(data.bonds.future_boss),"target":1},{"label":"Prueba final de predicción","current":int(data.bonds.future_final),"target":1}]
  "aria": return [{"label":"Teatros de los Ecos","current":sets.theater.size(),"target":3}]
  "beren": return [{"label":"Carreras diferentes","current":sets.races.size(),"target":3}]
  "celine": return [{"label":"Pruebas tácticas","current":sets.tactics.size(),"target":5},{"label":"Debilidades analizadas","current":sets.weaknesses.size(),"target":10}]
  "dalia": return [{"label":"Circuitos sin caídas","current":sets.circuits.size(),"target":5}]
  "elora": return [{"label":"Pruebas de resistencia","current":sets.endurance.size(),"target":5},{"label":"Encuentro sin curación","current":int(data.bonds.no_heal),"target":1}]
 return []

static func weakness(id: String) -> String:
 var tips: Array=["Mantén distancia: solo persigue.","Usa cobertura y muévete lateralmente al disparo.","Cambia de eje durante su carrera.","Evita que el grupo te rodee.","Sale de su línea anunciada.","Las columnas no detienen su persecución: busca espacio abierto.","Ataca por detrás: la coraza frontal reduce el daño.","Evita el ácido; espera a que desaparezca.","No permitas que sus muros cierren tu ruta.","Conserva espacio ante sus cambios de dirección.","Ataca al invocador antes de que acumule criaturas.","Cruza entre sus direcciones de disparo.","Sigue las señales de ataque durante la oscuridad.","Abandona la posición marcada antes de su salto.","Al derrotarlo, aléjate del círculo de explosión.","La copia es débil y no puede volver a duplicarse.","Evita la zona de maldición para conservar velocidad.","Busca los espacios entre las ráfagas circulares.","Conserva distancia para los dos fragmentos al derrotarlo.","Sal del círculo de relámpago antes de que se active."]
 for i in range(EnemyCatalog.DATA.size()):
  if EnemyCatalog.DATA[i].id==id: return tips[i]
 return "Sin observaciones suficientes"
