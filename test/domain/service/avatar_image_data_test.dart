import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/avatar_image_data.dart';

void main() {
  test('a Web blob path gets JPEG metadata from its bytes', () async {
    final image = await AvatarImageData.fromFile(XFile.fromData(
      Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0, 0, 16, 74, 70]),
      path: 'blob:http://localhost/opaque-id',
    ));
    expect(image.contentType, 'image/jpeg');
    expect(image.extension, '.jpg');
  });

  test('resized PNG bytes override the original JPEG MIME and filename',
      () async {
    final image = await AvatarImageData.fromFile(XFile.fromData(
      Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
      path: 'photo.jpg',
      mimeType: 'image/jpeg',
    ));
    expect(image.contentType, 'image/png');
    expect(image.extension, '.png');
  });

  test('empty and non-image files cannot be uploaded as avatars', () async {
    await expectLater(AvatarImageData.fromFile(XFile.fromData(Uint8List(0))),
        throwsFormatException);
    await expectLater(
        AvatarImageData.fromFile(XFile.fromData(
            Uint8List.fromList('%PDF-1.7'.codeUnits),
            path: 'photo.jpg')),
        throwsFormatException);
  });
}
