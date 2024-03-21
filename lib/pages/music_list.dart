// ignore_for_file: prefer_const_constructors_in_immutables, prefer_const_constructors

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:music/pages/list.dart';
import 'package:music/providers/files_provider.dart';
import 'package:music/providers/metadata_provider.dart';
import 'package:music/providers/playlist_provider.dart';

import 'package:music/utils/find_music_files.dart';
import 'package:music/utils/metadata.dart';
import 'package:provider/provider.dart';

class MusicList extends StatelessWidget {
  MusicList({super.key});

  Future<void> updateMusicFiles(context) async {
    FilesProvider filesProvider =
        Provider.of<FilesProvider>(context, listen: false);
    MetadataProvider metadataProvider =
        Provider.of<MetadataProvider>(context, listen: false);
    PlaylistProvider playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);

    List<File> files = await findMp3Files();

    for (File file in files) {
      await setMetadata(context, file, metadataProvider);
    }

    files = sortByName(context, metadataProvider, files);

    filesProvider.addFiles(files);
    playlistProvider.addFiles(files);
  }

  Future<void> setMetadata(
      context, File file, MetadataProvider myProvider) async {
    RequiredMetadata requiredMetadata = await getMetadata(file.path);

    myProvider
        .addRequiredMetadata(newMetadataMap: {file.path: requiredMetadata});
  }

  List<File> sortByName(
      context, MetadataProvider provider, List<File> musicFiles) {
    musicFiles.sort((fileA, fileB) {
      final nameA = provider.metadataMap[fileA.path]?.trackName;
      final nameB = provider.metadataMap[fileB.path]?.trackName;
      if (nameA != null && nameB != null) {
        return nameA.compareTo(nameB);
      }
      return -1;
    });

    return musicFiles;
  }

  @override
  Widget build(BuildContext context) {
    FilesProvider filesProvider =
        Provider.of<FilesProvider>(context, listen: false);
    List<File> musicFiles = filesProvider.musicFiles;

    return FutureBuilder<void>(
      future: updateMusicFiles(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while waiting for permission result
          return Scaffold();
        } else if (snapshot.hasError) {
          // Handle any errors
          return Scaffold(body: Center(child: Text('Error occurred')));
        } else {
          return CupertinoScrollbar(
            child: ListView.builder(
                itemCount: musicFiles.length,
                itemBuilder: ((context, index) =>
                    ListUI(file: musicFiles[index]))),
          );
        }
      },
    );
  }
}
