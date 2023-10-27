// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:teb_package/util/teb_url_manager.dart';
import 'package:teb_package/util/teb_util.dart';
import 'package:teb_package/visual_elements/teb_buttons_line.dart';
import 'package:teb_package/visual_elements/teb_text.dart';

class AboutDialogButton extends StatefulWidget {
  const AboutDialogButton({super.key});

  @override
  State<AboutDialogButton> createState() => _AboutDialogButtonState();
}

class _AboutDialogButtonState extends State<AboutDialogButton> {
  Future<void> _about({required BuildContext context}) async {
    final info = await TebUtil.version;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          insetPadding: kIsWeb
              ? MediaQuery.of(context).size.width <= 500
                  ? EdgeInsets.zero
                  : EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width <= 1000 ? 0 : MediaQuery.of(context).size.width * 0.3)
              : EdgeInsets.zero,
          scrollable: true,
          title: const TebText(text: 'Sobre', textSize: 30),
          titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
          content: StatefulBuilder(
            builder: (BuildContext ctx2, StateSetter setState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TebText(
                    text: 'Planning Poker v${info.version}.${info.buildNumber}',
                    textSize: 25,
                    padding: const EdgeInsets.only(bottom: 20),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const TebText(text: 'Desenvolvido por ', textSize: 18),
                      InkWell(
                        onTap: () => TebUrlManager.launchUrl(url: 'https://www.marcosmhs.com.br'),
                        child: TebText(
                          text: 'Marcos H. Silva',
                          color: Theme.of(context).primaryColor,
                          textSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => TebUrlManager.launchUrl(url: 'mailto:marcosmhs@live.com'),
                    child: TebText(text: 'marcosmhs@live.com', color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => TebUrlManager.launchUrl(url: 'https://github.com/marcosmhs/'),
                    child: TebText(text: 'https://github.com/marcosmhs/', color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TebButton(label: 'Fechar', onPressed: () => Navigator.of(dialogContext).pop()),
                    ],
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _about(context: context),
      icon: const Icon(Icons.question_mark_rounded),
    );
  }
}
