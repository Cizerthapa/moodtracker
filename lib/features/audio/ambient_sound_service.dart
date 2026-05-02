import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:moodtrack/core/constants/app_constants.dart';


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

  final Map<String, String> tracks = {
    'Birds': AppConstants.audioBirdsUrl,
    'Waterfall': AppConstants.audioWaterfallUrl,
    'Forest': AppConstants.audioForestUrl,
  };

  Future<void> togglePlay(String trackName) async {
    final trackUrl = tracks[trackName];
    if (trackUrl == null) {
      log('Audio: Error - Track "$trackName" not found in library', name: 'Audio');
      return;
    }

    log('Audio: Toggling play for track: $trackName', name: 'Audio');

    if (isPlaying && currentTrack == trackName) {
      log('Audio: Pausing current track: $currentTrack', name: 'Audio');
      await _player.pause();
    } else {
      // Check connectivity before playing remote URL
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        log('Audio: Error - No internet connection to stream audio', name: 'Audio');
        return;
      }

      try {
        log('Audio: Playing track: $trackName', name: 'Audio');
        currentTrack = trackName;
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.play(UrlSource(trackUrl));
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
