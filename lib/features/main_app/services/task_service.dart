import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../core/services/notification_service.dart';
import '../data/models/task.dart';
import 'category_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CategoryService _categoryService = CategoryService();

  // _tasksCollection sẽ được khởi tạo lại mỗi khi cần để đảm bảo đúng user
  CollectionReference get _tasksCollection {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User is not logged in.");
    }
    return _firestore.collection('users').doc(user.uid).collection('tasks');
  }

  Stream<QuerySnapshot> getTasksStream({String? categoryId}) {
    Query query = _tasksCollection.orderBy('createdAt', descending: true);
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    return query.snapshots();
  }

  Future<void> addTask(Task task, String categoryId) async {
    final docRef = await _tasksCollection.add({
      'title': task.title,
      // 'time': task.time,
      'categoryName': task.category,
      'categoryId': categoryId,
      'colorValue': task.color.value,
      'isCompleted': task.isCompleted,
      'createdAt': FieldValue.serverTimestamp(),
      'dueTimestamp': task.dueTimestamp,
      'dueDate': task.dueDate,
      'isAllDay': task.isAllDay,
    });

    // Lập lịch thông báo
    // Chỉ lập lịch thông báo nếu task có thời gian cụ thể
    if (task.dueTimestamp != null) {
      NotificationService.scheduleNotification(
        id: docRef.id.hashCode,
        title: 'Task Reminder: ${task.title}',
        body: 'Your task is due now.',
        scheduledTime: task.dueTimestamp!.toDate(),
      );
    }


  }

  Future<void> updateTaskCompletion(String taskId, String categoryId, bool isCompleted) async {
    // Chỉ cần cập nhật trạng thái của task
    await _tasksCollection.doc(taskId).update({'isCompleted': isCompleted});
  }

  Future<void> deleteTask(String taskId, String categoryId) async {
    // Chỉ cần xóa task
    await _tasksCollection.doc(taskId).delete();
  }

  Future<void> deleteTasksForCategory(String categoryName) async {
    final querySnapshot = await _tasksCollection.where('categoryName', isEqualTo: categoryName).get();
    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> updateTask(Task task, String oldCategoryId) async {
    if (task.id == null || task.categoryId == null) return;

    // Cập nhật dữ liệu của task trên Firestore
    await _tasksCollection.doc(task.id).update({
      'title': task.title,
      // 'time': task.time,
      'categoryName': task.category,
      'categoryId': task.categoryId,
      'colorValue': task.color.value,
      'dueTimestamp': task.dueTimestamp,
      'dueDate': task.dueDate,
      'isAllDay': task.isAllDay,
    });

    // Lập lịch lại thông báo với thời gian mới
    //    Sử dụng dueTimestamp.toDate() để có DateTime chính xác
    if (task.dueTimestamp != null) {
      NotificationService.scheduleNotification(
        id: task.id!.hashCode,
        title: 'Task Reminder: ${task.title}',
        body: 'Your task is due now.',
        scheduledTime: task.dueTimestamp!.toDate(),
      );
    }

  }

  Stream<QuerySnapshot> getTodaysTasksStream() {
    return _tasksCollection
        .where('isCompleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(4)
        .snapshots();
  }

  Stream<QuerySnapshot> getTasksForTodayStream() {
    // Lấy thời điểm hiện tại
    final DateTime now = DateTime.now();

    // Xác định thời điểm bắt đầu của ngày hôm nay
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);

    // Xác định thời điểm kết thúc của ngày hôm nay
    final DateTime endOfToday = startOfToday.add(const Duration(days: 1));

    // Truy vấn các task có dueTimestamp nằm trong khoảng từ đầu ngày đến cuối ngày
    return _tasksCollection
        .where('isCompleted', isEqualTo: false)
        .where('dueTimestamp', isGreaterThanOrEqualTo: startOfToday)
        .where('dueTimestamp', isLessThan: endOfToday)
        .orderBy('isAllDay', descending: false)
        .orderBy('dueTimestamp', descending: false)
        .limit(4)
        .snapshots();
  }

  Future<void> debugTasksForToday() async {
    final CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');

    final DateTime now = DateTime.now();
    final DateTime startOfDayLocal = DateTime(now.year, now.month, now.day);
    final DateTime endOfDayLocal = startOfDayLocal.add(const Duration(days: 1));

    final DateTime startUtc = startOfDayLocal.toUtc();
    final DateTime endUtc = endOfDayLocal.toUtc();

    print('=== DEBUG getTasksForToday START ===');
    print('now (local): $now');
    print('startOfDay (local): $startOfDayLocal');
    print('endOfDay (local): $endOfDayLocal');
    print('startOfDay (UTC)  : $startUtc');
    print('endOfDay (UTC)    : $endUtc');

    try {
      // 1) Show a sample of recent docs and inspect dueTimestamp field
      final sample = await tasks.orderBy('dueTimestamp', descending: true).limit(50).get();
      print('SAMPLE docs count: ${sample.size}');
      for (final doc in sample.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final raw = data['dueTimestamp'];
        print('--- docId: ${doc.id} ---');
        print(' raw field runtimeType: ${raw?.runtimeType}');
        if (raw == null) {
          print('  >> dueTimestamp: MISSING');
        } else if (raw is Timestamp) {
          final DateTime dt = raw.toDate();
          print('  >> Timestamp.toDate() -> dt (default): $dt');
          print('     dt.toLocal(): ${dt.toLocal()}');
          print('     dt.toUtc():   ${dt.toUtc()}');
          final bool inLocalRange = (dt.isAtSameMomentAs(startOfDayLocal) || dt.isAfter(startOfDayLocal)) && dt.isBefore(endOfDayLocal);
          final bool inUtcRange = (dt.toUtc().isAtSameMomentAs(startUtc) || dt.toUtc().isAfter(startUtc)) && dt.toUtc().isBefore(endUtc);
          print('     inLocalRange: $inLocalRange, inUtcRange: $inUtcRange');
        } else if (raw is DateTime) {
          final DateTime dt = raw;
          print('  >> DateTime stored directly: $dt / toUtc: ${dt.toUtc()}');
          final bool inLocalRange = (dt.isAtSameMomentAs(startOfDayLocal) || dt.isAfter(startOfDayLocal)) && dt.isBefore(endOfDayLocal);
          final bool inUtcRange = (dt.toUtc().isAtSameMomentAs(startUtc) || dt.toUtc().isAfter(startUtc)) && dt.toUtc().isBefore(endUtc);
          print('     inLocalRange: $inLocalRange, inUtcRange: $inUtcRange');
        } else {
          print('  >> Unknown stored type for dueTimestamp: $raw');
        }
        print('  title: ${data['title']}, categoryId: ${data['categoryId']}');
      }

      // 2) Run three variants of the "today" query and print counts
      // Variant A: use DateTime (local) directly
      final qA = await tasks
          .where('isCompleted', isEqualTo: false)
          .where('dueTimestamp', isGreaterThanOrEqualTo: startOfDayLocal)
          .where('dueTimestamp', isLessThan: endOfDayLocal)
          .get();
      print('Query A (DateTime local) returned: ${qA.size} docs');

      // Variant B: use Timestamp.fromDate(local)
      final qB = await tasks
          .where('isCompleted', isEqualTo: false)
          .where('dueTimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayLocal))
          .where('dueTimestamp', isLessThan: Timestamp.fromDate(endOfDayLocal))
          .get();
      print('Query B (Timestamp.fromDate(local)) returned: ${qB.size} docs');

      // Variant C: use Timestamp.fromDate(UTC)
      final qC = await tasks
          .where('isCompleted', isEqualTo: false)
          .where('dueTimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startUtc))
          .where('dueTimestamp', isLessThan: Timestamp.fromDate(endUtc))
          .get();
      print('Query C (Timestamp.fromDate(UTC)) returned: ${qC.size} docs');

      print('=== DEBUG getTasksForToday END ===');
    } catch (e, st) {
      print('DEBUG: error during debugTasksForToday: $e\n$st');
    }
  }

  Stream<int> getIncompleteTasksCountStreamForCategory(String categoryId) {
    return _tasksCollection
        .where('categoryId', isEqualTo: categoryId)
        .where('isCompleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length); // Trả về stream của số lượng document
  }

}