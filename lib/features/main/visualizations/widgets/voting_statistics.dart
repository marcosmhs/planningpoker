import 'dart:math';

import 'package:flutter/material.dart';
import 'package:planningpoker/features/story/models/story.dart';
import 'package:planningpoker/features/story/models/story_vote.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:teb_package/messaging/teb_custom_message.dart';
import 'package:teb_package/util/teb_url_manager.dart';
import 'package:teb_package/visual_elements/teb_text.dart';

class VontingStatistics extends StatefulWidget {
  const VontingStatistics(
      {super.key, required this.size, required this.user, required this.storyVotesList, required this.votingStory});

  final Size size;
  final User user;
  final List<StoryVote> storyVotesList;
  final Story votingStory;

  @override
  State<VontingStatistics> createState() => _VontingStatisticsState();
}

class _VontingStatisticsState extends State<VontingStatistics> {
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
            ListTile(
              leading: TebText(
                '${votesAvarege.round()}',
                textStyle: Theme.of(context).textTheme.headlineLarge!.fontStyle,
                textWeight: Theme.of(context).textTheme.headlineLarge!.fontWeight,
                textSize: Theme.of(context).textTheme.headlineLarge!.fontSize,
                textColor: Theme.of(context).textTheme.headlineLarge!.color,
                textAlign: TextAlign.center,
              ),
              title: TebText('Média dos votos: ${votesAvarege.round()} ($votesAvarege)'),
              subtitle: TebText('Menor Voto: $minVote / Maior Voto $maxVote'),
            ),

          //if ((user.creator || user.isSpectator) || (user.isPlayer && votingStory.status == StoryStatus.votingFinished))
          //  VoteCard.castedVotesList(context: context, user: user, storyVotes: storyVotes),

          //if (!user.creator && user.isPlayer && votingStory.id.isNotEmpty && votingStory.status != StoryStatus.votingFinished)
          //  VoteCard.listCardsForVote(
          //    context: context,
          //    user: user,
          //    votingStory: votingStory,
          //    storyVote: storyVote,
          //  )
        ],
      ),
    );
  }
}
