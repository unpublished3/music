// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, must_be_immutable, prefer_const_constructors_in_immutables

import "package:flutter/material.dart";
import 'dart:io';
import "package:audioplayers/audioplayers.dart";
import "package:music/providers/player_status_provider.dart";
import "package:music/providers/player_provider.dart";
import "package:music/providers/playlist_provider.dart";

import "package:music/utils/format_data.dart" as formatter;
import "package:page_transition/page_transition.dart";
import "package:provider/provider.dart";

class PlayerUI extends StatefulWidget {
  File file;
  final player = AudioPlayer();
  PlayerUI({super.key, required this.file});

  @override
  State<PlayerUI> createState() => _PlayerUIState();
}

class _PlayerUIState extends State<PlayerUI> {
  // Application State

  late PlayerStatusProvider playerStatusProvider;

  @override
  void initState() {
    super.initState();
    setUrl();

    playerStatusProvider =
        Provider.of<PlayerStatusProvider>(context, listen: false);
    playerStatusProvider.set(context, widget.file.path);


    widget.player.onPositionChanged.listen((newPostion) {
      if (mounted) {
        playerStatusProvider.changePosition(newPostion, playerStatusProvider.duration);
      }
    });

    widget.player.onPlayerComplete.listen((event) async {
      if (!playerStatusProvider.repeat) {
        skipNext(context);
      }
    });
  }

  void setUrl() async {
    await widget.player.setSourceDeviceFile(widget.file.path);
    if (mounted) {
      playerStatusProvider.alterPlayStatus(widget.player);
    }
  }

  int seekLocation(double value, Duration? duration) {
    if (duration != null) {
      return (value * duration.inSeconds).toInt();
    }
    return 0;
  }

  void skipNext(context) {
    List<File> musicFiles =
        Provider.of<PlaylistProvider>(context, listen: false).playlist;
    int index = musicFiles.indexOf(widget.file);
    if (index == musicFiles.length) {
      index = -1;
    }

    int nextMusicIndex = (index + 1) % musicFiles.length;
    File nextMusicFile = musicFiles[nextMusicIndex];

    nagivateToNewPlayer(context, nextMusicFile, 0);
  }

  void skipPrevious() {
    List<File> musicFiles =
        Provider.of<PlaylistProvider>(context, listen: false).playlist;
    int index = musicFiles.indexOf(widget.file);

    int previousMusicIndex =
        (index - 1 + musicFiles.length) % musicFiles.length;
    File previousMusicFile = musicFiles[previousMusicIndex];

    nagivateToNewPlayer(context, previousMusicFile, 1);
  }

  void nagivateToNewPlayer(context, File music, int direction) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    PlayerUI player = PlayerUI(file: music);
    PlayerUI currentPlayer = playerProvider.player;
    currentPlayer.player.pause();

    Navigator.push(
        context,
        PageTransition(
            child: player,
            type: direction == 1
                ? PageTransitionType.leftToRightWithFade
                : PageTransitionType.rightToLeftWithFade));
    playerProvider.changePlayer(newPlayer: player);
  }

  void nagivateToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void handleShuffle(context) {
    PlaylistProvider playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);
    playlistProvider.shuffle();
  }

  void handleLoop() {
    playerStatusProvider.alterRepetition();
    if (playerStatusProvider.repeat) {
      widget.player.setReleaseMode(ReleaseMode.loop);
    } else {
      widget.player.setReleaseMode(ReleaseMode.release);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool mode = Provider.of<PlaylistProvider>(context).mode;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          nagivateToHome();
        }
      },
      child: Consumer<PlayerStatusProvider>(
        builder: (context, value, child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            appBar: AppBar(
              leading: Padding(
                padding: EdgeInsets.only(left: 25),
                child: GestureDetector(
                  onTap: () => {nagivateToHome()},
                  child: Icon(
                    Icons.keyboard_arrow_down_sharp,
                    size: 40,
                  ),
                ),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.only(
                  left: 50, right: 50, top: 50, bottom: 180),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Music Image
                  GestureDetector(
                    onPanUpdate: (details) {
                      if (details.delta.dx.abs() > details.delta.dy.abs()) {
                        if (details.delta.dx < 0) {
                          skipNext(context);
                        } else if (details.delta.dx > 0) {
                          skipPrevious();
                        }
                      }
                    },
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                          image: DecorationImage(image: playerStatusProvider.albumArt.image)),
                    ),
                  ),

                  Column(
                    children: [Text(playerStatusProvider.trackName), Text(playerStatusProvider.artistName)],
                  ),

                  Column(
                    children: [
                      Slider(
                        onChanged: (double value) async {
                          await widget.player.seek(
                              Duration(seconds: seekLocation(value, playerStatusProvider.duration)));
                        },
                        value: value.percentageComplete,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatter.formatDuration(value.current)),
                          Text(formatter.formatDuration(playerStatusProvider.duration))
                        ],
                      )
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () => {handleShuffle(context)},
                        child: Icon(
                          Icons.shuffle,
                          color: !mode ? Colors.black : Colors.purple[600],
                        ),
                      ),
                      GestureDetector(
                          onTap: () => {skipPrevious()},
                          child: Icon(Icons.skip_previous)),
                      ElevatedButton(
                        onPressed: () {
                          if (mounted) {
                            playerStatusProvider
                                .alterPlayStatus(widget.player);
                          }
                        },
                        child: Icon(
                            value.isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                      GestureDetector(
                          onTap: () => {skipNext(context)},
                          child: Icon(Icons.skip_next)),
                      GestureDetector(
                        onTap: handleLoop,
                        child: Icon(
                          Icons.repeat_rounded,
                          color:
                              !value.repeat ? Colors.black : Colors.purple[600],
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
