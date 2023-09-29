import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'planning_poker.g.dart';

@HiveType(typeId: 0)
class PlanningData {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late String name;
  @HiveField(2)
  late String invitationCode;
  @HiveField(3)
  late DateTime? createDate;
  @HiveField(4)
  late bool othersCanCreateStories;

  PlanningData({
    this.id = '',
    this.name = '',
    this.invitationCode = '',
    this.createDate,
    this.othersCanCreateStories = false,
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
      othersCanCreateStories: map['othersCanCreateStories'] ?? false,
    );
    return u;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> r = {};
    r = {
      'id': id,
      'name': name,
      'invitationCode': invitationCode,
      'createDate': createDate.toString(),
      'othersCanCreateStories': othersCanCreateStories,
    };

    return r;
  }
}
