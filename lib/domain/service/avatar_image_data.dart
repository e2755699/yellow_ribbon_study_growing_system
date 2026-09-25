import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class AvatarImageData {
  const AvatarImageData(this.bytes, this.contentType, this.extension);

  final Uint8List bytes;
  final String contentType;
  final String extension;

  static Future<AvatarImageData> fromFile(XFile file) async {
    final bytes = await file.readAsBytes();
    // Web paths are blob URLs. Resizing can also change the actual format,
    // so prefer the bytes over both the original name and reported MIME type.
    final type = lookupMimeType('', headerBytes: bytes) ??
        file.mimeType ??
        lookupMimeType(file.name);
    const extensions = {
      'image/jpeg': '.jpg',
      'image/png': '.png',
      'image/gif': '.gif',
      'image/webp': '.webp',
      'image/bmp': '.bmp',
    };
    final extension = extensions[type];
    if (bytes.isEmpty || extension == null) {
      throw const FormatException('請選擇 JPG、PNG、GIF、WebP 或 BMP 圖片');
    }
    return AvatarImageData(bytes, type!, extension);
  }
}
