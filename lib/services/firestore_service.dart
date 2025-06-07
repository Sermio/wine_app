import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poll_model.dart';
import '../models/wine_model.dart';
import '../models/vote_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createPoll(Poll poll) async {
    final doc = await FirebaseFirestore.instance
        .collection('polls')
        .add(poll.toMap());
    return doc.id;
  }

  Future<List<Poll>> fetchPolls() async {
    final snapshot = await FirebaseFirestore.instance.collection('polls').get();
    return snapshot.docs
        .map((doc) => Poll.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> addWinesToPoll(String pollId, List<Wine> wines) async {
    final batch = FirebaseFirestore.instance.batch();
    final winesRef = FirebaseFirestore.instance.collection(
      'polls/$pollId/wines',
    );

    for (final wine in wines) {
      final doc = winesRef.doc(wine.id);
      batch.set(doc, wine.toMap());
    }

    await batch.commit();
  }

  Future<void> addWine(String pollId, Wine wine) async {
    await _db
        .collection('polls')
        .doc(pollId)
        .collection('wines')
        .add(wine.toMap());
  }

  Future<void> submitVote(Vote vote) async {
    await _db
        .collection('polls')
        .doc(vote.pollId)
        .collection('votes')
        .add(vote.toMap());
  }

  Future<void> closePoll(String pollId) async {
    await _db.collection('polls').doc(pollId).update({'closed': true});
  }

  Stream<List<Poll>> getActivePolls() {
    return _db
        .collection('polls')
        .where('closed', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Poll.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Poll>> getClosedPolls() {
    return _db
        .collection('polls')
        .where('closed', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Poll.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Wine>> getWines(String pollId) {
    return _db
        .collection('polls')
        .doc(pollId)
        .collection('wines')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Wine.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Vote>> getVotes(String pollId) {
    return _db
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Vote.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
