extends "res://scripts/cinematic_shell_v23.gd"


func _localized_text(text: String) -> String:
	var result := super._localized_text(text)
	result = result.replace("TRAINING GRATIS", "GRATIS")
	result = result.replace("Kein Geld · Müdigkeit limitiert", "Kostenlos · Müdigkeit limitiert")
	return result
