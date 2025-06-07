class UserModel {
  final String id;
  final String name;
  final String email;
  final String photoUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'photoUrl': photoUrl};
  }
}
