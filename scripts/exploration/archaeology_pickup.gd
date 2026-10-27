class_name ArchaeologyPickup
extends RelicPickup
var cached_icon: Texture2D

# Reuse the exact touch, proximity, chest and single-claim transaction of relics.
func valid_reward() -> bool:
 return data.get("reward_kind","")=="artifact" and not ArchaeologyCatalog.definition(str(data.get("id",""))).is_empty()

func icon() -> Texture2D:
 if cached_icon!=null: return cached_icon
 var entry:=ArchaeologyCatalog.definition(str(data.get("id","")))
 if not entry.is_empty(): cached_icon=load(entry.icon) as Texture2D
 return cached_icon

func display_name() -> String:
 return ArchaeologyCatalog.definition(str(data.get("id",""))).get("name","Vestigio desconocido")

func description() -> String:
 return ArchaeologyCatalog.definition(str(data.get("id",""))).get("summary","")

func rarity_label() -> String:
 var entry:=ArchaeologyCatalog.definition(str(data.get("id","")))
 return ArchaeologyCatalog.RARITIES[int(entry.rarity)] if not entry.is_empty() else ""
