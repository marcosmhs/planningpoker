// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:planningpoker/components/messaging/custom_message.dart';
import 'package:planningpoker/components/screen_elements/custom_scaffold.dart';
import 'package:planningpoker/components/util/custom_return.dart';
import 'package:planningpoker/components/visual_elements/custom_textFormField.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/planning_poker/planning_controller.dart';
import 'package:planningpoker/features/user/user.dart';
import 'package:planningpoker/features/user/user_controller.dart';
import 'package:provider/provider.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final TextEditingController _invitationCodeController = TextEditingController();
  final _user = User();

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
                  CustomTextEdit(
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
                  CustomMessage.error(context, message: 'Informe seu nome');
                } else {
                  _user.planningPokerId = Provider.of<PlanningPokerController>(context, listen: false).currentPlanning.id;
                  var customReturn = await userController.save(user: _user);
                  if (customReturn.returnType == ReturnType.error) {
                    FocusScopeNode currentFocus = FocusScope.of(ctx);
                    if (!currentFocus.hasPrimaryFocus) {
                      currentFocus.unfocus();
                    }

                    CustomMessage(
                      context: context,
                      messageText: customReturn.message,
                      messageType: MessageType.error,
                      durationInSeconds: 3,
                      modelType: ModelType.toast,
                      toastGravity: ToastGravity.TOP,
                    );
                  } else {
                    Navigator.of(context).popAndPushNamed(Routes.mainScreen);
                    Navigator.of(ctx).pop();
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
      CustomMessage.error(context, message: 'Ops, você não informou o código do convite');
      return;
    }

    var customReturn = await Provider.of<PlanningPokerController>(context, listen: false).setPlanningDataByInvitation(
      invitationCode: invitationCode,
    );
    if (customReturn.returnType == ReturnType.error) {
      CustomMessage.error(context, message: customReturn.message);
      return;
    }

    await _setUserData(buildContext: context);
  }

  @override
  Widget build(BuildContext context) {
    print(MediaQuery.of(context).size.width);
    return CustomScaffold(
      title: 'Planning Poker',
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: kIsWeb
                ? MediaQuery.of(context).size.width <= 750
                    ? MediaQuery.of(context).size.width
                    : MediaQuery.of(context).size.width * (MediaQuery.of(context).size.width <= 1000 ? 0.6 : 0.4)
                : MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('O que que fazer?', style: Theme.of(context).textTheme.headlineLarge),
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
                        child: CustomTextEdit(
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
