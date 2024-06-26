import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:planningpoker/local_data_controller.dart';
import 'package:teb_package/util/teb_return.dart';
import 'package:teb_package/util/teb_uid_generator.dart';

class UserController with ChangeNotifier {
  final _planningDataCollectionName = 'planningData';
  final _userCollectionName = 'user';
  late User _currentUser;

  User get currentUser => User.fromMap(_currentUser.toMap);

  Future<TebCustomReturn> save({required User user}) async {
    try {
      if (user.id.isEmpty) {
        user.id = TebUidGenerator.firestoreUid;
        user.createDate = DateTime.now();
      }

      await FirebaseFirestore.instance
          .collection(_planningDataCollectionName)
          .doc(user.planningPokerId)
          .collection(_userCollectionName)
          .doc(user.id)
          .set(user.toMap);

      _currentUser = User.fromMap(user.toMap);

      LocalDataController().saveUser(user: _currentUser);

      return TebCustomReturn.sucess;
    } on fb_auth.FirebaseException catch (e) {
      return TebCustomReturn.error(e.code);
    } catch (e) {
      return TebCustomReturn.error(e.toString());
    }
  }

  Future<User> getUserByAccessCode({required String planningId, required String userAccessCode}) async {
    final userDataRef = await FirebaseFirestore.instance
        .collection(_planningDataCollectionName)
        .doc(planningId)
        .collection(_userCollectionName)
        .where('accessCode', isEqualTo: userAccessCode)
        .get();

    if (userDataRef.size == 0) {
      return User();
    }

    final userData = userDataRef.docs.first.data();
    var user = User.fromMap(userData);
    LocalDataController().saveUser(user: user);

    return user;
  }

  Stream<QuerySnapshot<Object?>> getUserListData({required String planningId}) {
    return FirebaseFirestore.instance
        .collection(_planningDataCollectionName)
        .doc(planningId)
        .collection(_userCollectionName)
        .snapshots();
  }

  void clearCurrentUser() async {
    LocalDataController().clearUserData();
    _currentUser = User();
  }
}
