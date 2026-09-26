extends Node
## BGM / 효과음 재생 담당.
## 실제 오디오 에셋이 아직 없으므로(assets/audio 비어 있음) 사운드가 없으면
## 코드로 생성한 단순 톤을 임시로 쓴다. 에셋이 들어오면 아래 경로 상수만 바꾸면 된다.

const BGM_TITLE_PATH: String = "res://assets/audio/bgm/title.ogg"
const SFX_SELECT_PATH: String = "res://assets/audio/sfx/ui_select.wav"
const SFX_MOVE_PATH: String = "res://assets/audio/sfx/ui_move.wav"

## 챕터 연출용 효과음. 파일이 있으면 쓰고, 없으면 코드로 만든 임시음으로 대체한다.
const SFX_DOOR_OPEN_PATH: String = "res://assets/audio/sfx/door_1.mp3"
const SFX_DOOR_CLOSE_PATH: String = "res://assets/audio/sfx/door_2.mp3"
const SFX_STEPS_PATH: String = "res://assets/audio/sfx/step_1.mp3"
const SFX_KNOCK_PATH: String = "res://assets/audio/sfx/knock.wav"
const SFX_CHIME_PATH: String = "res://assets/audio/sfx/chime.wav"
const SFX_WINDOW_PATH: String = "res://assets/audio/sfx/window_open.wav"
const SFX_BUZZ_PATH: String = "res://assets/audio/sfx/buzz.wav"
const AMB_MURMUR_PATH: String = "res://assets/audio/ambience/murmur.ogg"
const SFX_TYPING_PATH: String = "res://assets/audio/sfx/typing.wav"

## 대사 타이핑음이 너무 촘촘하면 "토도도"가 아니라 윙 소리가 되므로 최소 간격을 둔다.
const TYPING_MIN_INTERVAL: float = 0.05
const TYPING_PITCH_JITTER: float = 0.06
const TYPING_VOLUME_DB: float = -4.0

const MIX_RATE: int = 22050
const AMBIENCE_FADE: float = 0.6

var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _steps_player: AudioStreamPlayer
var _murmur_player: AudioStreamPlayer
var _typing_player: AudioStreamPlayer
var _last_typing_msec: int = -100000
var _sfx_select: AudioStream
var _sfx_move: AudioStream
var _bgm_title: AudioStream
var _sfx_table: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "BGM"
	_bgm_player.name = "BgmPlayer"
	add_child(_bgm_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX"
	_sfx_player.name = "SfxPlayer"
	add_child(_sfx_player)

	_steps_player = AudioStreamPlayer.new()
	_steps_player.bus = "SFX"
	_steps_player.name = "StepsPlayer"
	add_child(_steps_player)

	_murmur_player = AudioStreamPlayer.new()
	_murmur_player.bus = "SFX"
	_murmur_player.name = "MurmurPlayer"
	add_child(_murmur_player)

	_typing_player = AudioStreamPlayer.new()
	_typing_player.bus = "SFX"
	_typing_player.name = "TypingPlayer"
	add_child(_typing_player)
	_typing_player.stream = _load_or_generate(SFX_TYPING_PATH, _make_typing_blip())

	_sfx_select = _load_or_generate(SFX_SELECT_PATH, _make_blip(880.0, 0.07, 0.35))
	_sfx_move = _load_or_generate(SFX_MOVE_PATH, _make_blip(1320.0, 0.04, 0.2))
	_bgm_title = _load_or_generate(BGM_TITLE_PATH, _make_pad_loop())

	_steps_player.stream = _looped(_load_or_generate(SFX_STEPS_PATH, _make_steps_loop()))
	_murmur_player.stream = _looped(_load_or_generate(AMB_MURMUR_PATH, _make_murmur_loop()))

	_sfx_table = {
		&"door_open": _load_or_generate(SFX_DOOR_OPEN_PATH, _make_creak()),
		&"door_close": _load_or_generate(SFX_DOOR_CLOSE_PATH, _make_creak()),
		&"knock": _load_or_generate(SFX_KNOCK_PATH, _make_knock()),
		&"chime": _load_or_generate(SFX_CHIME_PATH, _make_chime()),
		&"window_open": _load_or_generate(SFX_WINDOW_PATH, _make_whoosh()),
		&"buzz": _load_or_generate(SFX_BUZZ_PATH, _make_buzz()),
	}


func play_bgm_title() -> void:
	if _bgm_player.stream == _bgm_title and _bgm_player.playing:
		return
	_bgm_player.stream = _bgm_title
	_bgm_player.play()


func stop_bgm() -> void:
	_bgm_player.stop()


func play_select() -> void:
	_play_sfx(_sfx_select)


func play_move() -> void:
	_play_sfx(_sfx_move)


## 대사가 한 글자 찍힐 때의 "토" 소리. 간격이 너무 짧으면 건너뛴다.
## pitch 는 말하는 인물의 목소리 높이(말풍선 NPC 마다 다르게 준다).
func play_typing(pitch: float = 1.0, volume_db: float = TYPING_VOLUME_DB) -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_typing_msec < int(TYPING_MIN_INTERVAL * 1000.0):
		return
	_last_typing_msec = now
	_typing_player.pitch_scale = pitch * (1.0 + randf_range(-TYPING_PITCH_JITTER, TYPING_PITCH_JITTER))
	_typing_player.volume_db = volume_db
	_typing_player.play()


## 챕터 연출용 효과음. id: door_open / door_close / knock / chime / window_open / buzz
## 대사·발소리와 겹칠 수 있어 일회용 플레이어로 재생한다.
func play_sfx(id: StringName) -> void:
	var stream: AudioStream = _sfx_table.get(id, null)
	if stream == null:
		push_warning("등록되지 않은 효과음: %s" % id)
		return
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	player.stream = stream
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


## 발소리·웅성거림 같은 반복 환경음. kind: steps / murmur
func start_ambience(kind: StringName, volume_db: float = -6.0) -> void:
	var player: AudioStreamPlayer = _ambience_player(kind)
	if player == null or player.stream == null:
		return
	player.volume_db = -60.0
	if not player.playing:
		player.play()
	var tween := create_tween()
	tween.tween_property(player, "volume_db", volume_db, AMBIENCE_FADE)


func stop_ambience(kind: StringName) -> void:
	var player: AudioStreamPlayer = _ambience_player(kind)
	if player == null or not player.playing:
		return
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -60.0, AMBIENCE_FADE)
	tween.tween_callback(player.stop)


