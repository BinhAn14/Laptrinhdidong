import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zing_mp3_clone/controllers/player_controller.dart';
import 'package:zing_mp3_clone/models/music.dart';

class DownloadedMusicScreen extends StatefulWidget {
  const DownloadedMusicScreen({Key? key}) : super(key: key);

  @override
  _DownloadedMusicScreenState createState() => _DownloadedMusicScreenState();
}

class _DownloadedMusicScreenState extends State<DownloadedMusicScreen> {
  late Stream<List<String>> downloadedMusicsStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      downloadedMusicsStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) {
        final data = snapshot.data();
        if (data != null && data['downloadedMusics'] != null) {
          return List<String>.from(data['downloadedMusics']);
        }
        return [];
      });
    } else {
      downloadedMusicsStream = Stream.value([]);
    }
  }

  Future<Music?> _getMusicInfo(String musicId) async {
    final doc = await FirebaseFirestore.instance
        .collection('musics')
        .doc(musicId)
        .get();

    if (doc.exists) {
      return Music.fromMap(doc.data()!, doc.id);
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = PlayerController.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhạc đã tải về'),
      ),
      body: StreamBuilder<List<String>>(
        stream: downloadedMusicsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Đã xảy ra lỗi'));
          }

          final downloadedMusics = snapshot.data ?? [];

          if (downloadedMusics.isEmpty) {
            return const Center(child: Text('Chưa có nhạc nào đã tải về.'));
          }

          return ListView.builder(
            itemCount: downloadedMusics.length,
            itemBuilder: (ctx, index) {
              final musicId = downloadedMusics[index];

              return FutureBuilder<Music?>(
                future: _getMusicInfo(musicId),
                builder: (ctx, musicSnapshot) {
                  if (musicSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const ListTile(title: Text('Đang tải...'));
                  }

                  if (musicSnapshot.hasError || musicSnapshot.data == null) {
                    return const ListTile(
                        title: Text('Lỗi hoặc không tìm thấy nhạc'));
                  }

                  final music = musicSnapshot.data!;

                  return ListTile(
                    leading: const Icon(Icons.music_note),
                    title: Text(music.title),
                    subtitle: Text('Ca sĩ: ${music.artists}'),
                    onTap: () {
                      controller.setMusic(music);
                      Navigator.of(context).pushNamed('/playing');
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
