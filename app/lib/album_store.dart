// 第八十八批（人類指示）：相簿——**只存本機 App 專屬目錄**，不送伺服器、
// 不要求「讀取所有照片」權限（用 file_picker 選檔 → 複製到 App 沙箱）。
// 保護隱私、舊裝置可跑。每張：id／本機路徑／標題／addedAt。
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'app_settings.dart';

const String kAlbumKey = 'local_album';

class AlbumPhoto {
  const AlbumPhoto({
    required this.id,
    required this.path,
    required this.title,
    required this.addedAt,
  });

  final String id;
  final String path;
  final String title;
  final int addedAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'path': path,
        'title': title,
        'addedAt': addedAt,
      };

  static AlbumPhoto? fromJson(Object? v) {
    if (v is! Map) return null;
    final id = v['id'];
    final path = v['path'];
    final title = v['title'];
    final ts = v['addedAt'];
    if (id is! String || path is! String || title is! String || ts is! int) {
      return null;
    }
    return AlbumPhoto(id: id, path: path, title: title, addedAt: ts);
  }
}

List<AlbumPhoto> parseAlbum(String? raw) {
  if (raw == null || raw.isEmpty) return <AlbumPhoto>[];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <AlbumPhoto>[];
    return decoded
        .map(AlbumPhoto.fromJson)
        .whereType<AlbumPhoto>()
        .toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  } on Object {
    return <AlbumPhoto>[];
  }
}

String encodeAlbum(List<AlbumPhoto> photos) =>
    jsonEncode(<Object?>[for (final p in photos) p.toJson()]);

Future<Directory> _albumDir() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory('${base.path}/album');
  if (!dir.existsSync()) await dir.create(recursive: true);
  return dir;
}

Future<List<AlbumPhoto>> loadAlbum() async {
  try {
    final photos = parseAlbum(await AppSettings.get(kAlbumKey));
    // 過濾掉檔已不存在者（不自動刪 kv，避免檔案短暫不可見即消失）。
    return photos.where((p) => File(p.path).existsSync()).toList();
  } on Object {
    return <AlbumPhoto>[];
  }
}

Future<void> saveAlbum(List<AlbumPhoto> photos) async {
  await AppSettings.set(kAlbumKey, encodeAlbum(photos));
}

/// 從外部路徑複製一張進相簿（回傳新 AlbumPhoto）。
Future<AlbumPhoto> importPhoto(String sourcePath, {String? title}) async {
  final dir = await _albumDir();
  final id = '${DateTime.now().microsecondsSinceEpoch}';
  final ext = sourcePath.contains('.')
      ? sourcePath.substring(sourcePath.lastIndexOf('.'))
      : '.jpg';
  final dest = File('${dir.path}/$id$ext');
  await File(sourcePath).copy(dest.path);
  return AlbumPhoto(
    id: id,
    path: dest.path,
    title: title ?? dest.uri.pathSegments.last,
    addedAt: DateTime.now().millisecondsSinceEpoch,
  );
}

/// 刪除（同時刪檔＋kv）。
Future<void> deletePhoto(AlbumPhoto photo) async {
  try {
    final f = File(photo.path);
    if (f.existsSync()) await f.delete();
  } on Object {
    // 檔案已不存在 → 忽略。
  }
  final all = await loadAlbum();
  await saveAlbum(all.where((p) => p.id != photo.id).toList());
}

/// 清理不再被 kv References 的孤檔（可選，設定頁手動呼叫）。
Future<int> cleanOrphanPhotos() async {
  final dir = await _albumDir();
  final referenced = (await loadAlbum()).map((p) => p.path).toSet();
  var removed = 0;
  for (final f in dir.listSync()) {
    if (f is File && !referenced.contains(f.path)) {
      try {
        await f.delete();
        removed++;
      } on Object {
        // 忽略。
      }
    }
  }
  return removed;
}
