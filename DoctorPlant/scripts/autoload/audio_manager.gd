extends Node
## BGM / 효과음 재생 담당.
## 실제 오디오 에셋이 아직 없으므로(assets/audio 비어 있음) 사운드가 없으면
## 코드로 생성한 단순 톤을 임시로 쓴다. 에셋이 들어오면 아래 경로 상수만 바꾸면 된다.

const BGM_TITLE_PATH: String = "res://assets/audio/bgm/title.ogg"
const SFX_SELECT_PATH: String = "res://assets/audio/sfx/ui_select.wav"
const SFX_MOVE_PATH: String = "res://assets/audio/sfx/ui_move.wav"

const MIX_RATE: int = 22050

var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _sfx_select: AudioStream
var _sfx_move: AudioStream
var _bgm_title: AudioStream


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

	_sfx_select = _load_or_generate(SFX_SELECT_PATH, _make_blip(880.0, 0.07, 0.35))
	_sfx_move = _load_or_generate(SFX_MOVE_PATH, _make_blip(1320.0, 0.04, 0.2))
	_bgm_title = _load_or_generate(BGM_TITLE_PATH, _make_pad_loop())


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
