// Browser adapter only; report components never depend on browser APIs.
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadPdf(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)..download = filename;
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  // Let the browser take ownership of the download before releasing the blob.
  Future<void>.delayed(
      const Duration(seconds: 30), () => html.Url.revokeObjectUrl(url));
}
