extends ViewTest
## AC-77: a quiet, seamlessly looping wind plays in the lobby and in every level.

func _check(label: String, scene: Node) -> void:
	var w := scene.find_child("Wind", true, false) as AudioStreamPlayer
	check("ac_77 %s: has a Wind player" % label, w != null)
	if w == null:
		return
	var s := w.stream as AudioStreamWAV
	check("ac_77 %s: wind loops" % label, s != null and s.loop_mode == AudioStreamWAV.LOOP_FORWARD and s.loop_end > s.loop_begin)
	check("ac_77 %s: wind is quiet (%.0f dB)" % [label, w.volume_db], w.volume_db <= -15.0 and w.volume_db >= -40.0)
	check("ac_77 %s: wind starts by itself" % label, w.autoplay)


func _init() -> void:
	var w := Wind.make_loop()
	var d := w.data
	var n := d.size() / 2
	var peak := 0
	var sum_sq := 0.0
	for i in n:
		var v := d.decode_s16(i * 2)
		peak = maxi(peak, absi(v))
		sum_sq += float(v) * float(v)
	var rms := sqrt(sum_sq / n) / 32767.0
	check("ac_77 wind is audible and not clipping (rms %.3f, peak %d)" % [rms, peak], rms > 0.02 and peak < 32000)
	var jump := absi(d.decode_s16(0) - d.decode_s16((n - 1) * 2))
	check("ac_77 loop is seamless: end and start differ by %d" % jump, jump < 1500)
	_check("level", await new_game())
	_check("lobby", await new_lobby())
	finish()