func stop_all_ambience() -> void:
	stop_ambience(&"steps")
	stop_ambience(&"murmur")


func _ambience_player(kind: StringName) -> AudioStreamPlayer:
	match kind:
		&"steps":
			return _steps_player
		&"murmur":
			return _murmur_player
	push_warning("등록되지 않은 환경음: %s" % kind)
	return null


## 반복 재생하도록 복제한 스트림을 돌려준다.
func _looped(stream: AudioStream) -> AudioStream:
	if stream == null:
		return null
	var copy: AudioStream = stream.duplicate()
	if copy is AudioStreamMP3 or copy is AudioStreamOggVorbis:
		copy.set("loop", true)
	elif copy is AudioStreamWAV:
		var wav := copy as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.data.size() / 2.0) - 1
	return copy


func _play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.play()


func _load_or_generate(path: String, fallback: AudioStream) -> AudioStream:
	if ResourceLoader.exists(path):
		var stream := ResourceLoader.load(path) as AudioStream
		if stream != null:
			return stream
	return fallback


## 짧은 사인파 블립(UI 효과음 임시 대체).
func _make_blip(frequency: float, duration: float, gain: float) -> AudioStreamWAV:
	var frames: int = int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i: int in frames:
		var t: float = float(i) / MIX_RATE
		var envelope: float = 1.0 - float(i) / float(frames)
		var sample: float = sin(TAU * frequency * t) * envelope * envelope * gain
		_write_sample(data, i, sample)
	return _make_wav(data, false, 0, 0)


## 낮게 깔리는 4초 루프 패드(BGM 임시 대체).
func _make_pad_loop() -> AudioStreamWAV:
	var duration: float = 4.0
	var frames: int = int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i: int in frames:
		var t: float = float(i) / MIX_RATE
		var swell: float = 0.5 + 0.5 * sin(TAU * t / duration)
		var tone: float = sin(TAU * 196.0 * t) + 0.6 * sin(TAU * 293.66 * t) + 0.4 * sin(TAU * 392.0 * t)
		_write_sample(data, i, tone * 0.05 * swell)
	return _make_wav(data, true, 0, frames - 1)


func _write_sample(data: PackedByteArray, index: int, value: float) -> void:
	var clamped: int = int(clampf(value, -1.0, 1.0) * 32767.0)
	data.encode_s16(index * 2, clamped)


## 대사 타이핑음 "토". 둥근 중음에 빠른 감쇠, 앞머리만 살짝 딱딱하게.
func _make_typing_blip() -> AudioStreamWAV:
	var duration: float = 0.045
	var frames: int = int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i: int in frames:
		var t: float = float(i) / MIX_RATE
		var attack: float = clampf(t / 0.002, 0.0, 1.0)
		var envelope: float = attack * exp(-t * 70.0)
		var tone: float = sin(TAU * 520.0 * t) + 0.35 * sin(TAU * 1040.0 * t)
		_write_sample(data, i, tone * envelope * 0.3)
	return _make_wav(data, false, 0, 0)


