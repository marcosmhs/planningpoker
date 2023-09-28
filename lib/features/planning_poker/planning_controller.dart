import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:planningpoker/components/util/custom_return.dart';
import 'package:planningpoker/features/planning_poker/planning_poker.dart';

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

      return CustomReturn.sucess;
    } catch (e) {
      return CustomReturn.error(e.toString());
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> get getPlanningData {
    return FirebaseFirestore.instance.collection(_planningDataCollectionName).doc(_currentPlanning.id).snapshots();
  }

  void clearCurrentPlanning() {
    _currentPlanning = PlanningData();
  }
}