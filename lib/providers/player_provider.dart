import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:music/pages/player.dart';
import 'package:music/providers/metadata_provider.dart';
import 'package:music/providers/playlist_provider.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class PlayerProvider extends ChangeNotifier {
  PlayerUI _player = PlayerUI();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _uuid = const Uuid();
  final Completer<bool> _sourcesLoaded = Completer<bool>();

  PlayerUI get player => _player;
  AudioPlayer get audioPlayer => _audioPlayer;

  void changePlayer({required PlayerUI newPlayer}) async {
    _player = newPlayer;
    notifyListeners();
  }

  void loadSources(context, {String? loadedPath, int? played}) async {
    List<UriAudioSource> audioSourceList = [];

    PlaylistProvider playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);

    for (File file in playlistProvider.playlist) {
      RequiredMetadata? map =
          Provider.of<MetadataProvider>(context, listen: false)
              .metadataMap[file.path];
      final audioMetadata = await MetadataGod.readMetadata(file: file.path);
      Picture? picture = audioMetadata.picture;

      if (map != null) {
        String imagePath;

        if (picture != null) {
          imagePath = await _createFile(
              picture, basenameWithoutExtension(file.path), false);
        } else {
          Picture picture = Picture(
              mimeType: "image/jpeg",
              data: await getBytesFromAsset("assets/image.jpg"));
          imagePath = await _createFile(
              picture, basenameWithoutExtension(file.path), true);
        }

        imagePath = "file://$imagePath";

        audioSourceList.add(AudioSource.uri(
          Uri.file(file.path),
          // ignore: prefer_const_constructors
          tag: MediaItem(
              id: _uuid.v1(),
              title: map.trackName,
              artUri: Uri.parse(imagePath),
              artist: map.artistName),
        ));
      }
    }

    int? index;
    Duration? playedDuration;

    if (loadedPath != null) {
      index = playlistProvider.playlist
          .indexWhere((element) => element.path == loadedPath);
      playlistProvider.setCurrent(context, loadedPath);

      if (played != null) {
        playedDuration = Duration(milliseconds: played);
      }
    }

    AudioSource playlist = ConcatenatingAudioSource(children: audioSourceList);
    await audioPlayer.setAudioSource(playlist,
        initialIndex: index, initialPosition: playedDuration);
    _sourcesLoaded.complete(true);
  }

  void setUrl(context, {required String filePath}) async {
    await _sourcesLoaded.future;

    PlaylistProvider playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);

    int index = playlistProvider.playlist
        .indexWhere((element) => element.path == filePath);

    await audioPlayer.seek(Duration.zero, index: index);
    await audioPlayer.play();
  }

  Future<String> _createFile(Picture albumArt, String name, bool asset) async {
    final tempDir = Directory.systemTemp;
    final image = albumArt.data;

    final File file = asset
        ? File("${tempDir.path}/albumArtassetmusic.jpg")
        : File("${tempDir.path}/albumArt${name}music.jpg");

    file.writeAsBytes(image);

    return file.path;
  }

  Future<Uint8List> getBytesFromAsset(String assetPath) async {
    ByteData data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }
}
