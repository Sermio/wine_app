import 'package:cloud_firestore/cloud_firestore.dart';

class Poll {
  final String id;
  final String title;
  final DateTime date;
  final String creatorId;
  final bool closed;

  Poll({
    required this.id,
    required this.title,
    required this.date,
    required this.creatorId,
    required this.closed,
  });

  factory Poll.fromMap(Map<String, dynamic> data, String id) {
    return Poll(
      id: id,
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      creatorId: data['creatorId'] ?? '',
      closed: data['closed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'creatorId': creatorId,
      'closed': closed,
    };
  }
}
