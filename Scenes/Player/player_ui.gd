extends CanvasLayer

@onready var label_ammo: Label = $LabelAmmo


func _ready() -> void:
	label_ammo.text = str("Ammo:", str())
