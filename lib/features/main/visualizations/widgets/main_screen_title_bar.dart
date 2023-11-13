import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:teb_package/messaging/teb_custom_message.dart';

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
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Planning data
            Row(
              children: [
                // name
                Text(widget.planningData.name),
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
            // user info
            Row(
              children: [
                Text(
                  '${widget.user.name} - ',
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.labelLarge!.fontSize,
                    color: Theme.of(context).cardColor,
                  ),
                ),
                Text(
                  widget.user.accessCode,
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.labelMedium!.fontSize,
                    color: Theme.of(context).cardColor,
                  ),
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
            ),
          ],
        ),
        const SizedBox(width: 20),

        // invitation code
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.planningData.invitationCode,
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.labelLarge!.fontSize,
                    color: Theme.of(context).cardColor,
                  ),
                ),
              ],
            ),
            Text(
              'Código de convite',
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.labelMedium!.fontSize,
                color: Theme.of(context).cardColor,
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () {
            Clipboard.setData(
              ClipboardData(text: widget.planningData.invitationCode),
            ).then((value) => TebCustomMessage(
                context: context,
                messageText: 'Código da partida copiado para a área de transferência',
                messageType: TebMessageType.info));
          },
          child: const Icon(Icons.copy, size: 15),
        ),
      ],
    );
  }
}
