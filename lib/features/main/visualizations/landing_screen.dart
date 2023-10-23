// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:fluttertoast/fluttertoast.dart';
import 'package:planningpoker/features/main/hive_controller.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/main/visualizations/main_screen.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/planning_poker/planning_controller.dart';
import 'package:planningpoker/features/user/visualizations/user.dart';
import 'package:planningpoker/features/user/user_controller.dart';
import 'package:provider/provider.dart';
import 'package:teb_package/access_log/access_log_controller.dart';
import 'package:teb_package/messaging/teb_custom_dialog.dart';
import 'package:teb_package/messaging/teb_custom_message.dart';
import 'package:teb_package/screen_elements/teb_custom_scaffold.dart';
import 'package:teb_package/util/teb_return.dart';
import 'package:teb_package/util/teb_util.dart';
import 'package:teb_package/visual_elements/teb_text_form_field.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final TextEditingController _invitationCodeController = TextEditingController();
  final _user = User();
  var _planningData = PlanningData();

  var _info = TebUtil.packageInfo;
  var _initializing = true;

  Future<void> _setUserData({required BuildContext buildContext}) async {
    await showDialog(
      context: buildContext,
      builder: (BuildContext ctx) {
        List<bool> selectedRole = [true, false];

        return AlertDialog(
          scrollable: true,
          title: const Text('Informe Seus dados'),
          titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
          content: StatefulBuilder(
            builder: (BuildContext ctx2, StateSetter setState) {
              return Column(
                children: [
                  // user name
                  TebTextEdit(
                    context: ctx,
                    labelText: 'Seu nome',
                    hintText: 'Informe seu nome',
                    onSave: (value) => _user.name = value ?? '',
                    prefixIcon: Icons.person,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) => _user.name = value ?? '',
                  ),
                  // role selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Qual o seu papel?'),
                      ),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints.tightFor(height: 40),
                          child: ToggleButtons(
                            isSelected: selectedRole,
                            fillColor: Theme.of(context).primaryColor,
                            selectedColor: Colors.black,
                            onPressed: (index) {
                              setState(() {
                                _user.role = index == 0 ? Role.player : Role.spectator;
                                selectedRole = [index == 0, index == 1];
                              });
                            },
                            children: [
                              SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.3,
                                  child: Text(
                                    'Jogador',
                                    textAlign: TextAlign.center,
                                    style: _user.role == Role.player
                                        ? TextStyle(color: Theme.of(context).cardColor)
                                        : TextStyle(color: Theme.of(context).primaryColor),
                                  )),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.3,
                                  child: Text(
                                    'Espectador',
                                    textAlign: TextAlign.center,
                                    style: _user.role == Role.spectator
                                        ? TextStyle(color: Theme.of(context).cardColor)
                                        : TextStyle(color: Theme.of(context).primaryColor),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                var userController = Provider.of<UserController>(buildContext, listen: false);
                if (_user.name.isEmpty) {
                  TebCustomMessage.error(context, message: 'Informe seu nome');
                } else {
                  _user.planningPokerId = _planningData.id;
                  if (_user.isSpectator) _user.creator = _planningData.othersCanCreateStories;
                  var customReturn = await userController.save(user: _user);
                  if (customReturn.returnType == TebReturnType.error) {
                    if (!kIsWeb) {
                      FocusScopeNode currentFocus = FocusScope.of(ctx);
                      if (!currentFocus.hasPrimaryFocus) {
                        currentFocus.unfocus();
                      }
                    }

                    TebCustomMessage(
                      context: context,
                      messageText: customReturn.message,
                      messageType: TebMessageType.error,
                      durationInSeconds: 3,
                      modelType: TebModelType.toast,
                      toastGravity: ToastGravity.TOP,
                    );
                  } else {
                    Navigator.of(context).popAndPushNamed(Routes.mainScreen, arguments: {
                      'user': _user,
                      'planningData': _planningData,
                    });
                  }
                }
              },
              child: const Text("Continuar"),
            ),
          ],
        );
      },
    );
  }

  void _findPlanning({required BuildContext context, required String invitationCode}) async {
    if (invitationCode.isEmpty) {
      TebCustomMessage.error(context, message: 'Ops, você não informou o código do convite');
      return;
    }

    var customReturn = await Provider.of<PlanningPokerController>(context, listen: false).setPlanningDataByInvitation(
      invitationCode: invitationCode,
    );
    if (customReturn.returnType == TebReturnType.error) {
      TebCustomMessage.error(context, message: customReturn.message);
      return;
    }
    _planningData = Provider.of<PlanningPokerController>(context, listen: false).currentPlanning;

    await _setUserData(buildContext: context);
  }

  Widget _newPlanning() {
    return TebCustomScaffold(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('Planning Poker'),
          const SizedBox(width: 10),
          Text(
            'v${_info.version}-${_info.buildNumber}',
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.labelMedium!.fontSize,
              color: Theme.of(context).colorScheme.background,
            ),
          )
        ],
      ),
      appBarActions: [
        IconButton(
            onPressed: () {
              TebCustomDialog(context: context).informationDialog(
                  message:
                      'Desenvolvido por um programador entediado durante suas férias.\n\nImportante:\n1 - Evite colocar dados sensíveis nas descrições dos cards.\n2 - Plannings com mais de 5 dias serão excluídas\n\n Divirta-se');
            },
            icon: const Icon(Icons.question_mark))
      ],
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: kIsWeb
                ? MediaQuery.of(context).size.width <= 750
                    ? MediaQuery.of(context).size.width
                    : MediaQuery.of(context).size.width * (MediaQuery.of(context).size.width <= 1000 ? 0.6 : 0.4)
                : MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('O que deseja fazer?', style: Theme.of(context).textTheme.headlineLarge),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints.tightFor(height: 50, width: MediaQuery.of(context).size.width * 0.75),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).popAndPushNamed(Routes.planningDataForm),
                      child: const Text('Criar um novo jogo'),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text('Entrar em um jogo já criado', style: Theme.of(context).textTheme.headlineSmall),
                      ConstrainedBox(
                        constraints: BoxConstraints.tightFor(height: 72, width: MediaQuery.of(context).size.width * 0.75),
                        child: TebTextEdit(
                          context: context,
                          labelText: 'Código do jogo',
                          controller: _invitationCodeController,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints.tightFor(height: 50, width: MediaQuery.of(context).size.width * 0.75),
                          child: ElevatedButton(
                            onPressed: () => _findPlanning(context: context, invitationCode: _invitationCodeController.text),
                            child: const Text('Entrar'),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
      TebUtil.version.then((info) => setState(() => _info = info));
      _initializing = false;
      DeviceLogController(fireStoreInstance: FirebaseFirestore.instance).registerAccess(
        screenResolution: MediaQuery.of(context).size,
      );
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
            return _errorScreen(errorMessage: snapshot.error.toString());
            // ao final do processo
          } else {
            // irá avaliar se o usuário possui login ou não
            return hiveController.localUser.id.isEmpty
                ? _newPlanning()
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
