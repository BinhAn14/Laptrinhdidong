import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../providers/radio_provider.dart';
import '../providers/playing_log_provider.dart';
import '../models/music.dart';
import '../models/playlist.dart';
import '../screens/common/playing_screen.dart';

enum RepeatMode { off, one, all }

enum MyPlayerState { stopped, playing, paused }

class PlayerController {
  static final PlayerController instance = PlayerController._internal();
  PlayerController._internal() {
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerComplete.listen((event) {
      playNext(true);
      notifyMusicChange();
    });
  }

  late final AudioPlayer _audioPlayer;
  final _rng = Random();
  final StreamController<void> _musicChangeController =
      StreamController<void>.broadcast();

  List<Music> _musicList = [];
  final List<int> _playedIndexes = [];
  int _currentIndex = -1;

  MyPlayerState state = MyPlayerState.stopped;
  bool shuffleMode = false;
  RepeatMode repeatMode = RepeatMode.off;
  bool isShowingLyrics = false;

  Music? get current {
    _audioPlayer.onPlayerComplete;
    if (_currentIndex == -1) {
      return null;
    }
    return _musicList[_currentIndex];
  }

  bool get isPlaying => state == MyPlayerState.playing;
  bool get isActive => state != MyPlayerState.stopped;

  Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;
  Stream<void> get onMusicChanged => _musicChangeController.stream;
  Stream<PlayerState> get onPlayerStateChanged =>
      _audioPlayer.onPlayerStateChanged;

  void setPosition(int position) {
    _audioPlayer.seek(Duration(seconds: position));
  }

  void stopMusic() {
    _audioPlayer.stop();
    state = MyPlayerState.stopped;

    if (RadioProvider.instance.isPlaying) {
      RadioProvider.instance.stop();
    }

    notifyMusicChange();
  }

  void setMusic(Music music) {
    _musicList.clear();
    _playedIndexes.clear();

    _musicList.add(music);
    _currentIndex = 0;

    _play(music);
    notifyMusicChange();
  }

  void setPlaylist(Playlist playlist, {int? index, bool shuffle = false}) {
    assert((index != null && !shuffle) || (index == null && shuffle));

    _musicList.clear();
    _playedIndexes.clear();

    playlist.getMusicList().then((result) => _musicList = result);

    if (shuffle) {
      _currentIndex = _rng.nextInt(playlist.musicIDs.length);
    } else {
      _currentIndex = index!;
    }

    final initMusic = playlist.getMusicAtIndex(_currentIndex);
    shuffleMode = shuffle;
    _play(initMusic);
    notifyMusicChange();
  }

  void setMusicList(List<Music> musicList, {int? index, bool shuffle = false}) {
    assert((index != null && !shuffle) || (index == null && shuffle));

    _musicList = [...musicList];
    _playedIndexes.clear();

    if (shuffle) {
      _currentIndex = _rng.nextInt(musicList.length);
    } else {
      _currentIndex = index!;
    }

    final initMusic = musicList[_currentIndex];
    shuffleMode = shuffle;
    _play(initMusic);
    notifyMusicChange();
  }

  void _play(Music music) {
    _audioPlayer.play(UrlSource(music.audioUrl));
    state = MyPlayerState.playing;

    if (!music.isDevice) {
      PlayingLogProvider.instance.addNewLog(music.id);
    }

    if (RadioProvider.instance.isPlaying) {
      RadioProvider.instance.stop();
    }
  }

  void togglePlay() {
    if (state == MyPlayerState.playing) {
      _audioPlayer.pause();
      state = MyPlayerState.paused;
    } else if (state == MyPlayerState.paused) {
      if (RadioProvider.instance.isPlaying) {
        RadioProvider.instance.stop();
      }
      _audioPlayer.resume();
      state = MyPlayerState.playing;
    }
    notifyMusicChange();
  }

  void toggleShuffle() {
    shuffleMode = !shuffleMode;
  }

  void toggleRepeat() {
    if (repeatMode == RepeatMode.off) {
      repeatMode = RepeatMode.all;
    } else if (repeatMode == RepeatMode.all) {
      repeatMode = RepeatMode.one;
    } else {
      repeatMode = RepeatMode.off;
    }
  }

  void playNext([bool passive = false]) {
    _playedIndexes.add(_currentIndex);

    switch (repeatMode) {
      case RepeatMode.off:
        if (_playedIndexes.toSet().length == _musicList.length && passive) {
          state = MyPlayerState.stopped;
        } else {
          _currentIndex = shuffleMode
              ? _getNextRandomIndex()
              : ((_currentIndex + 1) % _musicList.length);
          _play(_musicList[_currentIndex]);
        }
        notifyMusicChange();
        break;

      case RepeatMode.one:
        if (passive) {
          _play(_musicList[_currentIndex]);
        } else {
          _currentIndex = shuffleMode
              ? _getNextRandomIndex()
              : ((_currentIndex + 1) % _musicList.length);
          _play(_musicList[_currentIndex]);
          notifyMusicChange();
        }
        break;

      case RepeatMode.all:
        _currentIndex = shuffleMode
            ? _getNextRandomIndex()
            : ((_currentIndex + 1) % _musicList.length);
        _play(_musicList[_currentIndex]);
        notifyMusicChange();
        break;
    }
  }

  void playPrevious() {
    if (_playedIndexes.isEmpty) {
      _audioPlayer.seek(Duration.zero);
      if (state == MyPlayerState.paused) {
        _audioPlayer.resume();
        state = MyPlayerState.playing;
        notifyMusicChange();
      }
    } else {
      _currentIndex = _playedIndexes.last;
      _playedIndexes.removeLast();
      _play(_musicList[_currentIndex]);
      notifyMusicChange();
    }
  }

  int _getNextRandomIndex() {
    List<int> pool = [for (var i = 0; i < _musicList.length; i++) i];
    for (int i = _playedIndexes.length - 1;
        i >= max(0, _playedIndexes.length - _musicList.length + 1);
        i--) {
      pool.remove(_playedIndexes[i]);
    }
    return pool[_rng.nextInt(pool.length)];
  }

  void maximizeScreen(BuildContext context) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const PlayingScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    ));
  }

  void notifyMusicChange() {
    _musicChangeController.add(null);
  }
}
