import 'package:cloud_firestore/cloud_firestore.dart';

enum Role { spectator, player }

class User {
  late String id;
  late String planningPokerId;
  late String name;
  late bool creator;
  late Role role;
  late DateTime? createDate;

  User({
    this.id = '',
    this.planningPokerId = '',
    this.name = '',
    this.creator = false,
    this.role = Role.player,
    this.createDate,
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return User.fromMap(data);
  }

  static User fromMap(Map<String, dynamic> map) {
    var u = User();

    u = User(
      id: map['id'] ?? '',
      planningPokerId: map['planningPokerId'] ?? '',
      name: map['name'] ?? '',
      role: roleFromString(map['role']),
      creator: map['creator'] ?? false,
      createDate: map['createDate'] == null ? null : DateTime.tryParse(map['createDate']),
    );
    return u;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> r = {};
    r = {
      'id': id,
      'planningPokerId': planningPokerId,
      'name': name,
      'role': role.toString(),
      'creator': creator,
      'createDate': createDate.toString(),
    };

    return r;
  }

  String get roleLabel {
    return role == Role.player ? 'Jogador' : 'Espectador';
  }

  static Role roleFromString(String stringValue) {
    return stringValue == 'Role.player' ? Role.player : Role.spectator;
  }
}
