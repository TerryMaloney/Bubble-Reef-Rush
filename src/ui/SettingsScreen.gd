## SettingsScreen.gd
## Full-screen settings menu. Accessible from the main menu.
## Changes are written immediately via Accessibility/SaveSystem — no "apply" step.
extends Control

class_name SettingsScreen

# ---------------------------------------------------------------------------
# Latency calibration constants
# ---------------------------------------------------------------------------
const _CAL_BPM: float = 90.0
const _CAL_WARMUP_BEATS: int = 4
const _CAL_TAPS_NEEDED: int = 8
const _CAL_SR: int = 44100
const _CAL_CLICK_FREQ: float = 880.0
const _CAL_CLICK_LEN: float = 0.035  # seconds per click burst

# ---------------------------------------------------------------------------
# Calibration state
# ---------------------------------------------------------------------------
var _cal_overlay: Control = null
var _cal_result_row: Control = null
var _cal_running: bool = false
var _cal_elapsed: float = 0.0
var _cal_next_beat: float = 0.0
var _cal_beat_count: int = 0
var _cal_beat_ms: Array[float] = []
var _cal_tap_ms: Array[float] = []
var _cal_pulse: ColorRect = null
var _cal_pulse_t: float = 0.0
var _cal_progress_lbl: Label = null
var _cal_result_lbl: Label = null
var _cal_clicker: AudioStreamPlayer = null
var _cal_measured_ms: float = 0.0


func _ready() -> void:
	_populate_from_settings()
	$Layout/VBox/BackButton.pressed.connect(func() -> void: GameManager.return_from_settings())

	# Latency slider (-200 to +200 ms).
	var latency_slider: HSlider = $Layout/VBox/LatencySection/LatencyRow/LatencySlider
	latency_slider.value_changed.connect(_on_latency_changed)

	# Auto-calibrate button added below the latency row.
	_build_calibrate_button()

	# Volume sliders.
	var master_slider: HSlider = $Layout/VBox/VolumesSection/MasterRow/MasterSlider
	var music_slider: HSlider = $Layout/VBox/VolumesSection/MusicRow/MusicSlider
	var sfx_slider: HSlider = $Layout/VBox/VolumesSection/SfxRow/SfxSlider
	master_slider.value_changed.connect(func(v: float) -> void: Accessibility.set_volume("master", v))
	music_slider.value_changed.connect(func(v: float) -> void: Accessibility.set_volume("music", v))
	sfx_slider.value_changed.connect(func(v: float) -> void: Accessibility.set_volume("sfx", v))

	# Toggle buttons.
	var wide_btn: CheckButton = $Layout/VBox/WideBeatSection/WideTimingToggle
	var motion_btn: CheckButton = $Layout/VBox/MotionSection/ReducedMotionToggle
	var colorblind_btn: CheckButton = $Layout/VBox/ColorblindSection/ColorblindToggle
	wide_btn.toggled.connect(func(v: bool) -> void: Accessibility.set_wide_timing_windows(v))
	motion_btn.toggled.connect(func(v: bool) -> void: Accessibility.set_reduced_motion(v))
	colorblind_btn.toggled.connect(func(v: bool) -> void: Accessibility.set_colorblind_judgements(v))

	# Text scale buttons.
	$Layout/VBox/TextScaleSection/TextScaleButtons/Scale80Button.pressed.connect(func() -> void: Accessibility.set_text_scale(0.8))
	$Layout/VBox/TextScaleSection/TextScaleButtons/Scale100Button.pressed.connect(func() -> void: Accessibility.set_text_scale(1.0))
	$Layout/VBox/TextScaleSection/TextScaleButtons/Scale120Button.pressed.connect(func() -> void: Accessibility.set_text_scale(1.2))


func _populate_from_settings() -> void:
	var latency_slider: HSlider = $Layout/VBox/LatencySection/LatencyRow/LatencySlider
	latency_slider.value = Accessibility.timing_offset_ms()
	_update_latency_label(Accessibility.timing_offset_ms())

	$Layout/VBox/VolumesSection/MasterRow/MasterSlider.value = Accessibility.volume_master()
	$Layout/VBox/VolumesSection/MusicRow/MusicSlider.value = Accessibility.volume_music()
	$Layout/VBox/VolumesSection/SfxRow/SfxSlider.value = Accessibility.volume_sfx()

	$Layout/VBox/WideBeatSection/WideTimingToggle.set_pressed_no_signal(Accessibility.wide_timing_windows())
	$Layout/VBox/MotionSection/ReducedMotionToggle.set_pressed_no_signal(Accessibility.reduced_motion())
	$Layout/VBox/ColorblindSection/ColorblindToggle.set_pressed_no_signal(Accessibility.colorblind_judgements())


func _on_latency_changed(value: float) -> void:
	Accessibility.set_timing_offset_ms(value)
	_update_latency_label(value)


