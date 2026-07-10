import 'package:acg_todo/domain/entities/folder.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FolderAdapter extends TypeAdapter<Folder> {
  @override
  final int typeId = 2; // 1 = NotificationAdapter

  @override
  Folder read(BinaryReader reader) {
    final fields = reader.readMap();
    return Folder(
      id: fields['id'] as String,
      name: fields['name'] as String,
      sortOrder: fields['sortOrder'] as int? ?? 0,
      colorValue: fields['colorValue'] as int?,
      createdAt: fields['createdAt'] != null
          ? DateTime.parse(fields['createdAt'] as String)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, Folder obj) {
    writer.writeMap({
      'id': obj.id,
      'name': obj.name,
      'sortOrder': obj.sortOrder,
      'colorValue': obj.colorValue,
      'createdAt': obj.createdAt?.toIso8601String(),
    });
  }
}
