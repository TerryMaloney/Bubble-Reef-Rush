## SettingsScreen.gd
## Full-screen settings menu. Accessible from the main menu.
## Changes are written immediately via Accessibility/SaveSystem — no "apply" step.
extends Control

class_name SettingsScreen


func _ready() -> void:
	_populate_from_settings()
	$Layout/BackButton.pressed.connect(func() -> void: GameManager.return_from_settings())

	# Latency slider (-200 to +200 ms).
	var latency_slider: HSlider = $Layout/LatencySection/LatencySlider
	latency_slider.value_changed.connect(_on_latency_changed)

	# Volume sliders.
	var master_slider: HSlider = $Layout/VolumesSection/MasterSlider
	var music_slider: HSlider = $Layout/VolumesSection/MusicSlider
	var sfx_slider: HSlider = $Layout/VolumesSection/SfxSlider
	master_slider.value_changed.connect(func(v: float) -> void: Accessibility.set_volume("master", v))
	music_slider.value_changed.connect(func(v: float) -> void: Accessibility.set_volume("music", v))
	sfx_slider.value_changed.connect(func(v: float) -> void: Accessibility.set_volume("sfx", v))

	# Toggle buttons.
	var wide_btn: CheckButton = $Layout/WideBeatSection/WideTimingToggle
	var motion_btn: CheckButton = $Layout/MotionSection/ReducedMotionToggle
	var colorblind_btn: CheckButton = $Layout/ColorblindSection/ColorblindToggle
	wide_btn.toggled.connect(func(v: bool) -> void: Accessibility.set_wide_timing_windows(v))
	motion_btn.toggled.connect(func(v: bool) -> void: Accessibility.set_reduced_motion(v))
	colorblind_btn.toggled.connect(func(v: bool) -> void: Accessibility.set_colorblind_judgements(v))

	# Text scale buttons.
	$Layout/TextScaleSection/Scale80Button.pressed.connect(func() -> void: Accessibility.set_text_scale(0.8))
	$Layout/TextScaleSection/Scale100Button.pressed.connect(func() -> void: Accessibility.set_text_scale(1.0))
	$Layout/TextScaleSection/Scale120Button.pressed.connect(func() -> void: Accessibility.set_text_scale(1.2))


func _populate_from_settings() -> void:
	var latency_slider: HSlider = $Layout/LatencySection/LatencySlider
	latency_slider.value = Accessibility.timing_offset_ms()
	_update_latency_label(Accessibility.timing_offset_ms())

	$Layout/VolumesSection/MasterSlider.value = Accessibility.volume_master()
	$Layout/VolumesSection/MusicSlider.value = Accessibility.volume_music()
	$Layout/VolumesSection/SfxSlider.value = Accessibility.volume_sfx()

	$Layout/WideBeatSection/WideTimingToggle.set_pressed_no_signal(Accessibility.wide_timing_windows())
	$Layout/MotionSection/ReducedMotionToggle.set_pressed_no_signal(Accessibility.reduced_motion())
	$Layout/ColorblindSection/ColorblindToggle.set_pressed_no_signal(Accessibility.colorblind_judgements())


func _on_latency_changed(value: float) -> void:
	Accessibility.set_timing_offset_ms(value)
	_update_latency_label(value)


func _update_latency_label(value: float) -> void:
	var label: Label = $Layout/LatencySection/LatencyValueLabel
	var sign_str: String = "+" if value >= 0 else ""
	label.text = "%s%.0f ms" % [sign_str, value]
