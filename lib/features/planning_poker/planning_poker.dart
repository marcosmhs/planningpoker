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

  PlanningData({
    this.id = '',
    this.name = '',
    this.invitationCode = '',
    this.createDate,
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
    };

    return r;
  }
}
