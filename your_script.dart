import 'dart:io';

void main() {
  final dir = Directory('assets/avatars');
  final files = dir.listSync();

  for (var file in files) {
    if (file is File && file.path.endsWith('.svg')) {
      final fileName = file.path.replaceAll('\\', '/'); // xử lý Windows path
      print("    '$fileName',");
    }
  }
}
