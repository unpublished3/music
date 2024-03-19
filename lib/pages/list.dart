// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, must_be_immutable

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:music/pages/player.dart';
import 'package:music/providers/metadata_provider.dart';
import 'package:music/providers/player_provider.dart';
import 'package:music/utils/metadata.dart';
import 'package:page_transition/page_transition.dart';
import 'dart:io';
import 'package:provider/provider.dart';

import "package:music/utils/format_data.dart" as formatter;

class ListUI extends StatelessWidget {
  File file;

  ListUI({super.key, required this.file});

  late Metadata audioMetadata;

  late RequiredMetadata requiredMetadata;

  Future<void> setMetadata(context) async {
    requiredMetadata = await getMetadata(file.path);
    updateMetadataProvider(context);
  }

  void updateMetadataProvider(context) {
    MetadataProvider myProvider =
        Provider.of<MetadataProvider>(context, listen: false);
    myProvider
        .addRequiredMetadata(newMetadataMap: {file.path: requiredMetadata});
  }

  void setPlayer(context) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    PlayerUI player = PlayerUI(file: file);
    PlayerUI currentPlayer = playerProvider.player;
    currentPlayer.player.pause();

    Navigator.push(context,
        PageTransition(child: player, type: PageTransitionType.bottomToTop));
    playerProvider.changePlayer(newPlayer: player);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: setMetadata(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while waiting for permission result
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          // Handle any errors
          return Scaffold(body: Center(child: Text('Error occurred')));
        } else {
          // Permission granted or denied
          return GestureDetector(
              onTap: () => {setPlayer(context)},
              child: ListElement(
                  albumArt: requiredMetadata.albumArt,
                  trackName:
                      formatter.formatName(requiredMetadata.trackName, 30),
                  artistName: requiredMetadata.artistName,
                  trackDuration: formatter
                      .formatDuration(requiredMetadata.trackDuration)));
        }
      },
    );
  }
}

class ListElement extends StatelessWidget {
  const ListElement({
    super.key,
    required this.albumArt,
    required this.trackName,
    required this.artistName,
    required this.trackDuration,
  });

  final Image albumArt;
  final String trackName;
  final String artistName;
  final String trackDuration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20, left: 20, top: 15, bottom: 0),
      child: Container(
        padding: EdgeInsets.all(12),
        height: MediaQuery.of(context).size.height * 0.1,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AlbumArt(albumArt: albumArt),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  child: Column(
                    children: [Text(trackName), Text(artistName)],
                  ),
                )
              ],
            ),
            Text(trackDuration)
          ],
        ),
      ),
    );
  }
}

class AlbumArt extends StatelessWidget {
  const AlbumArt({
    super.key,
    required this.albumArt,
  });

  final Image albumArt;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: MediaQuery.of(context).size.height * 0.07,
        decoration: BoxDecoration(
          image: DecorationImage(image: albumArt.image, fit: BoxFit.contain),
          borderRadius: BorderRadius.circular(100),
        ));
  }
}
