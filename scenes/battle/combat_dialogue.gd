extends RichTextLabel

func _ready():
	SignalBus.display_message.connect(display_text)


func display_text(text: String):
	self.text = text
