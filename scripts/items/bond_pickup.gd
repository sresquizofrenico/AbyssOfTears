class_name BondPickup
extends RelicPickup
const ICONS={"component":preload("res://assets/bonds/component.svg"),"sample":preload("res://assets/bonds/sample.svg"),"fragment":preload("res://assets/bonds/fragment.svg")}
func valid_reward() -> bool:
 var kind: String=data.get("reward_kind","")
 return (kind=="component" and BondProgress.valid_id("components",str(data.get("id","")))) or (kind=="fragment" and BondProgress.valid_id("fragments",str(data.get("id","")))) or (kind=="sample" and data.get("id")=="biomass")
func icon() -> Texture2D: return ICONS.get(data.get("reward_kind",""))
func display_name() -> String:
 if data.get("reward_kind")=="component": return "Componente "+str(int(str(data.id).substr(1))+1)
 return "Muestra de biomasa" if data.get("reward_kind")=="sample" else "Fragmento temporal"
func description() -> String:
 return "Recurso de exploración. Se recoge una sola vez y se utiliza en los talleres del vínculo."
