import 'dart:io';
import 'dart:typed_data';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

Future<void> openAttachment(Uint8List bytes, String name, String mime) async {
  final temp = await getTemporaryDirectory();
  final directory =
      await Directory('${temp.path}/yr-attachment-${const Uuid().v4()}')
          .create();
  final safeName = name
      .replaceAll(RegExp(r'[^\w\u4e00-\u9fff. -]'), '_')
      .replaceAll('..', '_');
  final file =
      File('${directory.path}/${safeName.isEmpty ? 'attachment' : safeName}');
  await file.writeAsBytes(bytes, flush: true);
  final result = await OpenFilex.open(file.path, type: mime);
  if (result.type != ResultType.done) {
    await file.delete();
    await directory.delete();
    throw StateError('無法開啟檔案，請確認裝置有支援此格式的 App');
  }
  // Native viewers may still be reading after open returns. The OS owns this temporary copy.
}
