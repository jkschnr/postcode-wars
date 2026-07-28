extends Node
## Audio — procedural SFX, no asset files. Every sound is synthesised once at
## boot into a small AudioStreamWAV (real ADSR-ish envelope, harmonic partials,
## noise beds, multi-note sequences) and played through a round-robin VOICE POOL
## so overlapping cues layer instead of cutting each other off (the old single
## bus stuttered on rapid cash ticks and swallowed taps mid-reveal).

const MIX := 22050.0
const VOICES := 8

var enabled := true
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}

func _ready() -> void:
	for i in range(VOICES):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)
	_bake_all()

# ------------------------------------------------------------------ synthesis
## A "voice" is one summed layer: {start, dur, f0, f1(glide), parts:[[mult,amp]],
## noise, vol}. _bake sums them sample-by-sample with incremental phase (so
## glides don't click) and an attack→exp-decay envelope, into a mono 16-bit WAV.
func _bake(voices: Array, total: float, peak := 0.9) -> AudioStreamWAV:
	var n := int(MIX * total)
	var buf := PackedFloat32Array(); buf.resize(n)
	for v in voices:
		var start: float = v.get("start", 0.0)
		var dur: float = v.get("dur", total - start)
		var f0: float = v.get("f0", 440.0)
		var f1: float = v.get("f1", f0)
		var parts: Array = v.get("parts", [[1.0, 1.0]])
		var noise: float = v.get("noise", 0.0)
		var vol: float = v.get("vol", 1.0)
		var atk: float = clampf(v.get("atk", 0.006), 0.001, dur * 0.5)
		var dk: float = -log(0.02) / maxf(0.02, dur - atk)   # decay to ~2% by end
		var i0 := int(start * MIX)
		var phases := PackedFloat32Array(); phases.resize(parts.size())
		for si in range(int(dur * MIX)):
			var idx := i0 + si
			if idx < 0 or idx >= n: continue
			var lt := float(si) / MIX
			var env: float = (lt / atk) if lt < atk else exp(-dk * (lt - atk))
			var freq: float = lerp(f0, f1, clampf(lt / dur, 0.0, 1.0))
			var s := 0.0
			for pi in range(parts.size()):
				var mult: float = parts[pi][0]
				phases[pi] += TAU * freq * mult / MIX
				s += sin(phases[pi]) * float(parts[pi][1])
			if noise > 0.0:
				s += (randf() * 2.0 - 1.0) * noise
			buf[idx] += s * env * vol
	# soft-clip and convert to 16-bit PCM
	var bytes := PackedByteArray(); bytes.resize(n * 2)
	for i in range(n):
		var x: float = buf[i]
		x = (x / (1.0 + absf(x))) * peak          # gentle saturation, no hard clip
		var q := int(clampf(x, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = q & 0xFF
		bytes[i * 2 + 1] = (q >> 8) & 0xFF
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.stereo = false
	w.mix_rate = int(MIX)
	w.data = bytes
	return w

func _bake_all() -> void:
	# soft UI tick — a rounded blip, two quiet partials
	_cache["tap"] = _bake([{"f0": 620, "dur": 0.05, "parts": [[1, 0.7], [2.0, 0.15]], "vol": 0.5}], 0.06)
	_cache["ui"]  = _bake([{"f0": 500, "f1": 540, "dur": 0.06, "parts": [[1, 0.7], [2.01, 0.18]], "vol": 0.55}], 0.07)
	# cash tick — bright, glides up a touch; short so a count-up layers into a shimmer
	_cache["cash"] = _bake([{"f0": 900, "f1": 1180, "dur": 0.06, "parts": [[1, 0.6], [2.0, 0.3], [3.01, 0.12]], "vol": 0.45}], 0.08)
	# coin — a proper two-partial chime (bank/collect payoff)
	_cache["coin"] = _bake([{"f0": 1046, "dur": 0.28, "parts": [[1, 0.55], [2.0, 0.3], [3.0, 0.14], [5.0, 0.06]], "vol": 0.6, "atk": 0.003}], 0.3)
	# reveal — a warm two-note swell up
	_cache["reveal"] = _bake([
		{"f0": 440, "dur": 0.16, "parts": [[1, 0.5], [2, 0.2]], "vol": 0.5},
		{"start": 0.09, "f0": 660, "dur": 0.22, "parts": [[1, 0.55], [2, 0.22], [3, 0.08]], "vol": 0.55}], 0.34)
	# crit — bright sparkle, glides up with shimmery partials
	_cache["crit"] = _bake([
		{"f0": 1200, "f1": 1560, "dur": 0.14, "parts": [[1, 0.5], [2.01, 0.3], [4.0, 0.14]], "vol": 0.55},
		{"start": 0.06, "f0": 1800, "dur": 0.14, "parts": [[1, 0.35], [2, 0.12]], "vol": 0.4}], 0.22)
	# level up — an ascending do-mi-sol-do arpeggio
	_cache["level_up"] = _bake([
		{"start": 0.00, "f0": 523, "dur": 0.14, "parts": [[1, 0.5], [2, 0.2]], "vol": 0.55},
		{"start": 0.10, "f0": 659, "dur": 0.14, "parts": [[1, 0.5], [2, 0.2]], "vol": 0.55},
		{"start": 0.20, "f0": 784, "dur": 0.16, "parts": [[1, 0.5], [2, 0.2]], "vol": 0.55},
		{"start": 0.30, "f0": 1046, "dur": 0.28, "parts": [[1, 0.55], [2, 0.25], [3, 0.1]], "vol": 0.62, "atk": 0.003}], 0.6)
	# error — low buzzy square-ish thud with a little noise
	_cache["error"] = _bake([{"f0": 150, "dur": 0.16, "parts": [[1, 0.5], [3, 0.2], [5, 0.1]], "noise": 0.08, "vol": 0.55}], 0.18)
	# whoosh — noise swept down, for screen transitions
	_cache["whoosh"] = _bake([{"f0": 520, "f1": 180, "dur": 0.18, "parts": [[1, 0.2]], "noise": 0.35, "vol": 0.4, "atk": 0.03}], 0.2)
	# hit — combat impact: noise burst + low thump
	_cache["hit"] = _bake([
		{"f0": 110, "f1": 70, "dur": 0.10, "parts": [[1, 0.8], [1.5, 0.2]], "vol": 0.7},
		{"f0": 300, "dur": 0.06, "parts": [[1, 0.2]], "noise": 0.5, "vol": 0.5}], 0.14)
	# unlock — pleasant two-note up (venue/district opens)
	_cache["unlock"] = _bake([
		{"f0": 660, "dur": 0.12, "parts": [[1, 0.5], [2, 0.2]], "vol": 0.5},
		{"start": 0.08, "f0": 988, "dur": 0.2, "parts": [[1, 0.55], [2, 0.22], [3, 0.09]], "vol": 0.55}], 0.3)

# ------------------------------------------------------------------ playback
func _emit(name: String, pitch := 1.0, vol_db := -8.0) -> void:
	if not enabled or not _cache.has(name):
		return
	var p := _pool[_next]
	_next = (_next + 1) % VOICES
	p.stream = _cache[name]
	p.pitch_scale = pitch
	p.volume_db = vol_db
	p.play()

# public API (kept stable) + new cues for the polish pass
func tap() -> void: _emit("tap", 1.0 + randf() * 0.04, -12.0)
func ui() -> void: _emit("ui", 1.0 + randf() * 0.03, -11.0)
func cash() -> void: _emit("cash", 0.97 + randf() * 0.12, -15.0)
func coin() -> void: _emit("coin", 1.0, -8.0)
func reveal() -> void: _emit("reveal", 1.0, -7.0)
func crit() -> void: _emit("crit", 1.0, -6.0)
func level_up() -> void: _emit("level_up", 1.0, -6.0)
func error() -> void: _emit("error", 1.0, -9.0)
func whoosh() -> void: _emit("whoosh", 1.0 + randf() * 0.06, -13.0)
func hit(power := 1.0) -> void: _emit("hit", clampf(1.2 - power * 0.35, 0.7, 1.3), -8.0)
func unlock() -> void: _emit("unlock", 1.0, -7.0)
