extends Panel

@onready var label_name: Label = %LabelName
@onready var player_color: ColorRect = %PlayerColor

var username: String
var color: Color

func _ready() -> void:
	label_name.text = username
	player_color.color = color
