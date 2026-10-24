class_name Sfx
extends Node
## Placeholder sounds: one short generated tone per named action. `counts`
## records every play so tests can check that an action made its sound.

const RATE := 22050
const TONES := {  # name -> [frequency Hz, seconds]
	"create": [660.0, 0.12],
	"move": [880.0, 0.18],
	"absorb": [990.0, 0.12],
	"fail": [110.0, 0.15],
	"win": [1320.0, 0.4],
	"lose": [147.0, 0.5],
	"menu": [520.0, 0.06],
}

var counts := {}
var _players := {}


func _ready() -> void:
	for tone in TONES:
		var p := AudioStreamPlayer.new()
		p.name = String(tone).capitalize()
		p.stream = _make(TONES[tone][0], TONES[tone][1])
		add_child(p)
		_players[tone] = p


func play(sound: String) -> void:
	counts[sound] = counts.get(sound, 0) + 1
	if _players.has(sound):
		_players[sound].play()


func _make(freq: float, seconds: float) -> AudioStreamWAV:
	var n := int(RATE * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var fade := 1.0 - float(i) / n
		var v := int(sin(TAU * freq * i / RATE) * 0.35 * fade * 32767.0)
		data.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	return w
