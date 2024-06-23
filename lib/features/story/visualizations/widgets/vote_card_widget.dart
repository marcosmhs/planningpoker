import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/consts.dart';
import 'package:planningpoker/features/story/models/story.dart';
import 'package:planningpoker/features/story/models/story_vote.dart';
import 'package:planningpoker/features/story/story_controller.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:teb_package/messaging/teb_custom_dialog.dart';
import 'package:teb_package/visual_elements/teb_text.dart';

class VoteCard extends StatefulWidget {
  final BuildContext context;
  final User user;
  final String name;
  final int vote;
  final Story story;
  final bool enhance;

  const VoteCard({
    super.key,
    required this.user,
    required this.context,
    required this.name,
    required this.vote,
    required this.story,
    this.enhance = false,
  });

  @override
  State<VoteCard> createState() => _VoteCardState();

  static Widget listCardsForVote({
    required BuildContext context,
    required User user,
    required Story votingStory,
    required StoryVote storyVote,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      height: MediaQuery.of(context).size.height * (kIsWeb ? 0.70 : 0.68),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          mainAxisExtent: 200,
          childAspectRatio: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: Consts.pokerCardsValues.length,
        itemBuilder: (BuildContext ctx, index) {
          return VoteCard(
              context: context,
              user: user,
              name: Consts.pokerCardsValues[index].values.first,
              vote: Consts.pokerCardsValues[index].keys.first,
              story: votingStory,
              enhance: storyVote.id.isEmpty ? false : storyVote.points == Consts.pokerCardsValues[index].keys.first);
        },
      ),
    );
  }

  static Widget castedVotesList({
    required BuildContext context,
    required User user,
    required List<StoryVote> storyVotes,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      height: MediaQuery.of(context).size.height * 0.58,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          mainAxisExtent: 200,
          childAspectRatio: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: storyVotes.length,
        itemBuilder: (BuildContext ctx, index) {
          return VoteCard(
            context: context,
            user: user,
            name: storyVotes[index].userName,
            vote: storyVotes[index].points,
            story: Story(),
          );
        },
      ),
    );
  }
}

class _VoteCardState extends State<VoteCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.inverseSurface, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: widget.enhance ? Theme.of(context).primaryColorLight : Theme.of(context).cardColor,
      ),
      child: ClipOval(
        child: InkWell(
          onTap: () async {
            if (widget.story.id.isEmpty) return;
            var oldVote = await StoryController().getUserVote(
              story: widget.story,
              user: widget.user,
            );

            var message = oldVote.id.isEmpty
                ? 'Confirma o voto ${widget.vote == 0 ? 'um café' : widget.vote}?'
                : 'Trocar o voto de: ${oldVote.points == 0 ? 'um café' : oldVote.points} por ${widget.vote == 0 ? 'um café' : widget.vote}?';

            // ignore: use_build_context_synchronously
            TebCustomDialog(context: context).confirmationDialog(message: message).then((response) {
              if (response == true) {
                StoryController().vote(
                  storyVote: StoryVote(points: widget.vote, storyId: widget.story.id),
                  user: widget.user,
                  oldStoryVote: oldVote,
                );
              }
            });
          },
          splashColor: Theme.of(context).primaryColor,
          child: Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ListTile(
                  title: TebText(
                    widget.name,
                    textAlign: TextAlign.center,
                    textStyle: Theme.of(context).textTheme.labelLarge!.fontStyle,
                    textColor: Theme.of(context).textTheme.labelLarge!.color,
                    textSize: Theme.of(context).textTheme.labelLarge!.fontSize,
                  ),
                ),
                const SizedBox(height: 10),
                widget.vote == 0
                    ? const Icon(Icons.coffee_outlined, size: 60)
                    : Text(
                        widget.vote.toString(),
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
