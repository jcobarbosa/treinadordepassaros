import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
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
    _initializePlayer();
    _initializeTimer();
  }

  Future<void> _initializePlayer() async {
    try {
      await loadFiles();
      await _setAudioSource(_audioUrls);
      await _player.setLoopMode(LoopMode.all);
      await _player.play();
    } catch (e) {
      print("Error initializing player: $e");
    }
  }

  Future<List<String>> loadFiles() async {
    _audioUrls = await getAudioFiles().then((files) {
      print("files ${files}");
      var minute2 = DateTime
          .now()
          .minute;
      var prefix = (minute2 % 2 == 0) ? "02-" : "07-";
      var list = files.where((file) => file.split("/").last.startsWith(prefix)).toList();
      print("list filtro: ${list}");
      return list;
    });
    return _audioUrls;
  }

  Future<void> _setAudioSource(List<String> urls) async {
    final audioSources = urls.map((url) => AudioSource.uri(Uri.parse(url), tag: url.split("/").last)).toList();
    print("audioSources: ${audioSources}");
    final playlist = ConcatenatingAudioSource(children: audioSources);
    await _player.setAudioSource(playlist);
  }

  Future<void> _rebuildPlaylist(List<String> newUrls) async {
    try {
      await _player.stop();
      await _setAudioSource(newUrls);
      await _player.play();
    } catch (e) {
      print("Error rebuilding playlist: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Treinador de Passarinhos"),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _updatePlaylist,
            child: Text("Rebuild Playlist"),
          ),
          Expanded(
            child: StreamBuilder<SequenceState>(
              stream: _player.sequenceStateStream.where((state) => state != null).cast<SequenceState>(),
              builder: (context, snapshot) {
                final sequenceState = snapshot.data;
                final sequence = sequenceState?.sequence;
                final currentIndex = sequenceState?.currentIndex;
                return ListView.builder(
                  itemCount: sequence?.length ?? 0,
                  itemBuilder: (context, index) {
                    final isPlaying = index == currentIndex;
                    return ListTile(
                      title: Text(
                        sequence![index].tag as String,
                        style: TextStyle(
                          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_player.playing) {
            await _player.pause();
          } else {
            await _player.play();
          }
        },
        child: Icon(_player.playing ? Icons.pause : Icons.play_arrow),
      ),
    );
  }

  void _updatePlaylist() async {
      var newAudioUrls = await loadFiles();
      await _rebuildPlaylist(newAudioUrls);
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
      _updatePlaylist();
      _initializeTimer();
    });
  }
}
