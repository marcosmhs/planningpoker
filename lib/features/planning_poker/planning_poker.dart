import 'package:cloud_firestore/cloud_firestore.dart';

class PlanningData {
  late String id;
  late String name;
  late String invitationCode;
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
