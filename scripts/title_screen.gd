class_name TitleScreen
extends CanvasLayer

# Launch flow: intro cinematic (assets/ui/intro.ogv, skippable) -> title card
# over the key art -> DEPLOY. The game tree is paused until deploy.

signal deployed

const INTRO := "res://assets/ui/intro.ogv"
const KEY_ART := "res://assets/ui/key_art.jpg"

var _video: VideoStreamPlayer
var _title: Control
var _prompt: Label
var _phase := "intro"   # intro | title | done
var _t := 0.0

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_build_title()
	if ResourceLoader.exists(INTRO):
		_video = VideoStreamPlayer.new()
		_video.stream = load(INTRO)
		_video.expand = true
		_video.set_anchors_preset(Control.PRESET_FULL_RECT)
		_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_video)
		_video.finished.connect(_show_title)
		var skip := _label("tap / any key to skip", 16, Color(1, 1, 1, 0.55))
		skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		skip.offset_left = -260
		skip.offset_top = -44
		_video.add_child(skip)
		_video.play()
	else:
		_show_title()

func _label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _build_title() -> void:
	_title = Control.new()
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.visible = false
	add_child(_title)
	if ResourceLoader.exists(KEY_ART):
		var art := TextureRect.new()
		art.texture = load(KEY_ART)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_title.add_child(art)
	# darken the left side so the title reads over the art
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	shade.anchor_right = 0.5
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_child(shade)
	var box := VBoxContainer.new()
	box.position = Vector2(60, 70)
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_child(box)
	box.add_child(_label("BOMBIES", 76, Color(0.92, 0.88, 0.2)))
	box.add_child(_label("DEAD ZONE", 46, Color(1.0, 0.3, 0.2)))
	var sub := _label("Hold the flooded garage. Three rounds. They change while you fight.", 18, Color(0.9, 0.9, 0.85))
	sub.custom_minimum_size = Vector2(520, 0)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(sub)
	_prompt = _label("", 26, Color(0.95, 0.85, 0.3))
	_prompt.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_prompt.offset_left = 60
	_prompt.offset_top = -90
	_title.add_child(_prompt)

func _show_title() -> void:
	if _phase != "intro":
		return
	_phase = "title"
	_t = 0.0
	if _video != null:
		_video.stop()
		_video.visible = false
	_title.visible = true
	_title.modulate.a = 0.0
	create_tween().tween_property(_title, "modulate:a", 1.0, 0.8)
	_prompt.text = "TAP TO DEPLOY" if TouchControls.is_touch_device() else "PRESS ANY KEY / CLICK TO DEPLOY"

func _process(delta: float) -> void:
	_t += delta
	if _phase == "title":
		_prompt.modulate.a = 0.55 + 0.45 * sin(_t * 3.0)

func _input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	if _phase == "intro":
		_show_title()
	elif _phase == "title" and _t > 0.6:
		_phase = "done"
		var tw := create_tween()
		tw.tween_property(self, "offset", Vector2.ZERO, 0.0)
		for c in get_children():
			if c is CanvasItem:
				tw.parallel().tween_property(c, "modulate:a", 0.0, 0.5)
		await tw.finished
		deployed.emit()
		queue_free()
