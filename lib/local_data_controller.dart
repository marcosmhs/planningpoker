import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/planning_poker/planning_controller.dart';

import 'package:planningpoker/features/user/model/user.dart';
import 'package:teb_package/log/debug_log/teb_debug_log.dart';
import 'package:teb_package/teb_package.dart';

class LocalDataController with ChangeNotifier {
  var _user = User();
  var _planningData = PlanningData();

  User get localUser => User.fromMap(_user.toMap);
  PlanningData get localPlanningData => PlanningData.fromMap(_planningData.toMap);

  Future<ThemeMode> getLocalThemeMode() async {
    var userThemeData = await TebLocalStorage.readString(key: 'userThemeMode');

    if (userThemeData.isEmpty) {
      return ThemeMode.dark;
    } else {
      if (userThemeData == ThemeMode.dark.name) {
        return ThemeMode.dark;
      } else {
        return ThemeMode.light;
      }
    }
  }

  Future<void> chechLocalData() async {
    try {
      // user data
      TebDebugLog(fireStoreInstance: FirebaseFirestore.instance, group: 'hive_controller - checkLocalData', message: 'Start');
      var userMap = await TebLocalStorage.readMap(key: 'user');

      if (userMap.isEmpty) return;

      _user = User.fromMap(userMap);

      //se a data de criação do usuário + 5 dias é menor que a data atual significa que ele foi
      //criado a mais de 5 dias, ou seja,  ele não deve mais existir
      if (_user.createDate != null && _user.createDate!.add(const Duration(days: 5)).isBefore(DateTime.now())) {
        TebDebugLog(fireStoreInstance: FirebaseFirestore.instance, group: 'hive_controller - checkLocalData', message: 'no user');
        clearUserData();
        clearPlanningData();
        _planningData = PlanningData();
        _user = User();
        return;
      }

      var planningMap = await TebLocalStorage.readMap(key: 'planning');

      if (planningMap.isNotEmpty) {
        _planningData = PlanningData.fromMap(planningMap);
      }

      var planningPokerController = PlanningPokerController();

      if (_planningData.id.isEmpty) return;

      var planningExists = await planningPokerController.planningExists(planningId: _planningData.id);

      if (!planningExists) {
        clearUserData();
        clearPlanningData();
        _planningData = PlanningData();
        _user = User();
      }
    } catch (e) {
      TebDebugLog(
        fireStoreInstance: FirebaseFirestore.instance,
        group: 'hive_controller - checkLocalData',
        message: 'error: ${e.toString()}',
      );
      var analytics = FirebaseAnalytics.instance;
      analytics.logEvent(name: 'hive_error ${e.toString()}');
      clearPlanningData();
      clearUserData();
    }
  }

  void saveUser({required User user}) async {
    clearUserData();
    TebLocalStorage.saveMap(key: 'user', map: user.toMap);
  }

  void savePlanningData({required PlanningData planningData}) async {
    TebLocalStorage.saveMap(key: 'planning', map: planningData.toMap);
  }

  void clearUserData() async {
    TebLocalStorage.removeValue(key: 'user');
  }

  void clearPlanningData() async {
    TebLocalStorage.removeValue(key: 'planning');
  }

  void clearAll() {
    TebLocalStorage.removeValue(key: 'user');
    TebLocalStorage.removeValue(key: 'planning');
  }

  void saveUserThemeMode({required UserThemeMode userThemeMode}) async {
    TebLocalStorage.saveString(key: 'userThemeMode', value: userThemeMode.themeName);
  }
}
