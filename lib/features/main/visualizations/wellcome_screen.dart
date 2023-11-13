// ignore_for_file: use_build_context_synchronously

// ignore: depend_on_referenced_packages
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/main/visualizations/botton_info.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/planning_poker/planning_controller.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:planningpoker/features/user/user_controller.dart';
import 'package:teb_package/teb_package.dart';

class WellComeScreen extends StatefulWidget {
  const WellComeScreen({super.key});

  @override
  State<WellComeScreen> createState() => _WellComeScreenState();
}

class _WellComeScreenState extends State<WellComeScreen> {
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
      //appBarActions: [
      //  IconButton(
      //      onPressed: () {
      //        TebCustomDialog(context: context).informationDialog(
      //            message:
      //                'Desenvolvido por um programador entediado durante suas férias.\n\nImportante:\n1 - Evite colocar dados sensíveis nas descrições dos cards.\n2 - Plannings com mais de 5 dias serão excluídas\n\n Divirta-se');
      //      },
      //      icon: const Icon(Icons.question_mark))
      //],
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
                        Navigator.of(context).popAndPushNamed(Routes.planningDataForm);
                      },
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
