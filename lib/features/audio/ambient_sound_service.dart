import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AmbientSoundService extends ChangeNotifier {
  static final AmbientSoundService _instance = AmbientSoundService._internal();
  factory AmbientSoundService() => _instance;
  AmbientSoundService._internal() {
    _initListener();
  }

  void _initListener() {
    _player.onPlayerStateChanged.listen((state) {
      isPlaying = state == PlayerState.playing;
      log('Audio: Internal state changed to $state (isPlaying: $isPlaying)', name: 'Audio');
      notifyListeners();
    });
  }

  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;
  String currentTrack = '';

  /// Keys are display names, values are asset paths relative to the assets folder.
  final Map<String, String> tracks = {
    'Birds': 'music/birds-relaxing.mp3',
    'Waterfall': 'music/waterfall.mp3',
    'Forest': 'music/forest-music.mp3',
  };

  Future<void> togglePlay(String trackName) async {
    final assetPath = tracks[trackName];
    if (assetPath == null) {
      log('Audio: Error - Track "$trackName" not found in library', name: 'Audio');
      return;
    }

    log('Audio: Toggling play for track: $trackName', name: 'Audio');

    if (isPlaying && currentTrack == trackName) {
      log('Audio: Pausing current track: $currentTrack', name: 'Audio');
      await _player.pause();
    } else {
      try {
        log('Audio: Playing local asset track: $trackName ($assetPath)', name: 'Audio');
        currentTrack = trackName;
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.play(AssetSource(assetPath));
      } catch (e) {
        log('Audio: Critical error playing track $trackName: $e', name: 'Audio');
        isPlaying = false;
      }
    }
  }

  Future<void> stop() async {
    log('Audio: Stopping playback', name: 'Audio');
    await _player.stop();
    isPlaying = false;
    notifyListeners();
  }
}
