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
import 'package:teb_package/visual_elements/teb_checkbox.dart';
import 'package:teb_package/visual_elements/teb_text_form_field.dart';

class PlanningForm extends StatefulWidget {
  const PlanningForm({super.key});

  @override
  State<PlanningForm> createState() => _PlanningFormState();
}

class _PlanningFormState extends State<PlanningForm> {
  var _planningData = PlanningData();
  var _user = User();
  bool _initializing = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _invitationCodeController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userKanbanizeUrlController = TextEditingController();
  final TextEditingController _userKanbanizeApiKeyController = TextEditingController();
  final TextEditingController _userKanbanizeBoardIdController = TextEditingController();
  final TextEditingController _userKanbanizeLaneNameController = TextEditingController();
  final TextEditingController _userKanbanizeColumnNameController = TextEditingController();

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
            _user.role = Role.spectator;
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

    var size = MediaQuery.of(context).size;

    var screenWidth = kIsWeb
        ? size.width <= 750
            ? size.width
            : size.width * (size.width <= 1000 ? 0.7 : 0.5)
        : size.width;

    return TebCustomScaffold(
      title: Text(_newPlanning ? 'Nova partida' : 'Alterar partida'),
      appBarActions: const [
        AboutDialogButton(),
      ],
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

                      const Padding(
                        padding: EdgeInsets.only(top: 20, bottom: 5),
                        child: Text('Kanbanize (não obrigartório)'),
                      ),

// https://medium.com/flutter-comunidade-br/flutter-como-consumir-uma-api-rest-e4bfbba91fd2

                      // Kanbanize Url
                      TebTextEdit(
                        context: context,
                        controller: _userKanbanizeUrlController,
                        labelText: 'Kanbanize URL',
                        hintText: 'Kanbanize URL',
                        onSave: (value) => _user.kanbanizeUrl = value ?? '',
                        prefixIcon: Icons.link,
                        textInputAction: TextInputAction.next,
                      ),
                      // kanbanize api key
                      TebTextEdit(
                        context: context,
                        controller: _userKanbanizeApiKeyController,
                        labelText: 'Kanbanize API Key',
                        hintText: 'Kanbanize API Key',
                        onSave: (value) => _user.kanbanizeApiKey = value ?? '',
                        isPassword: true,
                        prefixIcon: Icons.api,
                        textInputAction: TextInputAction.next,
                      ),

                      Row(
                        children: [
                          // Board ID
                          TebTextEdit(
                            width: screenWidth * 0.3,
                            context: context,
                            controller: _userKanbanizeBoardIdController,
                            labelText: 'Board ID',
                            hintText: 'Board ID',
                            onSave: (value) => _user.kanbanizeBoardId = value ?? '',
                            prefixIcon: Icons.commit_rounded,
                            textInputAction: TextInputAction.next,
                          ),
                          const Spacer(),
                          // Lane Name
                          TebTextEdit(
                            width: screenWidth * 0.65,
                            context: context,
                            controller: _userKanbanizeLaneNameController,
                            labelText: 'Lane',
                            hintText: 'Lane',
                            onSave: (value) => _user.kanbanizeLaneName = value ?? '',
                            prefixIcon: Icons.table_rows_outlined,
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),

                      // Lane Name
                      TebTextEdit(
                        context: context,
                        controller: _userKanbanizeColumnNameController,
                        labelText: 'Coluna',
                        hintText: 'Coluna',
                        onSave: (value) => _user.kanbanizeColumnName = value ?? '',
                        prefixIcon: Icons.view_column_outlined,
                        textInputAction: TextInputAction.next,
                      ),

                      TebCheckBox(
                        context: context,
                        value: _planningData.othersCanCreateStories,
                        title: 'Outros espectadores podem criar histórias',
                        onChanged: (value) => setState(() => _planningData.othersCanCreateStories = value!),
                      ),

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
