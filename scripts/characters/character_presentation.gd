class_name CharacterPresentation
extends RefCounted

# Public Android always uses the original catalog. Private reference cards are
# developer-only text and excluded from all public exports; no official artwork.
static func private_enabled() -> bool:
 return OS.has_feature("editor") and not OS.has_feature("android") and OS.get_cmdline_user_args().has("--private-reference")

static func entries() -> Array:
 var output: Array=CharacterCatalog.DATA.duplicate(true)
 if not private_enabled(): return output
 var file:=FileAccess.open("res://private/reference_cards.json",FileAccess.READ)
 if not file: return output
 var document=JSON.parse_string(file.get_as_text())
 if not document is Dictionary or not document.get("profiles") is Array: return output
 for card: Dictionary in document.profiles:
  for entry: Dictionary in output:
   if entry.id==card.get("id"):
    entry.name=str(card.reference_name)+" · REFERENCIA PRIVADA"
    entry.story=card.visual_brief
 return output
