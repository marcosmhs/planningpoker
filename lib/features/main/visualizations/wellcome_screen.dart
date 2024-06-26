// ignore_for_file: use_build_context_synchronously

// ignore: depend_on_referenced_packages
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/main/visualizations/widgets/about_dialog_button.dart';
import 'package:planningpoker/features/main/visualizations/widgets/botton_info.dart';
import 'package:planningpoker/features/planning_data/models/planning_poker.dart';
import 'package:planningpoker/features/planning_data/planning_controller.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:planningpoker/features/user/user_controller.dart';
import 'package:planningpoker/local_data_controller.dart';
import 'package:planningpoker/main.dart';
import 'package:teb_package/teb_package.dart';

class WellcomeScreen extends StatefulWidget {
  const WellcomeScreen({super.key});

  @override
  State<WellcomeScreen> createState() => _WellcomeScreenState();
}

class _WellcomeScreenState extends State<WellcomeScreen> {
  var _info = TebUtil.packageInfo;
  final TextEditingController _invitationCodeController = TextEditingController();
  final TextEditingController _userAccessCodeController = TextEditingController();
  final _user = User();
  var _planningData = PlanningData();
  var _initializing = true;
  var analytics = FirebaseAnalytics.instance;

  void _findPlanning({required BuildContext context, required String invitationCode, String userAccessCode = ''}) async {
    if (invitationCode.isEmpty) {
      TebCustomMessage.error(context, message: 'Ops, você não informou o código do convite');
      return;
    }

    var planningPokerController = PlanningPokerController();

    var customReturn = await planningPokerController.setPlanningDataByInvitation(
      invitationCode: invitationCode,
    );
    if (customReturn.returnType == TebReturnType.error) {
      TebCustomMessage.error(context, message: customReturn.message);
      return;
    }

    _planningData = planningPokerController.currentPlanning;
    analytics.logEvent(name: 'finding_created_planning');

    if (userAccessCode.isEmpty) {
      await _setUserData(buildContext: context);
    } else {
      var user = await UserController().getUserByAccessCode(
        planningId: _planningData.id,
        userAccessCode: userAccessCode,
      );

      if (user.id.isEmpty) {
        TebCustomMessage.error(context, message: 'Código de acesso não encontrado');
        return;
      }

      Navigator.of(context).popAndPushNamed(Routes.mainScreen, arguments: {
        'user': user,
        'planningData': _planningData,
      });
    }
  }

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
                  // Access code
                  TebTextEdit(
                    context: ctx,
                    labelText: 'Código de acesso',
                    hintText: 'Informe seu código de acesso',
                    onSave: (value) => _user.accessCode = value ?? '',
                    initialValue: _user.accessCode,
                    prefixIcon: Icons.lock_person,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) => _user.accessCode = value ?? '',
                  ),
                  // role selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: TebText('Qual o seu papel?'),
                      ),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints.tightFor(height: 40),
                          child: ToggleButtons(
                            isSelected: selectedRole,
                            fillColor: Theme.of(context).primaryColorLight,
                            selectedColor: Theme.of(context).primaryColorLight,
                            onPressed: (index) {
                              setState(() {
                                _user.role = index == 0 ? Role.player : Role.spectator;
                                selectedRole = [index == 0, index == 1];
                              });
                            },
                            children: [
                              SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.3,
                                  child: TebText(
                                    'Jogador',
                                    textAlign: TextAlign.center,
                                    style: _user.role == Role.player
                                        ? TextStyle(color: Theme.of(context).cardColor)
                                        : TextStyle(color: Theme.of(context).primaryColor),
                                  )),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.3,
                                  child: TebText(
                                    'Criador de histórias',
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
                var userController = UserController();
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

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      TebUtil.version.then((info) => setState(() => _info = info));
      analytics.logEvent(name: 'landing_entering');
      _initializing = false;
    }
    return TebCustomScaffold(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const TebText('Planning Poker'),
          const SizedBox(width: 10),
          TebText(
            'v${_info.version}-${_info.buildNumber}',
            textSize: Theme.of(context).textTheme.labelMedium!.fontSize,
          )
        ],
      ),
      appBarActions: [
        IconButton(
          onPressed: () {
            PlanningPokerMain.of(context)?.changeTheme();
          },
          icon: const Icon(Icons.light_mode_outlined),
        ),
        const AboutDialogButton(),
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
                      onPressed: () {
                        analytics.logEvent(name: 'create_new_planning');
                        LocalDataController().getLocalThemeMode().then((themeMode) {
                          Navigator.of(context).popAndPushNamed(Routes.planningDataForm, arguments: {'themeMode': themeMode});
                        });
                      },
                      child: const Text('Criar uma nova partida'),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TebText(
                        'Entrar em uma partida já criada',
                        style: Theme.of(context).textTheme.headlineMedium,
                        padding: const EdgeInsets.only(bottom: 20),
                      ),
                      const TebText('Caso tenha o código de convite e uma partida que já está em andamento, informe ele abaixo'),
                      ConstrainedBox(
                        constraints: BoxConstraints.tightFor(height: 72, width: MediaQuery.of(context).size.width * 0.75),
                        child: TebTextEdit(
                          context: context,
                          labelText: 'Código da partida',
                          controller: _invitationCodeController,
                        ),
                      ),
                      const TebText(
                        'Se você já tiver criado seu usuário para uma partida, informe o código de acesso do usuário que você criou',
                        padding: EdgeInsets.only(top: 10),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints.tightFor(height: 72, width: MediaQuery.of(context).size.width * 0.75),
                        child: TebTextEdit(
                          context: context,
                          labelText: 'Se já tiver um código de acesso informe-o abaixo',
                          controller: _userAccessCodeController,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints.tightFor(height: 50, width: MediaQuery.of(context).size.width * 0.75),
                          child: ElevatedButton(
                            onPressed: () => _findPlanning(
                              context: context,
                              invitationCode: _invitationCodeController.text,
                              userAccessCode: _userAccessCodeController.text,
                            ),
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
      bottomNavigationBar: const BottonInfo(),
    );
  }
}
