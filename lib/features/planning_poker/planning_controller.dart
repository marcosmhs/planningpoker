import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:planningpoker/components/util/custom_return.dart';
import 'package:planningpoker/features/main/hive_controller.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';

class PlanningPokerController with ChangeNotifier {
  final String _planningDataCollectionName = 'planningData';
  late PlanningData _currentPlanning;

  PlanningPokerController() {
    _currentPlanning = PlanningData();
  }

  PlanningData get currentPlanning => PlanningData.fromMap(_currentPlanning.toMap());

  Future<CustomReturn> setPlanningDataByInvitation({required String invitationCode}) async {
    try {
      var planningQuery = await FirebaseFirestore.instance
          .collection(_planningDataCollectionName)
          .where("invitationCode", isEqualTo: invitationCode)
          .get();

      final dataList = planningQuery.docs.map((doc) => doc.data()).toList();

      if (dataList.isEmpty) return CustomReturn.error('Não foi encontrada uma partida com este código');
      if (dataList.length > 1) return CustomReturn.error('Foi encontrada mais de uma partida com este código');

      _currentPlanning = PlanningData.fromMap(dataList.first);

      var hiveController = HiveController();
      hiveController.savePlanningData(planningData: _currentPlanning);

      return CustomReturn.sucess;
    } catch (e) {
      return CustomReturn.error('Erro! ${e.toString()}');
    }
  }

  Future<CustomReturn> save({required PlanningData planningData}) async {
    try {
      planningData.createDate = DateTime.now();
      await FirebaseFirestore.instance.collection(_planningDataCollectionName).doc(planningData.id).set(planningData.toMap());

      _currentPlanning = PlanningData.fromMap(planningData.toMap());

      var hiveController = HiveController();
      hiveController.savePlanningData(planningData: _currentPlanning);

      return CustomReturn.sucess;
    } catch (e) {
      return CustomReturn.error(e.toString());
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getPlanningData({required String planningId}) {
    return FirebaseFirestore.instance.collection(_planningDataCollectionName).doc(planningId).snapshots();
  }

  Future<bool> planningExists({required String planningId}) async {
    final query = FirebaseFirestore.instance.collection(_planningDataCollectionName).doc(planningId);

    final dataList = await query.get();
    return dataList.exists;
  }

  void clearCurrentPlanning() async {
    var hiveController = HiveController();
    hiveController.clearPlanningDataHiveBox();
    _currentPlanning = PlanningData();
  }
}
