// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';

Future<void> openAttachment(Uint8List bytes, String name, String mime) async {
  final url = html.Url.createObjectUrlFromBlob(html.Blob([bytes], mime));
  final anchor = html.AnchorElement(href: url)..download = name;
  anchor.click();
  Timer(const Duration(minutes: 1), () => html.Url.revokeObjectUrl(url));
}
