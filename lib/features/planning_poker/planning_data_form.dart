// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/components/messaging/custom_message.dart';
import 'package:planningpoker/components/screen_elements/custom_scaffold.dart';
import 'package:planningpoker/components/util/custom_return.dart';
import 'package:planningpoker/components/util/uid_generator.dart';
import 'package:planningpoker/components/visual_elements/buttons_line.dart';
import 'package:planningpoker/components/visual_elements/custom_textFormField.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/planning_poker/planning_poker.dart';
import 'package:planningpoker/features/planning_poker/planning_controller.dart';
import 'package:planningpoker/features/user/user.dart';
import 'package:planningpoker/features/user/user_controller.dart';

// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';

class PlanningDataForm extends StatefulWidget {
  const PlanningDataForm({super.key});

  @override
  State<PlanningDataForm> createState() => _PlanningDataFormState();
}

class _PlanningDataFormState extends State<PlanningDataForm> {
  var _planningData = PlanningData();
  var _user = User();
  bool _initializing = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _invitationCodeController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _savingData = false;
  bool _newPlanning = false;

  //List<bool> _selectedRole = [true, false];

  void _submit() async {
    if (_savingData) return;

    _savingData = true;

    if (!(_formKey.currentState?.validate() ?? true)) {
      _savingData = false;
    } else {
      // salva os dados
      _formKey.currentState?.save();
      PlanningPokerController planningController = Provider.of(context, listen: false);
      UserController userController = Provider.of(context, listen: false);
      CustomReturn retorno;
      try {
        if (_planningData.id.isEmpty) {
          _planningData.id = UidGenerator.firestoreUid;
        }

        retorno = await planningController.save(planningData: _planningData);
        if (retorno.returnType == ReturnType.sucess) {
          if (_newPlanning) {
            _user.creator = true;
            _user.planningPokerId = _planningData.id;
          }
          userController.save(user: _user);
          CustomMessage.sucess(context, message: _newPlanning ? 'Partida criada!' : 'Partida alterada');
          if (_newPlanning) {
            Navigator.of(context).popAndPushNamed(Routes.mainScreen, arguments: {
              'user': _user,
              'planningData': _planningData,
            });
          } else {
            Navigator.of(context).pop();
          }
        } else {
          CustomMessage.error(context, message: retorno.message);
        }
      } finally {
        _savingData = false;
      }
    }
  }

  //Widget _roleSelection(BuildContext context) {
  //  return Container(
  //    padding: const EdgeInsets.all(8),
  //    child: Row(
  //      children: [
  //        const Text('Qual o seu papel?'),
  //        const Spacer(),
  //        Center(
  //          child: ConstrainedBox(
  //            constraints: const BoxConstraints.tightFor(height: 40),
  //            child: ToggleButtons(
  //              isSelected: _selectedRole,
  //              fillColor: Theme.of(context).primaryColor,
  //              selectedColor: Colors.black,
  //              onPressed: (index) {
  //                setState(() {
  //                  _user.role = index == 0 ? Role.player : Role.spectator;
  //                  _selectedRole = [index == 0, index == 1];
  //                });
  //              },
  //              children: [
  //                SizedBox(
  //                    width: MediaQuery.of(context).size.width * 0.3,
  //                    child: Text(
  //                      'Jogador',
  //                      textAlign: TextAlign.center,
  //                      style: _user.role == Role.player
  //                          ? TextStyle(color: Theme.of(context).cardColor)
  //                          : TextStyle(color: Theme.of(context).primaryColor),
  //                    )),
  //                SizedBox(
  //                    width: MediaQuery.of(context).size.width * 0.3,
  //                    child: Text(
  //                      'Espectador',
  //                      textAlign: TextAlign.center,
  //                      style: _user.role == Role.spectator
  //                          ? TextStyle(color: Theme.of(context).cardColor)
  //                          : TextStyle(color: Theme.of(context).primaryColor),
  //                    )),
  //              ],
  //            ),
  //          ),
  //        ),
  //      ],
  //    ),
  //  );
  //}

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      final arguments = (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{}) as Map;
      _planningData = arguments['planningData'] ?? PlanningData();
      _user = arguments['user'] ?? User();

      _newPlanning = _planningData.id.isEmpty;
      _planningData.invitationCode = _newPlanning ? UidGenerator.invitationCode : _planningData.invitationCode;
      _nameController.text = _planningData.name;
      _invitationCodeController.text = _planningData.invitationCode;

      if (_user.id.isNotEmpty) {
        _userNameController.text = _user.name;
        //_selectedRole = [_user.role == Role.player, _user.role == Role.spectator];
      }

      _initializing = false;
    }

    return CustomScaffold(
      title: Text(_newPlanning ? 'Nova partida' : 'Alterar partida'),
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: kIsWeb
                ? MediaQuery.of(context).size.width <= 750
                    ? MediaQuery.of(context).size.width
                    : MediaQuery.of(context).size.width * (MediaQuery.of(context).size.width <= 1000 ? 0.6 : 0.4)
                : MediaQuery.of(context).size.width,
            child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // name
                      CustomTextEdit(
                        context: context,
                        controller: _nameController,
                        labelText: 'Nome da partida',
                        hintText: 'Nome da partida',
                        onSave: (value) => _planningData.name = value ?? '',
                        prefixIcon: Icons.casino_rounded,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final finalValue = value ?? '';
                          if (finalValue.trim().isEmpty) return 'O nome deve ser informado';
                          return null;
                        },
                      ),
                      // Code
                      CustomTextEdit(
                        context: context,
                        controller: _invitationCodeController,
                        labelText: 'Código de convite',
                        hintText: 'Informe o código do convite',
                        onSave: (value) => _planningData.invitationCode = value ?? '',
                        upperCase: true,
                        prefixIcon: Icons.mail_lock_sharp,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final finalValue = value ?? '';
                          if (finalValue == '') return 'Informe o código para convidar outras pessoas';
                          return null;
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 20, bottom: 5),
                        child: Text('Seu nome'),
                      ),
                      // user name
                      CustomTextEdit(
                        context: context,
                        controller: _userNameController,
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

                      // Role
                      //_roleSelection(context),

                      const SizedBox(height: 20),
                      // Butons
                      ButtonsLine(
                        buttons: [
                          Button(label: 'Cancelar', onPressed: () => Navigator.of(context).pop()),
                          Button(label: 'Continuar', onPressed: _submit),
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
