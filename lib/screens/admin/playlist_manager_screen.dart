import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/playlist.dart';

class PlaylistManagerScreen extends StatefulWidget {
  static const routeName = '/admin/playlists';

  const PlaylistManagerScreen({Key? key}) : super(key: key);

  @override
  State<PlaylistManagerScreen> createState() => _PlaylistManagerScreenState();
}

class _PlaylistManagerScreenState extends State<PlaylistManagerScreen> {
  List<Playlist> _playlists = [];
  Map<String, String> _selectedMusicMap = {};

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

  Future<void> _fetchPlaylists() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('playlists').get();
    setState(() {
      _playlists = snapshot.docs
          .map((doc) => Playlist.fromMapFirebase(doc.data(), doc.id))
          .toList();
    });
  }

  Future<Map<String, String>> _selectSongsDialog(
      BuildContext parentContext) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('musics').get();
    final musicMap = {
      for (var doc in snapshot.docs) doc.id: doc['title'] as String
    };
    Map<String, String> selectedMap = Map.of(_selectedMusicMap);

    return await showDialog<Map<String, String>>(
          context: parentContext,
          builder: (ctx) => AlertDialog(
            title: const Text('Chọn Bài Hát'),
            content: SingleChildScrollView(
              child: Column(
                children: musicMap.entries.map((entry) {
                  return StatefulBuilder(
                    builder: (ctx, setStateDialog) => CheckboxListTile(
                      title: Text(entry.value),
                      value: selectedMap.containsKey(entry.key),
                      onChanged: (selected) {
                        setStateDialog(() {
                          if (selected == true) {
                            selectedMap[entry.key] = entry.value;
                          } else {
                            selectedMap.remove(entry.key);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(selectedMap),
                child: const Text('Chọn'),
              ),
            ],
          ),
        ) ??
        {};
  }

  void _showPlaylistForm({Playlist? playlist}) async {
    final titleController = TextEditingController(text: playlist?.title ?? '');
    final imageUrlController =
        TextEditingController(text: playlist?.imageUrl ?? '');
    _selectedMusicMap = {};

    if (playlist != null && playlist.musicIDs.isNotEmpty) {
      final musicSnapshot = await FirebaseFirestore.instance
          .collection('musics')
          .where(FieldPath.documentId, whereIn: playlist.musicIDs)
          .get();
      setState(() {
        for (var doc in musicSnapshot.docs) {
          _selectedMusicMap[doc.id] = doc['title'] as String;
        }
      });
    }

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  playlist == null ? 'Thêm Playlist' : 'Chỉnh sửa Playlist',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Tên Playlist'),
                ),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.library_music),
                  label: const Text('Chọn Bài Hát'),
                  onPressed: () async {
                    final selected = await _selectSongsDialog(ctx);
                    setStateDialog(() {
                      _selectedMusicMap = selected;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _selectedMusicMap.isEmpty
                    ? const Text('Chưa chọn bài hát')
                    : Column(
                        children: _selectedMusicMap.values
                            .map((title) => ListTile(
                                  title: Text(title),
                                  leading: const Icon(Icons.music_note),
                                ))
                            .toList(),
                      ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu'),
                  onPressed: () async {
                    final newId = playlist?.id ??
                        FirebaseFirestore.instance
                            .collection('playlists')
                            .doc()
                            .id;

                    final newPlaylist = Playlist(
                      id: newId,
                      title: titleController.text,
                      imageUrl: imageUrlController.text,
                      musicIDs: _selectedMusicMap.keys.toList(),
                    );

                    await FirebaseFirestore.instance
                        .collection('playlists')
                        .doc(newId)
                        .set(newPlaylist.toFirestoreMap());

                    Navigator.of(ctx).pop();
                    _fetchPlaylists();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(playlist == null
                          ? 'Thêm playlist thành công!'
                          : 'Cập nhật playlist thành công!'),
                      backgroundColor: Colors.green,
                    ));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deletePlaylist(String id) async {
    await FirebaseFirestore.instance.collection('playlists').doc(id).delete();
    _fetchPlaylists();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Đã xóa playlist.'),
      backgroundColor: Colors.redAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Playlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPlaylistForm(),
          ),
        ],
      ),
      body: _playlists.isEmpty
          ? const Center(child: Text('Chưa có playlist nào.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: _playlists.length,
              itemBuilder: (ctx, index) {
                final playlist = _playlists[index];
                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: (playlist.imageUrl?.isNotEmpty == true)
                          ? Image.network(
                              playlist.imageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 40),
                            )
                          : const Icon(Icons.music_note, size: 40),
                    ),
                    title: Text(
                      playlist.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${playlist.musicIDs.length} bài nhạc'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () =>
                              _showPlaylistForm(playlist: playlist),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePlaylist(playlist.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
