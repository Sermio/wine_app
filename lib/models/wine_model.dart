import 'dart:io';

class Wine {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String pollId;
  final File? imageFile; // Solo para uso local al crear

  Wine({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.pollId,
    this.imageFile,
  });

  factory Wine.fromMap(Map<String, dynamic> data, String id) {
    return Wine(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      pollId: data['pollId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'pollId': pollId,
    };
  }
}
