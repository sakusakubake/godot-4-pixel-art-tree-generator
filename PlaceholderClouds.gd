extends Sprite2D

var clouds_noise

func _ready():
	clouds_noise = texture.noise


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	clouds_noise.offset.x -= 2.0 * delta
