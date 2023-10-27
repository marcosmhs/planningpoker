// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/features/main/visualizations/about_dialog_button.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/story/models/story.dart';
import 'package:planningpoker/features/story/story_controller.dart';
import 'package:planningpoker/features/user/model/user.dart';

// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';
import 'package:teb_package/messaging/teb_custom_message.dart';
import 'package:teb_package/screen_elements/teb_custom_scaffold.dart';
import 'package:teb_package/util/teb_return.dart';
import 'package:teb_package/util/teb_url_manager.dart';
import 'package:teb_package/visual_elements/teb_buttons_line.dart';
import 'package:teb_package/visual_elements/teb_text.dart';
import 'package:teb_package/visual_elements/teb_text_form_field.dart';

class StoryForm extends StatefulWidget {
  const StoryForm({super.key});

  @override
  State<StoryForm> createState() => _StoryFormState();
}

class _StoryFormState extends State<StoryForm> {
  var _story = Story();
  var _planningData = PlanningData();
  var _user = User();

  bool _initializing = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _urlFocus = FocusNode();

  final _formKey = GlobalKey<FormState>();
  bool _savingData = false;
  var _storyUrlLink = '';

  void _submit() async {
    if (_savingData) return;

    _savingData = true;

    if (!(_formKey.currentState?.validate() ?? true)) {
      _savingData = false;
    } else {
      // salva os dados
      _formKey.currentState?.save();
      StoryController storyController = Provider.of(context, listen: false);
      TebCustomReturn retorno;
      try {
        // remove a marcação de história em votação
        if (_story.status == StoryStatus.votingFinished) _story.status = StoryStatus.closed;
        retorno = await storyController.save(story: _story, planningPokerId: _planningData.id);
        if (retorno.returnType == TebReturnType.sucess) {
          Navigator.of(context).pop();
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
      _story = arguments['story'] ?? Story();
      _planningData = arguments['planningData'] ?? PlanningData();
      _user = arguments['user'] ?? User();

      _nameController.text = _story.name;
      _urlController.text = _story.url;
      _descriptionController.text = _story.description;
      _pointsController.text = _story.points.toString();
      _storyUrlLink = _story.url;
      _initializing = false;
    }

    return TebCustomScaffold(
      title: Text(_user.creator
          ? _story.id.isEmpty
              ? 'Nova história'
              : 'Alterar história'
          : 'Detalhes da história'),
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
                      focusNode: _nameFocus,
                      nextFocusNode: _descriptionFocus,
                      labelText: 'Nome/número da história',
                      hintText: 'Nome/número da história',
                      onSave: (value) => _story.name = value ?? '',
                      prefixIcon: Icons.arrow_forward,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final finalValue = value ?? '';
                        if (finalValue.trim().isEmpty) return 'O nome deve ser informado';
                        return null;
                      },
                    ),
                    const TebText(
                      text: 'Se você utiliza o Jira, informe aqui o código do card',
                      fontStyle: FontStyle.italic,
                      padding: EdgeInsets.only(bottom: 5),
                    ),
                    // Description
                    TebTextEdit(
                      context: context,
                      controller: _descriptionController,
                      focusNode: _descriptionFocus,
                      nextFocusNode: _urlFocus,
                      labelText: 'Resumo',
                      hintText: 'Resumo',
                      onSave: (value) => _story.description = value ?? '',
                      maxLines: 3,
                      prefixIcon: Icons.receipt,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final finalValue = value ?? '';
                        if (finalValue == '') return 'Informe um resumo da história para ajudar na votação';
                        return null;
                      },
                    ),
                    // url
                    TebTextEdit(
                      context: context,
                      controller: _urlController,
                      focusNode: _urlFocus,
                      labelText: 'Link',
                      hintText: 'Link para a história',
                      onSave: (value) => _story.url = value ?? '',
                      onChanged: (value) => setState(() => _storyUrlLink = value!),
                      prefixIcon: Icons.link,
                      textInputAction: TextInputAction.next,
                    ),
                    // URL Example
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          TebUrlManager.launchUrl(url: _storyUrlLink).then((value) {
                            if (!value) TebCustomMessage.error(context, message: 'Erro ao abrir o link');
                          });
                        },
                        child: Text(
                          _storyUrlLink,
                          style: TextStyle(color: Theme.of(context).primaryColor),
                        ),
                      ),
                    ),
                    // Points
                    if (_story.status != StoryStatus.created || _story.points != 0)
                      TebTextEdit(
                        context: context,
                        controller: _pointsController,
                        keyboardType: TextInputType.number,
                        labelText: 'Pontos',
                        hintText: 'Pontos da a história',
                        onSave: (value) => _story.points = int.tryParse(value ?? '') ?? 0,
                        prefixIcon: Icons.numbers,
                        textInputAction: TextInputAction.send,
                      ),
                    const SizedBox(height: 20),
                    // Butons
                    TebButtonsLine(
                      buttons: [
                        TebButton(label: 'Cancelar', onPressed: () => Navigator.of(context).pop()),
                        if (_user.creator)
                          TebButton(
                            label: _story.status == StoryStatus.votingFinished ? 'Concluir história' : 'Salvar',
                            onPressed: _submit,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
