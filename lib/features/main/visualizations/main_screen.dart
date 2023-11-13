// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:planningpoker/consts.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/main/visualizations/about_dialog_button.dart';

import 'package:planningpoker/features/main/visualizations/widgets/main_screen_title_bar.dart';
import 'package:planningpoker/features/main/visualizations/widgets/stories_area.dart';
import 'package:planningpoker/features/main/visualizations/widgets/voting_area.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/planning_poker/planning_controller.dart';

import 'package:planningpoker/features/user/model/user.dart';
import 'package:planningpoker/features/user/user_controller.dart';
import 'package:provider/provider.dart';
import 'package:teb_package/messaging/teb_custom_dialog.dart';
import 'package:teb_package/screen_elements/teb_custom_scaffold.dart';

// ignore: must_be_immutable
class MainScreen extends StatefulWidget {
  final User? user;
  final PlanningData? planningData;

  const MainScreen({
    super.key,
    this.user,
    this.planningData,
  });

  @override
  State<MainScreen> createState() => _MainScreen();
}

class _MainScreen extends State<MainScreen> with TickerProviderStateMixin {
  var _planningData = PlanningData();
  var _user = User();

  var _initializing = true;
  var _size = const Size(0, 0);

  void _confirmPlanningExit() {
    TebCustomDialog(context: context)
        .confirmationDialog(
            message: 'Tem certeza que deseja abandona a partida?\n\nIsso fará com que seu acesso seja removido permanentemente.')
        .then((response) {
      if (response == true) {
        Provider.of<PlanningPokerController>(context, listen: false).clearCurrentPlanning();
        Provider.of<UserController>(context, listen: false).clearCurrentUser();
        Navigator.of(context).popAndPushNamed(Routes.landingScreen);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      final arguments = (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{}) as Map;
      _user = arguments['user'] ?? User();
      _planningData = arguments['planningData'] ?? PlanningData();

      if (widget.user != null && widget.user!.id.isNotEmpty) _user = widget.user!;
      if (widget.planningData != null && widget.planningData!.id.isNotEmpty) _planningData = widget.planningData!;

      _initializing = false;
    }
    _size = MediaQuery.of(context).size;
    //Consts.mainAreaHeight = _size.height * 0.70;

    if (_user.id.isEmpty || _planningData.id.isEmpty) return const Text('');

    return TebCustomScaffold(
      // appbar
      appBar: AppBar(
        title: MainScreenTitleBar(planningData: _planningData, user: _user, context: context),
        actions: [
          const AboutDialogButton(),
          IconButton(
            onPressed: () => _confirmPlanningExit(),
            icon: const Icon(Icons.exit_to_app),
          )
        ],
      ),
      body: StreamBuilder(
        stream: Provider.of<PlanningPokerController>(context, listen: false).getPlanningData(planningId: _planningData.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Text('Parece que houve um erro, pois não há dados da planning e você está nesta tela'));
          }

          if (snapshot.hasData) _planningData = PlanningData.fromDocument(snapshot.data!);

          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // stories
              SizedBox(
                width: Consts.storiesAreaWidth,
                child: StoriesArea(planningData: _planningData, user: _user),
              ),
              // voting area
              SizedBox(
                width: _size.width - Consts.storiesAreaWidth,
                child: VotingArea(planningData: _planningData, user: _user),
              ),
            ],
          );
        },
      ),
    );
  }
}
