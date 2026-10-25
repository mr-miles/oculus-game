class_name Wind
extends AudioStreamPlayer
## A gentle looping wind: low-pass filtered noise whose loudness and pitch drift slowly, like
## gusts. Generated at start (no audio files), seamless when it loops, deliberately quiet.

const RATE := 22050
const SECONDS := 8.0
const VOLUME_DB := -22.0


func _init() -> void:
	name = "Wind"
	stream = make_loop()
	volume_db = VOLUME_DB
	autoplay = true


static func make_loop() -> AudioStreamWAV:
	var n := int(RATE * SECONDS)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var noise := PackedFloat32Array()
	noise.resize(n)
	for i in n:
		noise[i] = rng.randf_range(-1.0, 1.0)
	# Two low-pass passes around the loop (the second starts with the first's end state), so the
	# last sample flows into the first one without a click. The cut-off breathes with the gusts.
	var out := PackedFloat32Array()
	out.resize(n)
	var low := 0.0
	var low2 := 0.0
	for pass_no in 2:
		for i in n:
			var phase := TAU * float(i) / n  # whole cycles per loop keep the gusts seamless
			var gust := 0.5 + 0.5 * sin(phase * 1.0 + 0.6) * 0.6 + 0.5 * sin(phase * 3.0 + 2.0) * 0.4
			var k := 0.02 + 0.05 * gust  # low-pass coefficient: breezier in a gust
			low += (noise[i] - low) * k
			low2 += (low - low2) * k
			if pass_no == 1:
				out[i] = low2 * (0.35 + 0.65 * gust) * 3.2
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(clampf(out[i], -1.0, 1.0) * 0.6 * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w
