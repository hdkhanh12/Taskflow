import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_todo_app/features/main_app/services/task_service.dart';
import '../data/models/category.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CollectionReference get _categoriesCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return _firestore.collection('users').doc(user.uid).collection('categories');
  }

  // Lấy stream của tất cả các category
  Stream<QuerySnapshot> getCategoriesStream() {
    return _categoriesCollection.snapshots();
  }

  // Thêm một category mới
  Future<void> addCategory(Category category) async {
    await _categoriesCollection.add({
      'name': category.name,
      'iconPath': category.iconPath,
      'colorValue': category.color.value,
      'taskCount': 0, // Tạm thời
    });
  }

  // Cập nhật category
  Future<void> updateCategory(String categoryId, Category category) async {
    await _categoriesCollection.doc(categoryId).update({
      'name': category.name,
      'iconPath': category.iconPath,
      'colorValue': category.color.value,
    });
  }

  // Xóa category
  Future<void> deleteCategory(String categoryId, String categoryName) async {
    final taskService = TaskService();
    // 1. Xóa tất cả các task liên quan trước
    await taskService.deleteTasksForCategory(categoryName);
    // 2. Sau đó mới xóa category
    await _categoriesCollection.doc(categoryId).delete();
  }

  Future<void> updateTaskCount(String categoryId, int increment) async {
    await _categoriesCollection.doc(categoryId).update({
      'taskCount': FieldValue.increment(increment),
    });
  }

  DocumentReference getCategoryReference(String categoryId) {
    return _categoriesCollection.doc(categoryId);
  }
}