import 'dart:io';

import 'package:path_provider/path_provider.dart';

const String customMusicDirectory = '/storage/emulated/0/music/passarinho';

Future<List<String>> getAudioFiles() async {
  Directory? musicDir = await getExternalStorageDirectory();

  if (musicDir != null) {
    String musicPath = customMusicDirectory;
    Directory musicDirectory = Directory(musicPath);
    return musicDirectory.listSync().where((file) => file.path.endsWith(".wav") || file.path.endsWith(".mp3") ).map((file) => file.path).toList();
  }

  return [];
}

Future<FileSystemEntity?> getScheduledPlaylist() async {
  Directory? musicDir = await getExternalStorageDirectory();

  if (musicDir != null) {
    String musicPath = customMusicDirectory;
    Directory musicDirectory = Directory(musicPath);
    return musicDirectory.listSync().where((file) => file.path.endsWith("programa_antonio.txt")).firstOrNull;
  }

  return null;
}