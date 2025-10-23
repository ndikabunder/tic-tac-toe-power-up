extends Panel

func _ready():
	$VBoxContainer/CloseButton.pressed.connect(queue_free)
