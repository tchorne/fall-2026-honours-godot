extends Label3D

@export var stats := false

func _process(_delta: float) -> void:
	text = LoggerGlobal.get_text() if not stats else LoggerGlobal.get_stats()
	
func _ready() -> void:
	LoggerGlobal.info("Ready!")
