import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:planningpoker/features/planning_data/models/planning_poker.dart';
import 'package:planningpoker/local_data_controller.dart';
import 'package:teb_package/util/teb_return.dart';

class PlanningPokerController with ChangeNotifier {
  final String _planningDataCollectionName = 'planningData';
  late PlanningData _currentPlanning;

  PlanningPokerController() {
    _currentPlanning = PlanningData();
  }

  PlanningData get currentPlanning => PlanningData.fromMap(_currentPlanning.toMap);

  Future<TebCustomReturn> setPlanningDataByInvitation({required String invitationCode}) async {
    try {
      var planningQuery = await FirebaseFirestore.instance
          .collection(_planningDataCollectionName)
          .where("invitationCode", isEqualTo: invitationCode)
          .get();

      final dataList = planningQuery.docs.map((doc) => doc.data()).toList();

      if (dataList.isEmpty) return TebCustomReturn.error('Não foi encontrada uma partida com este código');
      if (dataList.length > 1) return TebCustomReturn.error('Foi encontrada mais de uma partida com este código');

      _currentPlanning = PlanningData.fromMap(dataList.first);

      var hiveController = LocalDataController();
      hiveController.savePlanningData(planningData: _currentPlanning);

      return TebCustomReturn.sucess;
    } catch (e) {
      return TebCustomReturn.error('Erro! ${e.toString()}');
    }
  }

  Future<TebCustomReturn> save({required PlanningData planningData}) async {
    try {
      planningData.createDate = DateTime.now();
      await FirebaseFirestore.instance.collection(_planningDataCollectionName).doc(planningData.id).set(planningData.toMap);

      _currentPlanning = PlanningData.fromMap(planningData.toMap);

      LocalDataController().savePlanningData(planningData: _currentPlanning);

      return TebCustomReturn.sucess;
    } catch (e) {
      return TebCustomReturn.error(e.toString());
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
    var hiveController = LocalDataController();
    hiveController.clearPlanningData();
    _currentPlanning = PlanningData();
  }
}
