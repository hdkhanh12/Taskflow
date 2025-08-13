import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String? id;
  final String title;
  final String contentJson; // Nội dung sẽ được lưu dưới dạng JSON
  final int colorValue;
  final bool isFavorite;
  final Timestamp createdAt;

  Note({
    this.id,
    required this.title,
    required this.contentJson,
    required this.colorValue,
    this.isFavorite = false,
    required this.createdAt,
  });
}