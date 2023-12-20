// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:planningpoker/features/story/models/story.dart';
import 'package:planningpoker/features/story/models/story_vote.dart';
import 'package:planningpoker/features/story/story_controller.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:teb_package/messaging/teb_custom_dialog.dart';
import 'package:teb_package/messaging/teb_custom_message.dart';
import 'package:teb_package/util/teb_return.dart';
import 'package:teb_package/util/teb_url_manager.dart';
import 'package:teb_package/visual_elements/teb_text.dart';

class VontingInfo extends StatefulWidget {
  const VontingInfo({
    super.key,
    required this.size,
    required this.user,
    required this.storyVotesList,
    required this.votingStory,
  });

  final Size size;
  final User user;
  final List<StoryVote> storyVotesList;
  final Story votingStory;

  @override
  State<VontingInfo> createState() => _VontingInfoState();
}

class _VontingInfoState extends State<VontingInfo> {
  void _setStoryPoints({required int points}) {
    if (widget.storyVotesList.isEmpty) {
      TebCustomMessage.error(context, message: 'Esta história ainda não possui votos');
      return;
    }
    TebCustomDialog(context: context)
        .confirmationDialog(
            message: 'Deseja atualizar os pontos desta história para ${points == 0 ? 'ym café' : points} e finalizá-la?')
        .then((value) async {
      if (value == true) {
        widget.votingStory.points = points;
        widget.votingStory.status = StoryStatus.votingFinished;
        widget.storyVotesList.clear();
        var customReturn =
            await StoryController().save(story: widget.votingStory, planningPokerId: widget.votingStory.planningPokerId);
        if (customReturn.returnType == TebReturnType.sucess) {
          TebCustomMessage.sucess(context, message: 'História atualizada com sucesso.');
        } else {
          TebCustomMessage.error(context, message: customReturn.message);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var votesAvarege = 0.0;
    var minVote = 0;
    var maxVote = 0;

    if (widget.storyVotesList.isNotEmpty) {
      var votesPoints = widget.storyVotesList.map((e) => e.points).toList();
      var votesPointsTotal = votesPoints.fold(0, (p, c) => p + c);
      votesAvarege = votesPointsTotal / votesPoints.length;
      minVote = votesPoints.reduce(min);
      maxVote = votesPoints.reduce(max);
    }

    return SizedBox(
      width: widget.size.width * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: TebText(
              'Votando\nagora',
              textAlign: TextAlign.center,
              textStyle: Theme.of(context).textTheme.headlineLarge!.fontStyle,
              textWeight: FontWeight.bold,
              textSize: Theme.of(context).textTheme.labelLarge!.fontSize,
              textColor: Theme.of(context).textTheme.labelLarge!.color,
            ),
            title: TebText(widget.votingStory.name),
            subtitle: TebText(widget.votingStory.description),
            trailing: widget.votingStory.url.isEmpty
                ? null
                :
                // url
                Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: GestureDetector(
                      onTap: () {
                        TebUrlManager.launchUrl(url: widget.votingStory.url).then((value) {
                          if (!value) TebCustomMessage.error(context, message: 'Erro ao abrir o link');
                        });
                      },
                      child: TebText(
                        'Mais detalhes',
                        textStyle: FontStyle.italic,
                        textColor: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
          ),

          // vote data
          if (((widget.user.creator || widget.user.isSpectator) && widget.storyVotesList.isNotEmpty) ||
              (widget.user.isPlayer && widget.votingStory.status == StoryStatus.votingFinished))
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: votesAvarege.round() == 0
                        ? const Icon(Icons.coffee_outlined, size: 40)
                        : TebText(
                            '${votesAvarege.round()}',
                            textStyle: Theme.of(context).textTheme.headlineLarge!.fontStyle,
                            textWeight: Theme.of(context).textTheme.headlineLarge!.fontWeight,
                            textSize: Theme.of(context).textTheme.headlineLarge!.fontSize,
                            textColor: Theme.of(context).textTheme.headlineLarge!.color,
                            textAlign: TextAlign.center,
                          ),
                    title: TebText(votesAvarege.round() == 0
                        ? 'Um café'
                        : 'Média dos votos: ${votesAvarege.round()} (${votesAvarege.toStringAsPrecision(2)})'),
                    subtitle: TebText(votesAvarege.round() == 0 ? '' : 'Menor Voto: $minVote / Maior Voto $maxVote'),
                  ),
                ),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _setStoryPoints(points: votesAvarege.round()),
                      icon: const Icon(Icons.close_outlined),
                      label: const TebText(
                        'Registrar pontuação e\nfinalizar votação',
                        padding: EdgeInsets.symmetric(vertical: 5),
                      ),
                    ),
                  ],
                )
              ],
            ),
        ],
      ),
    );
  }
}
