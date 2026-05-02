import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';

class AmbientSoundService {
  static final AmbientSoundService _instance = AmbientSoundService._internal();
  factory AmbientSoundService() => _instance;
  AmbientSoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;
  String currentTrack = '';

  final Map<String, String> tracks = {
    'Birds':
        'https://cdn.pixabay.com/download/audio/2022/01/18/audio_145c228d42.mp3', // Example bird sound
    'Waterfall':
        'https://cdn.pixabay.com/download/audio/2021/08/04/audio_0625c1539c.mp3', // Example waterfall
    'Forest':
        'https://cdn.pixabay.com/download/audio/2021/09/06/audio_4f09d20c57.mp3', // Example forest
  };

  Future<void> togglePlay(String trackName) async {
    log('Audio: Toggling play for track: $trackName', name: 'Audio');
    if (isPlaying && currentTrack == trackName) {
      log('Audio: Pausing current track: $currentTrack', name: 'Audio');
      await _player.pause();
      isPlaying = false;
    } else {
      log('Audio: Playing track: $trackName', name: 'Audio');
      currentTrack = trackName;
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(UrlSource(tracks[trackName]!));
      isPlaying = true;
    }
  }

  Future<void> stop() async {
    log('Audio: Stopping playback', name: 'Audio');
    await _player.stop();
    isPlaying = false;
  }
}
