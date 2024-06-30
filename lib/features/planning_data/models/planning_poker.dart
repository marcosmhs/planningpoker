import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planningpoker/consts.dart';

enum PlanningVoteType { tshirt, fibonacci }

class PlanningData {
  late String id;
  late String name;
  late String invitationCode;
  late DateTime? createDate;
  late bool othersCanCreateStories;
  late PlanningVoteType planningVoteType;

  PlanningData({
    this.id = '',
    this.name = '',
    this.invitationCode = '',
    this.createDate,
    this.othersCanCreateStories = true,
    this.planningVoteType = PlanningVoteType.fibonacci,
  });

  factory PlanningData.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return PlanningData.fromMap(data);
  }

  static PlanningData fromMap(Map<String, dynamic> map) {
    var u = PlanningData();

    u = PlanningData(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      invitationCode: map['invitationCode'] ?? '',
      createDate: map['createDate'] == null ? null : DateTime.tryParse(map['createDate']),
      othersCanCreateStories: map['othersCanCreateStories'] ?? true,
      planningVoteType:
          map['planningVoteType'] == null ? PlanningVoteType.fibonacci : planningVoteTypeFromString(map['planningVoteType']),
    );
    return u;
  }

  Map<String, dynamic> get toMap {
    Map<String, dynamic> r = {};
    r = {
      'id': id,
      'name': name,
      'invitationCode': invitationCode,
      'createDate': createDate.toString(),
      'othersCanCreateStories': othersCanCreateStories,
      'planningVoteType': planningVoteType.toString(),
    };

    return r;
  }

  static PlanningVoteType planningVoteTypeFromString(String stringValue) {
    switch (stringValue) {
      case 'StoryStatus.fibonacci':
        return PlanningVoteType.fibonacci;
      default:
        return PlanningVoteType.tshirt;
    }
  }

  List<VoteValue> get voteListValues {
    return planningVoteType == PlanningVoteType.fibonacci ? Consts.fibonacciListValues : Consts.tshirtListValues;
  }

  String getLoteDisplayByValue(int voteValue) {
    var voteList = planningVoteType == PlanningVoteType.fibonacci ? Consts.fibonacciListValues : Consts.tshirtListValues;
    var vote = voteList.where((v) => v.value == voteValue).firstOrNull;

    return vote == null ? '' : vote.displayValue;
  }

  VoteValue findClosestPossibleVote(double value) {
    var voteList = planningVoteType == PlanningVoteType.fibonacci ? Consts.fibonacciListValues : Consts.tshirtListValues;
    //return list.reduce((a, b) => (a - target).abs() < (b - target).abs() ? a : b);
    return voteList.reduce((a, b) => (a.value - value).abs() < (b.value - value).abs() ? a : b);
  }
}
