import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/consts.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/story/models/story.dart';
import 'package:planningpoker/features/story/story_controller.dart';
import 'package:planningpoker/features/story/visualizations/story_card_widget.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:teb_package/visual_elements/teb_text.dart';

class StoriesArea extends StatefulWidget {
  final PlanningData planningData;
  final User user;
  const StoriesArea({super.key, required this.planningData, required this.user});

  @override
  State<StoriesArea> createState() => _StoriesAreaState();
}

class _StoriesAreaState extends State<StoriesArea> {
  List<Story> storiesList = [];

  Story get _getVotingStory {
    var l = storiesList.where((s) => s.status == StoryStatus.voting).toList();
    if (l.isEmpty) return Story();
    return l.first;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: StoryController().getStories(planningPokerId: widget.planningData.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Ocorreu um erro na consulta da escala');
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          storiesList = snapshot.data!.docs.map((e) => Story.fromDocument(e)).toList();
          storiesList.sort((a, b) => a.storyStatusOrder.compareTo(b.storyStatusOrder));
        }

        var storyStatusLabel = '';
        var printLabel = false;

        return Column(
          children: [
            if (widget.user.creator)
              StoryCard.newCard(
                  context: context,
                  planningData: widget.planningData,
                  user: widget.user),
            Expanded(
              child: ListView.builder(
                itemCount: storiesList.length,
                itemBuilder: (ctx, index) {
                  if (storyStatusLabel != storiesList[index].statusLabel) {
                    printLabel = true;
                    storyStatusLabel = storiesList[index].statusLabel;
                  } else {
                    printLabel = false;
                  }
                  return Column(
                    children: [
                      if (printLabel)
                        TebText(
                          storyStatusLabel,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textWeight: FontWeight.bold,
                        ),
                      StoryCard(
                        user: widget.user,
                        planningData: widget.planningData,
                        story: storiesList[index],
                        votingStory: _getVotingStory,
                        clearVotingStory: () => _getVotingStory.clear(),
                        size: Size(Consts.storyCardWidth, Consts.storyCardHeight),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
