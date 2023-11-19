import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/planning_poker/planning_controller.dart';

import 'package:planningpoker/features/user/model/user.dart';
import 'package:teb_package/log/debug_log/teb_debug_log.dart';

class HiveController2 with ChangeNotifier {
  final _userHiveBoxName = 'user';
  late LazyBox<dynamic> _userHiveBox;

  final _planningDataHiveBoxName = 'planningData';
  late Box<dynamic> _planningDataHiveBox;

  final _userThemeModeHiveBoxName = 'userThemeMode';
  late Box<dynamic> _userThemeModeHiveBox;

  var _user = User();
  var _planningData = PlanningData();

  User get localUser => User.fromMap(_user.toMap);
  PlanningData get localPlanningData => PlanningData.fromMap(_planningData.toMap);

  Future<void> _prepareThemeModeHiveBox() async {
    if (!Hive.isBoxOpen(_userThemeModeHiveBoxName)) {
      _userThemeModeHiveBox = await Hive.openBox(_userThemeModeHiveBoxName);
    } else {
      _userThemeModeHiveBox = Hive.box(_userThemeModeHiveBoxName);
    }
  }

  Future<void> _prepareUserHiveBox() async {
    try {
      if (!Hive.isBoxOpen(_userHiveBoxName)) {
        _userHiveBox = await Hive.openLazyBox(_userHiveBoxName);
      } else {
        _userHiveBox = Hive.lazyBox(_userHiveBoxName);
      }
    } finally {
      if (!Hive.isBoxOpen(_userHiveBoxName)) {
        _userHiveBox = Hive.lazyBox(_userHiveBoxName);
      }
    }
  }

  Future<void> _preparePlanningDataHiveBox() async {
    if (!Hive.isBoxOpen(_planningDataHiveBoxName)) {
      _planningDataHiveBox = await Hive.openBox(_planningDataHiveBoxName);
    } else {
      _planningDataHiveBox = Hive.box(_planningDataHiveBoxName);
    }
  }

  Future<ThemeMode> getLocalThemeMode() async {
    await _prepareThemeModeHiveBox();

    if (_userThemeModeHiveBox.isEmpty) {
      return ThemeMode.dark;
    } else {
      var userThemeMode = _userThemeModeHiveBox.get('userThemeMode');
      if (userThemeMode.toString() == ThemeMode.dark.name) {
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
      await _prepareUserHiveBox();
      if (_userHiveBox.isNotEmpty) {
        _user = _userHiveBox.get(_userHiveBox.keyAt(0)) as User;
        TebDebugLog(
          fireStoreInstance: FirebaseFirestore.instance,
          group: 'hive_controller - checkLocalData',
          message: 'user data: ${_user.name}',
        );
      }

      //se a data de criação do usuário + 5 dias é menor que a data atual significa que ele foi
      //criado a mais de 5 dias, ou seja,  ele não deve mais existir
      if (_user.createDate != null && _user.createDate!.add(const Duration(days: 5)).isBefore(DateTime.now())) {
        TebDebugLog(fireStoreInstance: FirebaseFirestore.instance, group: 'hive_controller - checkLocalData', message: 'no user');
        clearUserHiveBox();
        clearPlanningDataHiveBox();
        _planningData = PlanningData();
        _user = User();
      } else {
        await _preparePlanningDataHiveBox();
        if (_planningDataHiveBox.isNotEmpty) {
          _planningData = _planningDataHiveBox.get(_planningDataHiveBox.keyAt(0));
        }

        var planningPokerController = PlanningPokerController();

        if (_planningData.id.isEmpty) return;

        var planningExists = await planningPokerController.planningExists(planningId: _planningData.id);

        if (!planningExists) {
          clearUserHiveBox();
          clearPlanningDataHiveBox();
          _planningData = PlanningData();
          _user = User();
        }
      }
    } catch (e) {
      TebDebugLog(
        fireStoreInstance: FirebaseFirestore.instance,
        group: 'hive_controller - checkLocalData',
        message: 'error: ${e.toString()}',
      );
      var analytics = FirebaseAnalytics.instance;
      analytics.logEvent(name: 'hive_error ${e.toString()}');
      clearPlanningDataHiveBox();
      clearUserHiveBox();
    }
  }

  Future<void> removeBox() async {
    await _prepareUserHiveBox();
    await _userHiveBox.deleteFromDisk();

    await _preparePlanningDataHiveBox();
    await _planningDataHiveBox.deleteFromDisk();
  }

  void saveUser({required User user}) async {
    clearUserHiveBox();
    await _userHiveBox.put(user.id, user);
    await _userHiveBox.close();
  }

  void savePlanningData({required PlanningData planningData}) async {
    await _preparePlanningDataHiveBox();
    await _planningDataHiveBox.clear();
    await _planningDataHiveBox.put(planningData.id, planningData);
  }

  void clearUserHiveBox() async {
    await _prepareUserHiveBox();
    await _userHiveBox.clear();
    await _userHiveBox.deleteFromDisk();
  }

  void clearPlanningDataHiveBox() async {
    await _preparePlanningDataHiveBox();
    await _planningDataHiveBox.clear();
    await _planningDataHiveBox.deleteFromDisk();
  }

  void clearAll() {
    clearPlanningDataHiveBox();
    clearUserHiveBox();
  }

  void saveUserThemeMode({required UserThemeMode userThemeMode}) async {
    await _prepareThemeModeHiveBox();
    await _userThemeModeHiveBox.clear();
    await _userThemeModeHiveBox.put('userThemeMode', userThemeMode);
  }
}
