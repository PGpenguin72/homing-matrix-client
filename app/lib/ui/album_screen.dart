// 第八十八批：相簿畫面（本機相簿，只存 App 沙箱）。
import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../album_store.dart';
import '../l10n/app_strings.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  List<AlbumPhoto> _photos = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final photos = await loadAlbum();
    if (!mounted) return;
    setState(() {
      _photos = photos;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final picked = await FilePicker.pickFiles(type: FileType.image);
    if (picked.isEmpty) return;
    var added = 0;
    for (final f in picked) {
      if (f.path == null) continue;
      await importPhoto(f.path!);
      added++;
    }
    if (added > 0) unawaited(_load());
  }

  Future<void> _open(AlbumPhoto p) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(p.title)),
          body: Center(child: Image.file(File(p.path), fit: BoxFit.contain)),
        ),
      ),
    );
  }

  Future<void> _delete(AlbumPhoto p) async {
    await deletePhoto(p);
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.t('相簿'))),
      floatingActionButton: FloatingActionButton(
        tooltip: S.t('加入照片'),
        onPressed: () => unawaited(_add()),
        child: const Icon(Icons.add_photo_alternate),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? Center(child: Text(S.t('相簿是空的')))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, i) {
                    final p = _photos[i];
                    return GestureDetector(
                      onTap: () => unawaited(_open(p)),
                      onLongPress: () => unawaited(_delete(p)),
                      child: GridTile(
                        footer: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            p.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                        child: Image.file(File(p.path), fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
    );
  }
}
