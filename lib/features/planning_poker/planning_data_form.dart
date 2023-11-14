// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/main/visualizations/about_dialog_button.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/planning_poker/planning_controller.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:planningpoker/features/user/user_controller.dart';

// ignore: depend_on_referenced_packages
import 'package:teb_package/messaging/teb_custom_message.dart';
import 'package:teb_package/screen_elements/teb_custom_scaffold.dart';
import 'package:teb_package/util/teb_return.dart';
import 'package:teb_package/util/teb_uid_generator.dart';
import 'package:teb_package/visual_elements/teb_buttons_line.dart';
import 'package:teb_package/visual_elements/teb_checkbox.dart';
import 'package:teb_package/visual_elements/teb_text_form_field.dart';

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

  void _submit() async {
    if (_savingData) return;

    _savingData = true;

    if (!(_formKey.currentState?.validate() ?? true)) {
      _savingData = false;
    } else {
      // salva os dados
      _formKey.currentState?.save();
      var planningController = PlanningPokerController();
      var userController = UserController();
      TebCustomReturn retorno;
      try {
        if (_planningData.id.isEmpty) {
          _planningData.id = TebUidGenerator.firestoreUid;
        }

        retorno = await planningController.save(planningData: _planningData);
        if (retorno.returnType == TebReturnType.sucess) {
          if (_newPlanning) {
            _user.creator = true;
            _user.planningPokerId = _planningData.id;
          }
          userController.save(user: _user);
          TebCustomMessage.sucess(context, message: _newPlanning ? 'Partida criada!' : 'Partida alterada');
          if (_newPlanning) {
            Navigator.of(context).popAndPushNamed(Routes.mainScreen, arguments: {
              'user': _user,
              'planningData': _planningData,
            });
          } else {
            Navigator.of(context).pop();
          }
        } else {
          TebCustomMessage.error(context, message: retorno.message);
        }
      } finally {
        _savingData = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      final arguments = (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{}) as Map;
      _planningData = arguments['planningData'] ?? PlanningData();
      _user = arguments['user'] ?? User();

      _newPlanning = _planningData.id.isEmpty;
      _planningData.invitationCode = _newPlanning ? TebUidGenerator.invitationCode : _planningData.invitationCode;
      _nameController.text = _planningData.name;
      _invitationCodeController.text = _planningData.invitationCode;

      if (_user.id.isNotEmpty) {
        _userNameController.text = _user.name;
      }

      _initializing = false;
    }

    return TebCustomScaffold(
      title: Text(_newPlanning ? 'Nova partida' : 'Alterar partida'),
      appBarActions: const [
        AboutDialogButton(),
      ],
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
                      TebTextEdit(
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
                      TebTextEdit(
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
                      TebTextEdit(
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

                      TebCheckBox(
                        context: context,
                        value: _planningData.othersCanCreateStories,
                        title: 'Outros espectadores podem criar histórias',
                        onChanged: (value) => setState(() => _planningData.othersCanCreateStories = value!),
                      ),

                      // Role
                      //_roleSelection(context),

                      const SizedBox(height: 20),
                      // Butons
                      TebButtonsLine(
                        buttons: [
                          TebButton(label: 'Cancelar', onPressed: () => Navigator.of(context).pop()),
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
