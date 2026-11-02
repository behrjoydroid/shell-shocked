# Placeholder gun sounds, synthesized once on first use so there are no audio files
# to import. The sound pass in M9 can swap these for real recordings.
extends RefCounted

const MIX_RATE := 22050
const PEAK := 0.9
const FADE_OUT_TIME := 0.005

static var _shot: AudioStreamWAV
static var _click: AudioStreamWAV
static var _clack: AudioStreamWAV


static func shot() -> AudioStreamWAV:
	if _shot == null:
		_shot = _synth_shot()
	return _shot


# Pulling the trigger on an empty gun.
static func click() -> AudioStreamWAV:
	if _click == null:
		_click = _synth_tick(0.03, 180.0, 1900.0)
	return _click


# Working the magazine, at the start and end of a reload.
static func clack() -> AudioStreamWAV:
	if _clack == null:
		_clack = _synth_tick(0.09, 70.0, 420.0)
	return _clack


# A sharp noise crack, a muffled noise body and a low thump, all dying away fast.
static func _synth_shot() -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var samples := PackedFloat32Array()
	samples.resize(int(0.6 * MIX_RATE))
	var muffled := 0.0
	for i in samples.size():
		var t := float(i) / MIX_RATE
		var noise := rng.randf_range(-1.0, 1.0)
		muffled = lerpf(muffled, noise, 0.18)
		var crack := noise * exp(-t * 90.0)
		var body := muffled * exp(-t * 14.0)
		var thump := sin(TAU * 70.0 * t) * exp(-t * 22.0)
		samples[i] = crack * 0.7 + body * 1.3 + thump * 0.6
	return _to_wav(samples)


# A short metallic tick: noise plus a tone, both decaying at the given rate.
static func _synth_tick(length: float, decay: float, tone_hz: float) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var samples := PackedFloat32Array()
	samples.resize(int(length * MIX_RATE))
	for i in samples.size():
		var t := float(i) / MIX_RATE
		var envelope := exp(-t * decay)
		samples[i] = (rng.randf_range(-1.0, 1.0) * 0.6 + sin(TAU * tone_hz * t) * 0.5) * envelope
	return _to_wav(samples)


# Scales to a fixed peak and fades the very end to silence so it can't pop.
static func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var loudest := 0.0
	for sample in samples:
		loudest = maxf(loudest, absf(sample))
	var fade_samples := int(FADE_OUT_TIME * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var fade := minf(float(samples.size() - 1 - i) / fade_samples, 1.0)
		bytes.encode_s16(i * 2, int(samples[i] / loudest * PEAK * fade * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.data = bytes
	return wav
