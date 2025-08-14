import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NoteService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _notesCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notes');
  }

  // Lấy stream của notes, có thể sắp xếp
  Stream<QuerySnapshot> getNotesStream({String orderBy = 'createdAt', bool descending = true}) {
    return _notesCollection.orderBy(orderBy, descending: descending).snapshots();
  }

  // Thêm note
  Future<void> addNote(Map<String, dynamic> noteData) async {
    await _notesCollection.add(noteData);
  }

  // Cập nhật note
  Future<void> updateNote(String noteId, Map<String, dynamic> noteData) async {
    await _notesCollection.doc(noteId).update(noteData);
  }

  // Xóa note
  Future<void> deleteNote(String noteId) async {
    await _notesCollection.doc(noteId).delete();
  }

  Future<void> deleteMultipleNotes(Set<String> noteIds) async {
    final batch = _notesCollection.firestore.batch();
    for (final id in noteIds) {
      batch.delete(_notesCollection.doc(id));
    }
    await batch.commit();
  }

  Future<void> updateNoteFavoriteStatus(String noteId, bool isFavorite) async {
    await _notesCollection.doc(noteId).update({
      'isFavorite': isFavorite,
    });
  }

  Stream<QuerySnapshot> getLatestNoteStream() {
    return _notesCollection
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .snapshots();
  }

}