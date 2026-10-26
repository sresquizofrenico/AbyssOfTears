class_name MenuIntro
extends RefCounted

const DURATION := 6.5
var elapsed := 0.0
var active := true

func advance(delta: float) -> void:
 if not active: return
 elapsed = minf(DURATION,elapsed+maxf(0,delta))
 active = elapsed < DURATION

func skip() -> void:
 elapsed = DURATION
 active = false

func phase() -> String:
 if elapsed < 1.0: return "light"
 if elapsed < 2.7: return "enter"
 if elapsed < 3.6: return "look"
 if elapsed < 4.4: return "attack"
 if elapsed < 5.2: return "dissolve"
 if active: return "reveal"
 return "ambient"

func title_alpha() -> float:
 return smoothstep(4.9,5.7,elapsed)

func buttons_alpha() -> float:
 return smoothstep(5.6,DURATION,elapsed)

func darkness() -> float:
 return 1.0-smoothstep(0.0,1.3,elapsed)
