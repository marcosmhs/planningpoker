// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/main/visualizations/widgets/about_dialog_button.dart';
import 'package:planningpoker/features/planning_data/models/planning_poker.dart';
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
  //final TextEditingController _kanbanizeUrlController = TextEditingController();
  //final TextEditingController _kanbanizeApiKeyController = TextEditingController();
  //final TextEditingController _kanbanizeBoardIdController = TextEditingController();
  //final TextEditingController _kanbanizeLaneNameController = TextEditingController();
  //final TextEditingController _kanbanizeColumnNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _savingData = false;

  var _user = User();
  var _planningData = PlanningData();
  var _newPlanning = false;

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

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      final arguments = (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{}) as Map;
      _planningData = arguments['planningData'] ?? PlanningData();
      _user = arguments['user'] ?? User();
      _newPlanning = arguments['newPlanning'] ?? false;

      if (_user.id.isNotEmpty) {
        _nameController.text = _user.name;
        _accessCodeController.text = _user.accessCode;
        //_kanbanizeUrlController.text = _user.kanbanizeUrl;
        //_kanbanizeApiKeyController.text = _user.kanbanizeApiKey;
        //_kanbanizeBoardIdController.text = _user.kanbanizeBoardId;
        //_kanbanizeLaneNameController.text = _user.kanbanizeLaneName;
        //_kanbanizeColumnNameController.text = _user.kanbanizeColumnName;
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TebTextEdit(
                            width: screenWidth * 0.90,
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
                            icon: const Icon(Icons.control_point_rounded),
                            iconSize: 45,
                          )
                        ],
                      ),

                      // const Padding(
                      //   padding: EdgeInsets.only(top: 20, bottom: 5),
                      //   child: Text('Kanbanize (não obrigartório)'),
                      // ),

                      //// Kanbanize Url
                      //TebTextEdit(
                      //  context: context,
                      //  controller: _kanbanizeUrlController,
                      //  labelText: 'Kanbanize URL',
                      //  hintText: 'Kanbanize URL',
                      //  onSave: (value) => _user.kanbanizeUrl = value ?? '',
                      //  prefixIcon: Icons.link,
                      //  textInputAction: TextInputAction.next,
                      //),
                      //// kanbanize api key
                      //TebTextEdit(
                      //  context: context,
                      //  controller: _kanbanizeApiKeyController,
                      //  labelText: 'Kanbanize API Key',
                      //  hintText: 'Kanbanize API Key',
                      //  onSave: (value) => _user.kanbanizeApiKey = value ?? '',
                      //  isPassword: true,
                      //  prefixIcon: Icons.api,
                      //  textInputAction: TextInputAction.next,
                      //),

                      //Row(
                      //  children: [
                      //    // Board ID
                      //    TebTextEdit(
                      //      width: screenWidth * 0.3,
                      //      context: context,
                      //      controller: _kanbanizeBoardIdController,
                      //      labelText: 'Board ID',
                      //      hintText: 'Board ID',
                      //      onSave: (value) => _user.kanbanizeBoardId = value ?? '',
                      //      prefixIcon: Icons.commit_rounded,
                      //      textInputAction: TextInputAction.next,
                      //    ),
                      //    const Spacer(),
                      //    // Lane Name
                      //    TebTextEdit(
                      //      width: screenWidth * 0.65,
                      //      context: context,
                      //      controller: _kanbanizeLaneNameController,
                      //      labelText: 'Lane',
                      //      hintText: 'Lane',
                      //      onSave: (value) => _user.kanbanizeLaneName = value ?? '',
                      //      prefixIcon: Icons.table_rows_outlined,
                      //      textInputAction: TextInputAction.next,
                      //    ),
                      //  ],
                      //),

                      //// Lane Name
                      //TebTextEdit(
                      //  context: context,
                      //  controller: _kanbanizeColumnNameController,
                      //  labelText: 'Coluna',
                      //  hintText: 'Coluna',
                      //  onSave: (value) => _user.kanbanizeColumnName = value ?? '',
                      //  prefixIcon: Icons.view_column_outlined,
                      //  textInputAction: TextInputAction.next,
                      //),

                      TebButtonsLine(
                        padding: const EdgeInsets.only(top: 20),
                        buttons: [
                          TebButton(label: 'Cancelar', onPressed: () => Navigator.of(context).pop()), // TODO - alterar para excluir cadastro da planning se tbem cancelou o usuário
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
