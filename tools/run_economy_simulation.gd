extends SceneTree
const Simulator = preload("res://tools/economy_simulation.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var report: Dictionary={"version":"0.7.0","assumptions":"Perfect three-floor clears; seeded production room, loot, shop and price tables. Keys required for secrets/chests; no purchased keys, damage, deaths or healing expenditure. Not phone gameplay telemetry.","greedy":Simulator.run(2000),"save_for_rare":Simulator.run(2000,"save_for_rare")}
 var file:=FileAccess.open("user://economy-simulation.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "))
 file.close()
 print(JSON.stringify(report,"  "))
 print("SIMULATION_REPORT ",ProjectSettings.globalize_path("user://economy-simulation.json"))
 quit()
