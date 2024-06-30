// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/main/visualizations/widgets/about_dialog_button.dart';
import 'package:planningpoker/features/planning_data/models/planning_poker.dart';
import 'package:planningpoker/features/planning_data/planning_controller.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:planningpoker/features/user/user_controller.dart';

// ignore: depend_on_referenced_packages
import 'package:teb_package/messaging/teb_custom_message.dart';
import 'package:teb_package/screen_elements/teb_custom_scaffold.dart';
import 'package:teb_package/util/teb_return.dart';
import 'package:teb_package/util/teb_uid_generator.dart';
import 'package:teb_package/visual_elements/teb_buttons_line.dart';
import 'package:teb_package/visual_elements/teb_text.dart';
import 'package:teb_package/visual_elements/teb_text_form_field.dart';

class UserForm extends StatefulWidget {
  const UserForm({super.key});

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  bool _initializing = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accessCodeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _savingData = false;

  var _user = User();
  var _planningData = PlanningData();
  var _newPlanning = false;

  List<bool> _selectedRole = [true, false];

  void _submit() async {
    if (_savingData) return;

    _savingData = true;

    if (!(_formKey.currentState?.validate() ?? true)) {
      _savingData = false;
    } else {
      // salva os dados
      _formKey.currentState?.save();
      var userController = UserController();
      TebCustomReturn retorno;
      try {
        if (_newPlanning) {
          _user.creator = true;
          _user.role = Role.spectator;
          _user.planningPokerId = _planningData.id;
        }
        retorno = await userController.save(user: _user);

        if (retorno.returnType != TebReturnType.sucess) {
          TebCustomMessage.error(context, message: retorno.message);
        }

        if (_newPlanning) {
          Navigator.of(context).popAndPushNamed(Routes.mainScreen, arguments: {
            'user': _user,
            'planningData': _planningData,
          });
        } else {
          Navigator.of(context).pop();
        }
      } finally {
        _savingData = false;
      }
    }
  }

  void _cancel() async {
    if (_newPlanning) {
      PlanningPokerController().delete(planningData: _planningData);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      final arguments = (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{}) as Map;
      _planningData = arguments['planningData'] ?? PlanningData();
      _user = arguments['user'] ?? User();
      _newPlanning = arguments['newPlanning'] ?? false;

      _accessCodeController.text = _user.accessCode;
      _selectedRole = [_user.isPlayer, _user.isSpectator];

      if (_user.id.isNotEmpty) {
        _nameController.text = _user.name;
      }

      _initializing = false;
    }

    var size = MediaQuery.of(context).size;

    var screenWidth = kIsWeb
        ? size.width <= 750
            ? size.width
            : size.width * (size.width <= 1000 ? 0.7 : 0.5)
        : size.width;

    return TebCustomScaffold(
      title: const TebText('Seus dados'),
      appBarActions: const [AboutDialogButton()],
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: screenWidth,
            child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 20, bottom: 5),
                        child: Text('Seus dados'),
                      ),
                      // user name
                      TebTextEdit(
                        context: context,
                        controller: _nameController,
                        labelText: 'Seu nome',
                        hintText: 'Informe seu nome',
                        onSave: (value) => _user.name = value ?? '',
                        prefixIcon: Icons.person,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final finalValue = value ?? '';
                          if (finalValue.trim().isEmpty) return 'O seu nome deve ser informado';
                          return null;
                        },
                      ),
                      // access code
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TebTextEdit(
                            width: screenWidth * 0.80,
                            context: context,
                            controller: _accessCodeController,
                            labelText: 'Código de acesso',
                            hintText: 'Informe seu codigo de acesso',
                            onSave: (value) => _user.accessCode = value ?? '',
                            prefixIcon: Icons.person,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final finalValue = value ?? '';
                              if (finalValue.trim().isEmpty) return 'O código de acesso deve ser informado';
                              return null;
                            },
                          ),
                          const Spacer(),
                          IconButton.filled(
                            onPressed: () {
                              _user.accessCode = TebUidGenerator.userAccessCode;
                              _accessCodeController.text = _user.accessCode;
                            },
                            icon: const Icon(Icons.refresh_sharp),
                            iconSize: 35,
                          )
                        ],
                      ),

                      //role
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
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
                                  isSelected: _selectedRole,
                                  fillColor: Theme.of(context).primaryColorLight,
                                  selectedColor: Theme.of(context).primaryColorLight,
                                  onPressed: (index) {
                                    setState(() {
                                      _user.role = index == 0 ? Role.player : Role.spectator;
                                      _selectedRole = [index == 0, index == 1];
                                    });
                                  },
                                  children: [
                                    SizedBox(
                                        width: screenWidth * 0.3,
                                        child: TebText(
                                          'Jogador',
                                          textAlign: TextAlign.center,
                                          style: _user.role == Role.player
                                              ? TextStyle(color: Theme.of(context).cardColor)
                                              : TextStyle(color: Theme.of(context).primaryColor),
                                        )),
                                    SizedBox(
                                        width: screenWidth * 0.3,
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
                      ),

                      TebButtonsLine(
                        padding: const EdgeInsets.only(top: 20),
                        buttons: [
                          TebButton(label: 'Cancelar', onPressed: _cancel), //TODO - testar
                          TebButton(label: 'Continuar', onPressed: _submit),
                        ],
                      ),
                    ],
                  ),
                )),
          ),
        ),
      ),
    );
  }
}
