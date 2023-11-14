import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:teb_package/messaging/teb_custom_message.dart';
import 'package:teb_package/visual_elements/teb_text.dart';

class MainScreenTitleBar extends StatefulWidget {
  final PlanningData planningData;
  final User user;
  final BuildContext context;

  const MainScreenTitleBar({
    super.key,
    required this.planningData,
    required this.user,
    required this.context,
  });

  @override
  State<MainScreenTitleBar> createState() => _MainScreenTitleBarState();
}

class _MainScreenTitleBarState extends State<MainScreenTitleBar> {
  Widget _invitationData(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.planningData.invitationCode,
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.labelLarge!.fontSize,
                    //color: Theme.of(context).cardColor,
                  ),
                ),
              ],
            ),
            Text(
              'Código de convite',
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.labelMedium!.fontSize,
                //color: Theme.of(context).cardColor,
              ),
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
    return Row(
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
    );
  }

  Widget _usetData(BuildContext context) {
    return Row(
      children: [
        TebText(
          '${widget.user.name} - ',
          textSize: Theme.of(context).textTheme.labelLarge!.fontSize,
        ),
        TebText(
          widget.user.accessCode,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Planning data
            _planningData(context),
            // User data
            _usetData(context),
          ],
        ),
        const SizedBox(width: 20),

        // invitation data
        _invitationData(context),
      ],
    );
  }
}
