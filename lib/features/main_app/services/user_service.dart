import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy tham chiếu đến document của người dùng hiện tại
  DocumentReference get _userDocument {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return _firestore.collection('users').doc(user.uid);
  }

  // Lấy dữ liệu profile của người dùng (dưới dạng stream để tự động cập nhật)
  Stream<DocumentSnapshot> getUserProfileStream() {
    return _userDocument.snapshots();
  }

  // Cập nhật profile của người dùng
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    // Cập nhật displayName trong Firebase Auth để đồng bộ
    if (data['displayName'] != null) {
      await _auth.currentUser?.updateDisplayName(data['displayName']);
    }
    // Cập nhật dữ liệu trong Firestore
    await _userDocument.set(data, SetOptions(merge: true));
  }
}