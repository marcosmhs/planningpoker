// ignore_for_file: use_build_context_synchronously
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages

import 'package:planningpoker/features/main/hive_controller.dart';
import 'package:planningpoker/features/main/visualizations/main_screen.dart';
import 'package:planningpoker/features/main/visualizations/wellcome_screen.dart';

import 'package:teb_package/screen_elements/teb_custom_scaffold.dart';


class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  var _initializing = true;
  var analytics = FirebaseAnalytics.instance;

  Widget _errorScreen({required String errorMessage}) {
    return TebCustomScaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Fatal error!'),
            const SizedBox(height: 20),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      analytics.logEvent(name: 'landing_entering');
      _initializing = false;
    }

    var hiveController = HiveController();

    return FutureBuilder(
      future: hiveController.chechLocalData(),
      builder: (ctx, snapshot) {
        // enquanto está carregando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
          // em caso de erro
        } else {
          if (snapshot.error != null) {
            hiveController.clearPlanningDataHiveBox();
            hiveController.clearUserHiveBox();
            analytics.logEvent(name: 'landing_error');
            return _errorScreen(errorMessage:  snapshot.error.toString());
            // ao final do processo
          } else {
            // irá avaliar se o usuário possui login ou não
            return hiveController.localUser.id.isEmpty
                ? const WellComeScreen()
                : MainScreen(
                    user: hiveController.localUser,
                    planningData: hiveController.localPlanningData,
                  );
          }
        }
      },
    );
  }
}