func _update_latency_label(value: float) -> void:
	var label: Label = $Layout/VBox/LatencySection/LatencyRow/LatencyValueLabel
	var sign_str: String = "+" if value >= 0 else ""
	label.text = "%s%.0f ms" % [sign_str, value]


# ---------------------------------------------------------------------------
# Calibration button
# ---------------------------------------------------------------------------

func _build_calibrate_button() -> void:
	var btn: Button = Button.new()
	btn.text = "Auto-Calibrate Latency"
	btn.custom_minimum_size = Vector2(0, 56)
	btn.add_theme_font_size_override("font_size", 22)
	$Layout/VBox/LatencySection.add_child(btn)
	btn.pressed.connect(_open_cal_overlay)


# ---------------------------------------------------------------------------
# Calibration overlay (built procedurally — no extra .tscn needed)
# ---------------------------------------------------------------------------

func _open_cal_overlay() -> void:
	if _cal_overlay != null:
		return

	_cal_overlay = Control.new()
	_cal_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.05, 0.15, 0.96)
	_cal_overlay.add_child(bg)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(700.0, 0.0)
	vbox.add_theme_constant_override("separation", 28)
	_cal_overlay.add_child(vbox)

	var title: Label = Label.new()
	title.text = "Latency Calibration"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var instr: Label = Label.new()
	instr.text = "Tap the button each time you hear the click.\nTap in time for 8 beats."
	instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(instr)

	# Pulse circle — a square ColorRect centred visually
	var pulse_wrap: CenterContainer = CenterContainer.new()
	_cal_pulse = ColorRect.new()
	_cal_pulse.custom_minimum_size = Vector2(200.0, 200.0)
	_cal_pulse.color = Color(0.2, 0.4, 0.9)
	pulse_wrap.add_child(_cal_pulse)
	vbox.add_child(pulse_wrap)

	_cal_progress_lbl = Label.new()
	_cal_progress_lbl.text = "Get ready…"
	_cal_progress_lbl.add_theme_font_size_override("font_size", 28)
	_cal_progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_cal_progress_lbl)

	var tap_btn: Button = Button.new()
	tap_btn.text = "TAP"
	tap_btn.custom_minimum_size = Vector2(0.0, 120.0)
	tap_btn.add_theme_font_size_override("font_size", 48)
	tap_btn.pressed.connect(_on_cal_tap)
	vbox.add_child(tap_btn)

	_cal_result_lbl = Label.new()
	_cal_result_lbl.text = ""
	_cal_result_lbl.add_theme_font_size_override("font_size", 26)
	_cal_result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cal_result_lbl.visible = false
	vbox.add_child(_cal_result_lbl)

	_cal_result_row = HBoxContainer.new()
	(_cal_result_row as HBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
	(_cal_result_row as HBoxContainer).add_theme_constant_override("separation", 24)
	_cal_result_row.visible = false
	var apply_btn: Button = Button.new()
	apply_btn.text = "Apply"
	apply_btn.custom_minimum_size = Vector2(200.0, 72.0)
	apply_btn.pressed.connect(_apply_cal)
	_cal_result_row.add_child(apply_btn)
	var discard_btn: Button = Button.new()
	discard_btn.text = "Discard"
	discard_btn.custom_minimum_size = Vector2(200.0, 72.0)
	discard_btn.pressed.connect(_close_cal_overlay)
	_cal_result_row.add_child(discard_btn)
	vbox.add_child(_cal_result_row)

	# Dismiss (×) button — top-right corner of overlay
	var close_btn: Button = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(80.0, 80.0)
	close_btn.add_theme_font_size_override("font_size", 32)
	close_btn.anchor_left = 1.0
	close_btn.anchor_right = 1.0
	close_btn.anchor_bottom = 0.0
	close_btn.anchor_top = 0.0
	close_btn.offset_left = -100.0
	close_btn.offset_top = 16.0
	close_btn.offset_right = -16.0
	close_btn.offset_bottom = 96.0
	close_btn.pressed.connect(_close_cal_overlay)
	_cal_overlay.add_child(close_btn)

	add_child(_cal_overlay)
	_begin_cal_loop()


func _begin_cal_loop() -> void:
	_cal_running = true
	_cal_elapsed = 0.0
	_cal_next_beat = 60.0 / _CAL_BPM
	_cal_beat_count = 0
	_cal_beat_ms.clear()
	_cal_tap_ms.clear()
	_cal_pulse_t = 0.0
	_setup_cal_clicker()


func _setup_cal_clicker() -> void:
	if _cal_clicker != null:
		_cal_clicker.queue_free()
	var gen: AudioStreamGenerator = AudioStreamGenerator.new()
	gen.mix_rate = float(_CAL_SR)
	gen.buffer_length = 0.05
	_cal_clicker = AudioStreamPlayer.new()
	_cal_clicker.stream = gen
	_cal_clicker.bus = "Master"
	_cal_clicker.volume_db = -3.0
	add_child(_cal_clicker)
	_cal_clicker.play()
	# Prime buffer with silence so the generator doesn't stall
	var pb: AudioStreamGeneratorPlayback = _cal_clicker.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb != null:
		var silence: PackedVector2Array = PackedVector2Array()
		silence.resize(int(0.05 * _CAL_SR))
		pb.push_chunk(silence)


func _fire_cal_click() -> void:
	if _cal_clicker == null or not _cal_clicker.playing:
		return
	var pb: AudioStreamGeneratorPlayback = _cal_clicker.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var n: int = int(_CAL_CLICK_LEN * float(_CAL_SR))
	var samples: PackedVector2Array = PackedVector2Array()
	samples.resize(n)
	for i: int in range(n):
		var t: float = float(i) / float(_CAL_SR)
		var env: float = 1.0 - float(i) / float(n)
		var v: float = sin(TAU * _CAL_CLICK_FREQ * t) * env * 0.8
		samples[i] = Vector2(v, v)
	pb.push_chunk(samples)


func _process(delta: float) -> void:
	if not _cal_running:
		return
	_cal_elapsed += delta
	while _cal_elapsed >= _cal_next_beat:
		_cal_next_beat += 60.0 / _CAL_BPM
		_on_cal_beat()
	# Decay pulse brightness back to resting colour
	_cal_pulse_t = maxf(0.0, _cal_pulse_t - delta * 5.0)
	if _cal_pulse != null:
		_cal_pulse.color = Color(
			lerp(0.2, 1.0, _cal_pulse_t),
			lerp(0.4, 1.0, _cal_pulse_t),
			lerp(0.9, 0.1, _cal_pulse_t)
		)


func _on_cal_beat() -> void:
	_cal_beat_count += 1
	_cal_pulse_t = 1.0
	_fire_cal_click()
	if _cal_beat_count > _CAL_WARMUP_BEATS:
		_cal_beat_ms.append(float(Time.get_ticks_msec()))
	if _cal_progress_lbl == null:
		return
	if _cal_beat_count <= _CAL_WARMUP_BEATS:
		_cal_progress_lbl.text = "Get ready…"
	else:
		_cal_progress_lbl.text = "Taps: %d / %d" % [_cal_tap_ms.size(), _CAL_TAPS_NEEDED]


func _on_cal_tap() -> void:
	if not _cal_running or _cal_beat_count <= _CAL_WARMUP_BEATS:
		return
	_cal_tap_ms.append(float(Time.get_ticks_msec()))
	if _cal_progress_lbl != null:
		_cal_progress_lbl.text = "Taps: %d / %d" % [_cal_tap_ms.size(), _CAL_TAPS_NEEDED]
	if _cal_tap_ms.size() >= _CAL_TAPS_NEEDED:
		_finish_calibration()


func _finish_calibration() -> void:
	_cal_running = false
	if _cal_clicker != null:
		_cal_clicker.stop()

	# Match each tap to its nearest beat and collect offsets.
	var half_beat_ms: float = (60000.0 / _CAL_BPM) * 0.5
	var offsets: Array[float] = []
	for tap_ms: float in _cal_tap_ms:
		var best: float = INF
		for beat_ms: float in _cal_beat_ms:
			var d: float = tap_ms - beat_ms
			if absf(d) < absf(best):
				best = d
		if absf(best) < half_beat_ms:
			offsets.append(best)

	if offsets.is_empty():
		if _cal_result_lbl != null:
			_cal_result_lbl.text = "Could not measure — please try again."
			_cal_result_lbl.visible = true
		return

	var total: float = 0.0
	for v: float in offsets:
		total += v
	var avg: float = total / float(offsets.size())
	_cal_measured_ms = clampf(avg, -200.0, 200.0)

	if _cal_progress_lbl != null:
		_cal_progress_lbl.text = "Done!"
	if _cal_result_lbl != null:
		var prev: float = Accessibility.timing_offset_ms()
		var sign_a: String = "+" if _cal_measured_ms >= 0.0 else ""
		var sign_p: String = "+" if prev >= 0.0 else ""
		_cal_result_lbl.text = "Measured: %s%.0f ms   (was %s%.0f ms)" % [
			sign_a, _cal_measured_ms, sign_p, prev
		]
		_cal_result_lbl.visible = true
	if _cal_result_row != null:
		_cal_result_row.visible = true


func _apply_cal() -> void:
	Accessibility.set_timing_offset_ms(_cal_measured_ms)
	var slider: HSlider = $Layout/VBox/LatencySection/LatencyRow/LatencySlider
	slider.value = _cal_measured_ms
	_update_latency_label(_cal_measured_ms)
	_close_cal_overlay()


func _close_cal_overlay() -> void:
	_cal_running = false
	if _cal_clicker != null:
		_cal_clicker.queue_free()
		_cal_clicker = null
	if _cal_overlay != null:
		_cal_overlay.queue_free()
		_cal_overlay = null
	_cal_pulse = null
	_cal_progress_lbl = null
	_cal_result_lbl = null
	_cal_result_row = null
