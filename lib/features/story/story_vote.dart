import 'package:cloud_firestore/cloud_firestore.dart';

class StoryVote {
  late String id;
  late String planningPokerId;
  late String storyId;
  late String userId;
  late String userName;
  late int points;

  StoryVote({
    this.id = '',
    this.planningPokerId = '',
    this.storyId = '',
    this.userId = '',
    this.userName = '',
    this.points = 0,
  });

  factory StoryVote.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return StoryVote.fromMap(data);
  }

  static StoryVote fromMap(Map<String, dynamic> map) {
    var u = StoryVote();

    u = StoryVote(
      id: map['id'] ?? '',
      planningPokerId: map['planningPokerId'] ?? '',
      storyId: map['storyId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      points: map['points'] ?? 0,
    );
    return u;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> r = {};
    r = {
      'id': id,
      'planningPokerId': planningPokerId,
      'storyId': storyId,
      'userId': userId,
      'userName': userName,
      'points': points,
    };

    return r;
  }
}
