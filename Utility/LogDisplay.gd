extends Label3D

func _process(delta: float) -> void:
	text = LoggerGlobal.get_text()
	
func _ready() -> void:
	LoggerGlobal.info("Ready!")
