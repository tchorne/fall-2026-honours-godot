extends Node

var logMessages: Array[LoggedMessage] = []

func get_text() -> String:
	return "\n".join(logMessages.map(func (x): return str(x)))
	
func trace(message: String):
	var lm := LoggedMessage.new(Severity.TRACE, message)
	
	logMessages.push_back(lm)
	print_rich("[color=gray]%s[/color]" % [message])

func info(message: String):
	var lm := LoggedMessage.new(Severity.INFO, message)
	logMessages.push_back(lm)
	print(lm)
	

func warning(message: String):
	logMessages.push_back(LoggedMessage.new(Severity.WARNING, message))

func error(message: String):
	logMessages.push_back(LoggedMessage.new(Severity.ERROR, message))
	print_rich("[color=red]%s[/color]" % [message])
	print_stack()

enum Severity {
	TRACE,
	INFO,
	WARNING,
	ERROR,
	CRITICAL,
}

class LoggedMessage:
	var severity := Severity.TRACE
	var message := ""
	
	func _to_string() -> String:
		return "%s: %s" % [severity, message]
	
	func _init(s: Severity, m: String) -> void:
		severity = s
		message = m
		