## 문이 끼익 열리는 소리(에셋이 없을 때만 쓰는 대체음).
func _make_creak() -> AudioStreamWAV:
	var duration: float = 0.9
	var frames: int = int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i: int in frames:
		var t: float = float(i) / MIX_RATE
		var ratio: float = t / duration
		var freq: float = lerpf(180.0, 420.0, ratio)
		var envelope: float = sin(PI * ratio)
		var wobble: float = 0.6 + 0.4 * sin(TAU * 11.0 * t)
		_write_sample(data, i, sin(TAU * freq * t) * envelope * wobble * 0.18)
	return _make_wav(data, false, 0, 0)


## 똑똑. 두 번 두드리는 소리.
func _make_knock() -> AudioStreamWAV:
	var duration: float = 0.7
	var frames: int = int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var hits: Array[float] = [0.0, 0.26]
	for i: int in frames:
		var t: float = float(i) / MIX_RATE
		var sample: float = 0.0
		for hit: float in hits:
			var dt: float = t - hit
			if dt < 0.0 or dt > 0.18:
				continue
			var envelope: float = exp(-dt * 38.0)
			sample += (sin(TAU * 140.0 * dt) + 0.5 * sin(TAU * 320.0 * dt)) * envelope * 0.35
		_write_sample(data, i, sample)
	return _make_wav(data, false, 0, 0)


## 병원 내부 알림음.
func _make_chime() -> AudioStreamWAV:
	var duration: float = 1.6
	var frames: int = int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var notes: Array[float] = [880.0, 1174.66]
	for i: int in frames:
		var t: float = float(i) / MIX_RATE
		var sample: float = 0.0
		for n: int in notes.size():
			var start: float = n * 0.35
			var dt: float = t - start
			if dt < 0.0:
				continue
			sample += sin(TAU * notes[n] * dt) * exp(-dt * 3.2) * 0.22
		_write_sample(data, i, sample)
	return _make_wav(data, false, 0, 0)


## 창문이 열리며 스치는 소리.
func _make_whoosh() -> AudioStreamWAV:
	var duration: float = 1.1
	var frames: int = int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260920
	var smoothed: float = 0.0
	for i: int in frames:
		var ratio: float = float(i) / float(frames)
		var envelope: float = sin(PI * ratio)
		smoothed = lerpf(smoothed, rng.randf_range(-1.0, 1.0), 0.08)
		_write_sample(data, i, smoothed * envelope * 0.25)
	return _make_wav(data, false, 0, 0)


## 미니게임에서 실수했을 때의 낮은 "뿌" 소리.
func _make_buzz() -> AudioStreamWAV:
	var duration: float = 0.22
	var frames: int = int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i: int in frames:
		var t: float = float(i) / MIX_RATE
		var envelope: float = clampf(t / 0.01, 0.0, 1.0) * (1.0 - t / duration)
		# 사각파에 가까운 거친 소리. 두 음을 살짝 어긋나게 겹쳐 떨리게 한다.
		var tone: float = signf(sin(TAU * 150.0 * t)) * 0.6 + signf(sin(TAU * 157.0 * t)) * 0.4
		_write_sample(data, i, tone * envelope * 0.12)
	return _make_wav(data, false, 0, 0)


## 발소리 루프(에셋이 없을 때만 쓰는 대체음).
func _make_steps_loop() -> AudioStreamWAV:
	var duration: float = 1.2
	var frames: int = int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var steps: Array[float] = [0.0, 0.6]
	for i: int in frames:
		var t: float = float(i) / MIX_RATE
		var sample: float = 0.0
		for step: float in steps:
			var dt: float = t - step
			if dt < 0.0 or dt > 0.12:
				continue
			sample += sin(TAU * 95.0 * dt) * exp(-dt * 55.0) * 0.3
		_write_sample(data, i, sample)
	return _make_wav(data, true, 0, frames - 1)


## 식물들이 웅성대는 소리(낮은 잡음 루프).
func _make_murmur_loop() -> AudioStreamWAV:
	var duration: float = 3.0
	var frames: int = int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 991120
	var smoothed: float = 0.0
	for i: int in frames:
		var t: float = float(i) / MIX_RATE
		smoothed = lerpf(smoothed, rng.randf_range(-1.0, 1.0), 0.02)
		var swell: float = 0.6 + 0.4 * sin(TAU * t / duration)
		# 루프 이음매가 튀지 않도록 양 끝을 줄인다.
		var edge: float = clampf(minf(t, duration - t) / 0.3, 0.0, 1.0)
		_write_sample(data, i, smoothed * swell * edge * 0.12)
	return _make_wav(data, true, 0, frames - 1)


func _make_wav(data: PackedByteArray, looped: bool, loop_begin: int, loop_end: int) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	if looped:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = loop_begin
		wav.loop_end = loop_end
	return wav
