import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teb_package/util/teb_uid_generator.dart';

enum Role { spectator, player }

class User {
  late String id;
  late String planningPokerId;
  late String name;
  late bool creator;
  late Role role;
  late DateTime? createDate;
  late String accessCode;
  late String kanbanizeApiKey;
  late String kanbanizeUrl;
  late String kanbanizeBoardId;
  late String kanbanizeLaneName;
  late String kanbanizeColumnName;
  

  User({
    this.id = '',
    this.planningPokerId = '',
    this.name = '',
    this.creator = false,
    this.role = Role.player,
    this.createDate,
    String accessCode = '',
    this.kanbanizeApiKey = '',
    this.kanbanizeUrl = '',
    this.kanbanizeBoardId = '',
    this.kanbanizeLaneName = '',
    this.kanbanizeColumnName = '',
  }) {
    this.accessCode = accessCode.isNotEmpty ? accessCode : TebUidGenerator.userAccessCode;
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
      
      kanbanizeApiKey: map['kanbanizeApiKey'] ?? '',
      kanbanizeUrl: map['kanbanizeUrl'] ?? '',
      kanbanizeBoardId: map['kanbanizeBoardId'] ?? '',
      kanbanizeLaneName: map['kanbanizeLaneName'] ?? '',
      kanbanizeColumnName: map['kanbanizeColumnName'] ?? '',
    );
    return u;
  }

  Map<String, dynamic> get toMap {
    Map<String, dynamic> r = {};
    r = {
      'id': id,
      'planningPokerId': planningPokerId,
      'name': name,
      'role': role.toString(),
      'creator': creator,
      'createDate': createDate.toString(),
      'accessCode': accessCode,
      
      'kanbanizeApiKey': kanbanizeApiKey,
      'kanbanizeUrl': kanbanizeUrl,
      'kanbanizeBoardId': kanbanizeBoardId,
      'kanbanizeLaneName': kanbanizeLaneName,
      'kanbanizeColumnName': kanbanizeColumnName,
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

class UserThemeMode {
  final String themeName;

  UserThemeMode({required this.themeName});
}
