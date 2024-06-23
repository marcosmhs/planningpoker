import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/consts.dart';
import 'package:planningpoker/features/planning_data/models/planning_poker.dart';
import 'package:planningpoker/features/story/models/story.dart';
import 'package:planningpoker/features/story/story_controller.dart';
import 'package:planningpoker/features/story/visualizations/widgets/story_card_widget.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:teb_package/visual_elements/teb_text.dart';

class StoriesAreaWidget extends StatefulWidget {
  final PlanningData planningData;
  final User user;
  const StoriesAreaWidget({super.key, required this.planningData, required this.user});

  @override
  State<StoriesAreaWidget> createState() => _StoriesAreaWidgetState();
}

class _StoriesAreaWidgetState extends State<StoriesAreaWidget> {
  List<Story> storiesList = [];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Story>>(
      future: StoryController().getInitialStories(widget.planningData.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Ocorreu um erro na consulta');
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          var initialStoriesList = snapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: StoryController().getStories(planningPokerId: widget.planningData.id),
            builder: (context, streamSnapshot) {
              if (streamSnapshot.hasError) {
                return const Text('Ocorreu um erro na consulta');
              } else if (streamSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              storiesList = initialStoriesList;

              if (streamSnapshot.hasData) {
                storiesList = streamSnapshot.data!.docs.map((e) => Story.fromDocument(e)).toList();
                storiesList.sort((a, b) => a.order.compareTo(b.order));
                storiesList.sort((a, b) => a.storyStatusIndex.compareTo(b.storyStatusIndex));
              }

              var storyStatusLabel = '';
              var printLabel = false;

              return Column(
                children: [
                  if (widget.user.creator)
                    StoryCard.newCard(context: context, planningData: widget.planningData, user: widget.user),
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

                        var storyVoting = StoryController().getVotingStory(storiesList);
                        if (storyVoting.id.isEmpty) {
                          storyVoting = StoryController().getVotingFinishedStory(storiesList);
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
                              votingStory: storyVoting,
                              //clearVotingStory: () => _getVotingStory.clear(),
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
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
