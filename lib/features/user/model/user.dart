import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:teb_package/util/teb_uid_generator.dart';

part 'user.g.dart';

@HiveType(typeId: 2)
enum Role {
  @HiveField(0)
  spectator,
  @HiveField(1)
  player
}

@HiveType(typeId: 1)
class User {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late String planningPokerId;
  @HiveField(2)
  late String name;
  @HiveField(3)
  late bool creator;
  @HiveField(4)
  late Role role;
  @HiveField(5)
  late DateTime? createDate;
  @HiveField(6)
  late String accessCode;

  User({
    this.id = '',
    this.planningPokerId = '',
    this.name = '',
    this.creator = false,
    this.role = Role.player,
    this.createDate,
    String? accessCode,
  }) {
    this.accessCode = accessCode ?? TebUidGenerator.userAccessCode;
  }

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
      accessCode: map['accessCode'] ?? '',
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
      'accessCode': accessCode,
    };

    return r;
  }

  bool get isPlayer {
    return role == Role.player;
  }

  bool get isSpectator {
    return role == Role.spectator;
  }

  String get roleLabel {
    return role == Role.player ? 'Jogador' : 'Espectador';
  }

  static Role roleFromString(String stringValue) {
    return stringValue == 'Role.player' ? Role.player : Role.spectator;
  }
}
