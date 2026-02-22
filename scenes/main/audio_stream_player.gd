class_name MuAudioStream

extends AudioStreamPlayer

const DAMAGE_AUDIO_COOLDOWN = 1

var story_music = preload("res://assets/music/8_Bit_Nostalgia_-_www.FesliyanStudios.com.mp3")
var battle_music = preload("res://assets/music/Retro_Platforming_-_David_Fesliyan.mp3")
var boss_music = preload("res://assets/music/Boss_Time_-_www.FesliyanStudios.com.mp3")

var damage_audio = preload("res://assets/sound-effects/dogwolf123-retro-hurt-sound-03-474780.mp3")

var playing_track_index = -1
var damage_sound_cooldown


func _ready():
	damage_sound_cooldown = 0


func _process(delta):
	if damage_sound_cooldown > 0:
		damage_sound_cooldown -= delta


func stop_music():
	stop()
	playing_track_index = -1


func play_story_music():
	if playing_track_index != 0:
		playing_track_index = 0
		stream = story_music
		play()


func play_battle_music():
	if playing_track_index != 1:
		playing_track_index = 1
		stream = battle_music
		play()


func play_boss_music():
	if playing_track_index != 2:
		playing_track_index = 2
		stream = boss_music
		play()


func play_damage_audio():
	print("HIT")
	if damage_sound_cooldown <= 0:
		damage_sound_cooldown = DAMAGE_AUDIO_COOLDOWN
		stream = damage_audio
		play()
