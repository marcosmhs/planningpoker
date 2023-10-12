import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:planningpoker/components/util/custom_return.dart';
import 'package:planningpoker/components/util/uid_generator.dart';
import 'package:planningpoker/features/main/hive_controller.dart';
import 'package:planningpoker/features/user/visualizations/user.dart';

class UserController with ChangeNotifier {
  final _planningDataCollectionName = 'planningData';
  final _userCollectionName = 'user';
  late User _currentUser;

  User get currentUser => User.fromMap(_currentUser.toMap());

  //Future<bool> _userNameExists({required User user}) async {
  //  var query = FirebaseFirestore.instance
  //      .collection(_planningDataCollectionName)
  //      .doc(user.planningPokerId)
  //      .collection(_userCollectionName)
  //      .where("name", isEqualTo: user.name);
  //  if (user.id.isNotEmpty) {
  //    query = query.where("id", isNotEqualTo: user.id);
  //  }
  //  var dataList = await query.get();
  //  return dataList.docs.isNotEmpty;
  //}

  Future<CustomReturn> save({required User user}) async {
    //if (await _userNameExists(user: user)) {
    //  return CustomReturn.error('Já existe uma pessoa com o nome ${user.name}');
    //}

    try {
      if (user.id.isEmpty) {
        user.id = UidGenerator.firestoreUid;
        user.createDate = DateTime.now();
      }

      await FirebaseFirestore.instance
          .collection(_planningDataCollectionName)
          .doc(user.planningPokerId)
          .collection(_userCollectionName)
          .doc(user.id)
          .set(user.toMap());

      _currentUser = User.fromMap(user.toMap());

      var hiveController = HiveController();
      hiveController.saveUser(user: _currentUser);

      return CustomReturn.sucess;
    } on fb_auth.FirebaseException catch (e) {
      return CustomReturn.error(e.code);
    } catch (e) {
      return CustomReturn.error(e.toString());
    }
  }

  void clearCurrentUser() async {
    var hiveController = HiveController();
    hiveController.clearUserHiveBox();
    _currentUser = User();
  }
}
