import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/planning_data/models/planning_poker.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:teb_package/messaging/teb_custom_message.dart';
import 'package:teb_package/visual_elements/teb_text.dart';

class TitleBarWidget extends StatefulWidget {
  final PlanningData planningData;
  final User user;
  final BuildContext context;

  const TitleBarWidget({
    super.key,
    required this.planningData,
    required this.user,
    required this.context,
  });

  @override
  State<TitleBarWidget> createState() => _TitleBarWidgetState();
}

class _TitleBarWidgetState extends State<TitleBarWidget> {
  Widget _invitationData(BuildContext context) {
    return Row(
      children: [
        Row(
          children: [
            TebText(
              'Código da partida: ',
              style: TextStyle(fontSize: Theme.of(context).textTheme.labelLarge!.fontSize),
            ),
            TebText(
              widget.planningData.invitationCode,
              style: TextStyle(fontSize: Theme.of(context).textTheme.labelLarge!.fontSize),
              padding: const EdgeInsets.only(left: 3),
            ),
          ],
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () {
            Clipboard.setData(
              ClipboardData(text: widget.planningData.invitationCode),
            ).then(
              (value) => TebCustomMessage(
                  context: context,
                  messageText: 'Código da partida copiado para a área de transferência',
                  messageType: TebMessageType.info),
            );
          },
          child: const Icon(Icons.copy, size: 15),
        ),
      ],
    );
  }

  Widget _planningData(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // name
            TebText(widget.planningData.name),
            const SizedBox(width: 10),
            // edit link
            if (widget.user.creator)
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(
                  Routes.planningDataForm,
                  arguments: {'planningData': widget.planningData, 'user': widget.user},
                ),
                child: const Icon(Icons.edit, size: 20),
              ),
          ],
        ),
        const SizedBox(height: 5),
        _invitationData(context),
      ],
    );
  }

  Widget _usetData(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // user name
        Row(
          children: [
            TebText(
              widget.user.name,
              textSize: 18,
              padding: const EdgeInsets.only(right: 10),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(
                Routes.userForm,
                arguments: {'planningData': widget.planningData, 'user': widget.user},
              ),
              child: const Icon(Icons.edit, size: 20),
            ),
          ],
        ),
        // invitation code
        Row(
          children: [
            TebText(
              'Código de acesso: ${widget.user.accessCode}',
              textSize: Theme.of(context).textTheme.labelMedium!.fontSize,
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () {
                Clipboard.setData(
                  ClipboardData(text: widget.user.accessCode),
                ).then((value) => TebCustomMessage(
                    context: context,
                    messageText: 'Código de acesso copiado para a área de transferência',
                    messageType: TebMessageType.info));
              },
              child: const Icon(Icons.copy, size: 15),
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _planningData(context),
        const SizedBox(width: 80),
        // User data
        _usetData(context),
      ],
    );
  }
}
