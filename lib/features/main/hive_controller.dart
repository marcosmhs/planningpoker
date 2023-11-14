import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/planning_poker/planning_controller.dart';

import 'package:planningpoker/features/user/model/user.dart';

class HiveController with ChangeNotifier {
  final _playerHiveBoxName = 'player';
  late Box<dynamic> _playerHiveBox;

  final _planningDataHiveBoxName = 'planningData';
  late Box<dynamic> _planningDataHiveBox;

  final _themeModeHiveBoxName = 'themeMode';
  late Box<dynamic> _themeModeHiveBox;

  var _user = User();
  var _planningData = PlanningData();

  Future<void> _prepareThemeModeHiveBox() async {
    if (!Hive.isBoxOpen(_themeModeHiveBoxName)) {
      _themeModeHiveBox = await Hive.openBox(_themeModeHiveBoxName);
    } else {
      _themeModeHiveBox = Hive.box(_themeModeHiveBoxName);
    }
  }

  Future<void> _prepareUserHiveBox() async {
    if (!Hive.isBoxOpen(_playerHiveBoxName)) {
      _playerHiveBox = await Hive.openBox(_playerHiveBoxName);
    } else {
      _playerHiveBox = Hive.box(_playerHiveBoxName);
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

    if (_themeModeHiveBox.isEmpty) {
      return ThemeMode.dark;
    } else {
      var tm = _themeModeHiveBox.get('themeMode');
      if (tm.toString() == ThemeMode.dark.name) {
        return ThemeMode.dark;
      } else {
        return ThemeMode.light;
      }
    }
  }

  Future<void> chechLocalData() async {
    try {
      // user data
      await _prepareUserHiveBox();
      if (_playerHiveBox.isNotEmpty) {
        _user = _playerHiveBox.get(_playerHiveBox.keyAt(0));
      }

      //se a data de criação do usuário + 5 dias é menor que a data atual significa que ele foi
      //criado a mais de 5 dias, ou seja,  ele não deve mais existir
      if (_user.createDate != null && _user.createDate!.add(const Duration(days: 5)).isBefore(DateTime.now())) {
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
      var analytics = FirebaseAnalytics.instance;
      analytics.logEvent(name: 'hive_error ${e.toString()}');
      clearPlanningDataHiveBox();
      clearUserHiveBox();
    }
  }

  Future<void> removeBox() async {
    await _prepareUserHiveBox();
    await _playerHiveBox.deleteFromDisk();

    await _preparePlanningDataHiveBox();
    await _planningDataHiveBox.deleteFromDisk();
  }

  User get localUser => User.fromMap(_user.toMap());
  PlanningData get localPlanningData => PlanningData.fromMap(_planningData.toMap());

  void saveUser({required User user}) async {
    await _prepareUserHiveBox();
    await _playerHiveBox.clear();
    await _playerHiveBox.put(user.id, user);
  }

  void savePlanningData({required PlanningData planningData}) async {
    await _preparePlanningDataHiveBox();
    await _planningDataHiveBox.clear();
    await _planningDataHiveBox.put(planningData.id, planningData);
  }

  void clearUserHiveBox() async {
    await _prepareUserHiveBox();
    await _playerHiveBox.clear();
    await _playerHiveBox.deleteFromDisk();
  }

  void clearPlanningDataHiveBox() async {
    await _preparePlanningDataHiveBox();
    await _planningDataHiveBox.clear();
    await _planningDataHiveBox.deleteFromDisk();
  }

  void saveThemeMode({required ThemeMode themeMode}) async {
    await _prepareThemeModeHiveBox();
    await _themeModeHiveBox.clear();
    await _themeModeHiveBox.put('themeMode', themeMode.name);
  }
}
