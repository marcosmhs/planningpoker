import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/planning_poker/planning_controller.dart';

import 'package:planningpoker/features/user/model/user.dart';

class HiveController with ChangeNotifier {
  final _userHiveBoxName = 'user';
  late Box<dynamic> _userHiveBox;

  final _planningDataHiveBoxName = 'planningData';
  late Box<dynamic> _planningDataHiveBox;

  var _user = User();
  var _planningData = PlanningData();

  Future<void> _prepareUserHiveBox() async {
    if (!Hive.isBoxOpen(_userHiveBoxName)) {
      _userHiveBox = await Hive.openBox(_userHiveBoxName);
    } else {
      _userHiveBox = Hive.box(_userHiveBoxName);
    }
  }

  Future<void> _preparePlanningDataHiveBox() async {
    if (!Hive.isBoxOpen(_planningDataHiveBoxName)) {
      _planningDataHiveBox = await Hive.openBox(_planningDataHiveBoxName);
    } else {
      _planningDataHiveBox = Hive.box(_planningDataHiveBoxName);
    }
  }

  Future<void> chechLocalData() async {
    await _prepareUserHiveBox();
    if (_userHiveBox.isNotEmpty) {
      _user = _userHiveBox.get(_userHiveBox.keyAt(0));
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
  }

  Future<void> removeBox() async {
    await _prepareUserHiveBox();
    await _userHiveBox.deleteFromDisk();

    await _preparePlanningDataHiveBox();
    await _planningDataHiveBox.deleteFromDisk();
  }

  User get localUser => User.fromMap(_user.toMap());
  PlanningData get localPlanningData => PlanningData.fromMap(_planningData.toMap());

  void saveUser({required User user}) async {
    await _prepareUserHiveBox();
    await _userHiveBox.clear();
    await _userHiveBox.put(user.id, user);
  }

  void savePlanningData({required PlanningData planningData}) async {
    await _preparePlanningDataHiveBox();
    await _planningDataHiveBox.clear();
    await _planningDataHiveBox.put(planningData.id, planningData);
  }

  void clearUserHiveBox() async {
    await _prepareUserHiveBox();
    await _userHiveBox.clear();
  }

  void clearPlanningDataHiveBox() async {
    await _preparePlanningDataHiveBox();
    await _planningDataHiveBox.clear();
  }
}
