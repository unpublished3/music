import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

class PlaylistProvider extends ChangeNotifier {
  final List<File> _playlist = [];
  final List<File> _shuffledPlaylist = [];
  String _current = "none";
  bool _mode = false;

  List<File> get playlist =>
      !_mode ? _playlist.toList() : _shuffledPlaylist.toList();
  bool get mode => _mode;

  void addFiles(List<File> files) {
    if (_playlist.length != files.length) {
      _playlist.addAll(files);
      _shuffledPlaylist.addAll(files);
    }
    notifyListeners();
  }

  void shuffle() {
    if (_mode == false) {
      final random = Random();
      _shuffledPlaylist.shuffle(random);
      _mode = true;
    } else {
      _mode = false;
    }
    notifyListeners();
  }

  void setCurrent(String path) {
    _current = path;
    notifyListeners();
  }

  String get current => _current;
}
