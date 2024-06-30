import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:treinapassarinhos/fileUtils.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AudioPlayerScreen(),
    );
  }
}

class AudioPlayerScreen extends StatefulWidget {
  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  List<String> _audioUrls = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _buildPlaylist();
    _initializeTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Treinador de Passarinhos"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<SequenceState>(
              stream: _player.sequenceStateStream.where((state) => state != null).cast<SequenceState>(),
              builder: (context, snapshot) {
                if (_audioUrls.isNotEmpty) {
                  final sequenceState = snapshot.data;
                  final sequence = sequenceState?.sequence;
                  final currentIndex = sequenceState?.currentIndex;
                  return ListView.builder(
                    itemCount: sequence?.length ?? 0,
                    itemBuilder: (context, index) {
                      final isPlaying = index == currentIndex &&
                          _audioUrls.isNotEmpty;
                      return ListTile(
                        title: Text(
                          sequence![index].tag as String,
                          style: TextStyle(
                            fontWeight: isPlaying ? FontWeight.bold : FontWeight
                                .normal,
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return Padding(
                    child: Text("Sem agendamento"),
                    padding: new EdgeInsets.all(10.0),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buildPlaylist() async {
      await loadFiles().then((value) async {
        if (value.isNotEmpty) {
          await _playList();
        } else {
          setState(() {
            _audioUrls = [];
          });
          await _player.stop();
        }
      });
  }

  Future<void> _playList() async {
    try {
      await _setAudioSource(_audioUrls);
      await _player.setLoopMode(LoopMode.all);
      await _player.play();
    } catch (e) {
      print("Error rebuilding playlist: $e");
    }
  }

  Future<List<String>> loadFiles() async {
    var allAudioFiles = await getAudioFiles();
    var newPlaylist = await getScheduledPlaylist();

    List<String> list = [];
    
    // newPlaylist.firstWhere((element) {
    newPlaylist.forEach((element) {
      var dateTimeNow = DateTime.now();
      var currentTimestamp = "${(dateTimeNow.hour.toString()).padLeft(2,"0")}${(dateTimeNow.minute.toString()).padLeft(2,"0")}";

      var schedule = element.split(",");

      var startTime = schedule[0].replaceAll(":", "");
      var endTime = schedule[1].replaceAll(":", "");

      if (currentTimestamp.compareTo(startTime) >= 0 && currentTimestamp.compareTo(endTime) < 0) {
        var audioTracks = schedule[2].split(";");
        list = allAudioFiles.where((audio) => audioTracks.contains(audio.split("/").last)).toList();
      }
    });

    setState(() {
      _audioUrls = list;
    });

    return list;
  }

  Future<void> _setAudioSource(List<String> urls) async {
    final audioSources = urls.map((url) => AudioSource.uri(Uri.parse(url), tag: url.split("/").last)).toList();
    final playlist = ConcatenatingAudioSource(children: audioSources);
    await _player.setAudioSource(playlist);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _initializeTimer() {
    if (_timer  != null) {
      _timer?.cancel();
    }
    _timer = createTimer();
  }

  Timer createTimer() {
    return Timer.periodic(Duration(seconds: (60 - DateTime.now().second)), (timer) {
      print("Agendamento em execução ${DateTime.now()}");
      _buildPlaylist();
      _initializeTimer();
    });
  }

  Future<void> _requestPermission() async {
    var storageStatus = await Permission.storage.status;
    if (storageStatus.isDenied) {
      await Permission.storage.request();
    }
  }
}
