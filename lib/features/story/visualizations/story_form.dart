// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:planningpoker/components/messaging/custom_message.dart';
import 'package:planningpoker/components/screen_elements/custom_scaffold.dart';
import 'package:planningpoker/components/util/custom_return.dart';
import 'package:planningpoker/components/visual_elements/buttons_line.dart';
import 'package:planningpoker/components/visual_elements/custom_textFormField.dart';
import 'package:planningpoker/features/story/story.dart';
import 'package:planningpoker/features/story/story_controller.dart';

// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';

class StoryForm extends StatefulWidget {
  const StoryForm({super.key});

  @override
  State<StoryForm> createState() => _StoryFormState();
}

class _StoryFormState extends State<StoryForm> {
  var _story = Story();
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

  void _submit() async {
    if (_savingData) return;

    _savingData = true;

    if (!(_formKey.currentState?.validate() ?? true)) {
      _savingData = false;
    } else {
      // salva os dados
      _formKey.currentState?.save();
      StoryController storyController = Provider.of(context, listen: false);
      CustomReturn retorno;
      try {
        // remove a marcação de história em votação
        if (_story.status == StoryStatus.votingFinished) _story.status = StoryStatus.closed;
        retorno = await storyController.save(story: _story);
        if (retorno.returnType == ReturnType.sucess) {
          Navigator.of(context).pop();
        } else {
          CustomMessage.error(context, message: retorno.message);
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
      _nameController.text = _story.name;
      _urlController.text = _story.url;
      _descriptionController.text = _story.description;
      _pointsController.text = _story.points.toString();

      _initializing = false;
    }

    return CustomScaffold(
      title: _story.id.isEmpty ? 'Nova história' : 'Alterar história',
      body: SingleChildScrollView(
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
                  focusNode: _nameFocus,
                  nextFocusNode: _descriptionFocus,
                  labelText: 'Nome da história',
                  hintText: 'Nome da história',
                  onSave: (value) => _story.name = value ?? '',
                  prefixIcon: Icons.arrow_forward,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final finalValue = value ?? '';
                    if (finalValue.trim().isEmpty) return 'O nome deve ser informado';
                    return null;
                  },
                ),
                // Description
                CustomTextEdit(
                  context: context,
                  controller: _descriptionController,
                  focusNode: _descriptionFocus,
                  nextFocusNode: _urlFocus,
                  labelText: 'Resumo',
                  hintText: 'Resumo',
                  onSave: (value) => _story.description = value ?? '',
                  maxLines: 3,
                  prefixIcon: Icons.receipt,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final finalValue = value ?? '';
                    if (finalValue == '') return 'Informe um resumo da história para ajudar na votação';
                    return null;
                  },
                ),
                // url
                CustomTextEdit(
                  context: context,
                  controller: _urlController,
                  focusNode: _urlFocus,
                  labelText: 'Link',
                  hintText: 'Link para a história',
                  onSave: (value) => _story.url = value ?? '',
                  prefixIcon: Icons.link,
                  textInputAction: TextInputAction.next,
                ),
                // Points
                if (_story.status != StoryStatus.created || _story.points != 0)
                  CustomTextEdit(
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
                ButtonsLine(
                  buttons: [
                    Button(label: 'Cancelar', onPressed: () => Navigator.of(context).pop()),
                    Button(
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
    );
  }
}
