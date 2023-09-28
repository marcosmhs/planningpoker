import 'package:cloud_firestore/cloud_firestore.dart';

enum StoryStatus { created, voting, votingFinished, closed }

class Story {
  late String id;
  late String planningPokerId;
  late String name;
  late String url;
  late String description;
  late int points;
  late StoryStatus status;

  Story({
    this.id = '',
    this.planningPokerId = '',
    this.name = '',
    this.url = '',
    this.description = '',
    this.points = 0,
    this.status = StoryStatus.created,
  });

  factory Story.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Story.fromMap(data);
  }

  static Story fromMap(Map<String, dynamic> map) {
    var u = Story();

    u = Story(
      id: map['id'] ?? '',
      planningPokerId: map['planningPokerId'] ?? '',
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      description: map['description'] ?? '',
      points: map['points'] ?? 0,
      status: map['status'] == null ? StoryStatus.created : storyStatusFromString(map['status']),
    );
    return u;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> r = {};
    r = {
      'id': id,
      'planningPokerId': planningPokerId,
      'name': name,
      'url': url,
      'description': description,
      'points': points,
      'status': status.toString(),
    };

    return r;
  }

  static StoryStatus storyStatusFromString(String stringValue) {
    switch (stringValue) {
      case 'StoryStatus.created':
        return StoryStatus.created;
      case 'StoryStatus.voting':
        return StoryStatus.voting;
      case 'StoryStatus.votingFinished':
        return StoryStatus.votingFinished;
      default:
        return StoryStatus.closed;
    }
  }
}