import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadWineImage(
    String pollId,
    String wineId,
    File file,
  ) async {
    Reference ref = _storage.ref().child('polls/$pollId/wines/$wineId.jpg');
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> uploadUserProfileImage(String userId, File file) async {
    Reference ref = _storage.ref().child('users/$userId/profile.jpg');
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
