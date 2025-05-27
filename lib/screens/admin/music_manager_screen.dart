import 'package:flutter/material.dart';
import '../../../models/music.dart';
import '../../../providers/music_provider.dart';

class MusicManagerScreen extends StatefulWidget {
  const MusicManagerScreen({Key? key}) : super(key: key);

  static const routeName = '/admin/musics';

  @override
  State<MusicManagerScreen> createState() => _MusicManagerScreenState();
}

class _MusicManagerScreenState extends State<MusicManagerScreen> {
  late List<Music> _musics;

  @override
  void initState() {
    super.initState();
    _loadMusics();
  }

  Future<void> _loadMusics() async {
    await MusicProvider.instance.fetchAndSetData();
    setState(() {
      _musics = MusicProvider.instance.list;
    });
  }

  void _showMusicForm({Music? existing}) {
    final isEdit = existing != null;

    final titleController = TextEditingController(text: existing?.title ?? '');
    final artistController =
        TextEditingController(text: existing?.artists ?? '');
    final imageUrlController =
        TextEditingController(text: existing?.imageUrl ?? '');
    final thumbnailUrlController =
        TextEditingController(text: existing?.thumbnailUrl ?? '');
    final audioUrlController =
        TextEditingController(text: existing?.audioUrl ?? '');
    final durationController =
        TextEditingController(text: existing?.duration.toString() ?? '');
    final lyricsController =
        TextEditingController(text: existing?.lyrics ?? '');

    showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                isEdit ? "Sửa bài nhạc" : "Thêm bài nhạc",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Tên bài hát"),
              ),
              TextField(
                controller: artistController,
                decoration: const InputDecoration(labelText: "Nghệ sĩ"),
              ),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(labelText: "Image URL"),
              ),
              TextField(
                controller: thumbnailUrlController,
                decoration: const InputDecoration(labelText: "Thumbnail URL"),
              ),
              TextField(
                controller: audioUrlController,
                decoration: const InputDecoration(labelText: "Audio URL"),
              ),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: "Thời lượng (s)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: lyricsController,
                decoration: const InputDecoration(labelText: "Lyrics"),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Hủy")),
                  ElevatedButton(
                    onPressed: () async {
                      final music = Music(
                        id: existing?.id ?? '',
                        title: titleController.text,
                        artists: artistController.text,
                        imageUrl: imageUrlController.text.trim(),
                        thumbnailUrl: thumbnailUrlController.text.trim(),
                        audioUrl: audioUrlController.text.trim(),
                        duration:
                            int.tryParse(durationController.text.trim()) ?? 0,
                        lyrics: lyricsController.text.trim().isEmpty
                            ? 'Lời bài hát sẽ được cập nhật'
                            : lyricsController.text.trim(),
                      );

                      if (isEdit) {
                        await MusicProvider.instance.updateMusic(music);
                      } else {
                        await MusicProvider.instance.addMusic(music);
                      }

                      Navigator.pop(ctx);
                      _loadMusics();
                    },
                    child: Text(isEdit ? "Lưu" : "Thêm"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _deleteMusic(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc muốn xoá bài nhạc này không?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Hủy")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Xoá")),
        ],
      ),
    );

    if (confirm ?? false) {
      await MusicProvider.instance.deleteMusic(id);
      _loadMusics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🎶 Quản lý bài nhạc"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showMusicForm(),
          )
        ],
      ),
      body: FutureBuilder(
        future: MusicProvider.instance.fetchAndSetData(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Có lỗi xảy ra: ${snapshot.error}'));
          } else if (_musics.isEmpty) {
            return const Center(
              child: Text("Chưa có bài nhạc nào"),
            );
          } else {
            return ListView.builder(
              itemCount: _musics.length,
              itemBuilder: (ctx, index) {
                final music = _musics[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        music.thumbnailUrl,
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, error, stackTrace) =>
                            const Icon(Icons.music_note),
                      ),
                    ),
                    title: Text(
                      music.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(music.artists),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showMusicForm(existing: music),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteMusic(music.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
