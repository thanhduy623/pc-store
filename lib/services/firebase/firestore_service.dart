import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Thêm vào database với ID tự động và nhận lại đối tượng vừa tạo
  Future<Map<String, dynamic>> addWithAutoId(String collection, Map<String, dynamic> json) async {
    DocumentReference docRef = await _db.collection(collection).add(json);
    DocumentSnapshot doc = await docRef.get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = docRef.id;
    return data;
  }

  // Thêm vào database với ID truyền vào và nhận lại đối tượng vừa tạo
  Future<Map<String, dynamic>> addWithCustomId(String collection, String id, Map<String, dynamic> json) async {
    await _db.collection(collection).doc(id).set(json);
    DocumentSnapshot doc = await _db.collection(collection).doc(id).get();
    return doc.data() as Map<String, dynamic>;
  }

  // Sửa dữ liệu vào database với ID truyền vào
  Future<void> updateData(String collection, String id, Map<String, dynamic> json) async {
    await _db.collection(collection).doc(id).update(json);
  }

  // Xoá dữ liệu vào database với ID truyền vào
  Future<void> deleteData(String collection, String id) async {
    await _db.collection(collection).doc(id).delete();
  }

  // Lấy toàn bộ dữ liệu trong collection
  Future<List<Map<String, dynamic>>> getAllData(String collection) async {
    QuerySnapshot snapshot = await _db.collection(collection).get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Lấy toàn bộ dữ liệu có dữ liệu trùng khớp với json (chứa các thuộc tính)
  Future<List<Map<String, dynamic>>> getDataWithExactMatch(String collection, Map<String, dynamic> json) async {
    Query query = _db.collection(collection);
    json.forEach((key, value) {
      query = query.where(key, isEqualTo: value);
    });
    QuerySnapshot snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Lấy toàn bộ dữ liệu có dữ liệu liên quan với json (chứa các thuộc tính)
  Future<List<Map<String, dynamic>>> getDataWithLikeMatch(String collection, Map<String, dynamic> json) async {
    Query query = _db.collection(collection);
    json.forEach((key, value) {
      query = query.where(key, isGreaterThanOrEqualTo: value).where(key, isLessThanOrEqualTo: value);
    });
    QuerySnapshot snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }


  // Lấy thông tin dữ liệu theo ID
  Future<Map<String, dynamic>?> getDataById(String collection, String id) async {
    try {
      DocumentSnapshot doc = await _db.collection(collection).doc(id).get();

      // Kiểm tra nếu document tồn tại
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        print('Không tìm thấy dữ liệu với ID: $id');
        return null;
      }
    } catch (e) {
      print('Lỗi khi lấy dữ liệu: $e');
      return null;
    }
  }
}
