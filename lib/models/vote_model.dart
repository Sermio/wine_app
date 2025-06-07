class Vote {
  final String id;
  final String pollId;
  final String wineId;
  final String userId;
  final int rating;
  final String userName;
  final String userPhoto;

  Vote({
    required this.id,
    required this.pollId,
    required this.wineId,
    required this.userId,
    required this.rating,
    required this.userName,
    required this.userPhoto,
  });

  factory Vote.fromMap(Map<String, dynamic> data, String id) {
    return Vote(
      id: id,
      pollId: data['pollId'] ?? '',
      wineId: data['wineId'] ?? '',
      userId: data['userId'] ?? '',
      rating: data['rating'] ?? 0,
      userName: data['userName'] ?? '',
      userPhoto: data['userPhoto'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pollId': pollId,
      'wineId': wineId,
      'userId': userId,
      'rating': rating,
      'userName': userName,
      'userPhoto': userPhoto,
    };
  }
}
