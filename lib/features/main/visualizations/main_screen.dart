// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planningpoker/consts.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/main/visualizations/about_dialog_button.dart';
import 'package:planningpoker/features/main/visualizations/botton_info.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/planning_poker/planning_controller.dart';
import 'package:planningpoker/features/story/models/story.dart';
import 'package:planningpoker/features/story/visualizations/story_card_widget.dart';
import 'package:planningpoker/features/story/story_controller.dart';
import 'package:planningpoker/features/story/models/story_vote.dart';
import 'package:planningpoker/features/story/visualizations/vote_card_widget.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:planningpoker/features/user/user_controller.dart';
import 'package:provider/provider.dart';
import 'package:teb_package/messaging/teb_custom_dialog.dart';
import 'package:teb_package/messaging/teb_custom_message.dart';
import 'package:teb_package/screen_elements/teb_custom_scaffold.dart';

// ignore: must_be_immutable
class MainScreen extends StatefulWidget {
  final User? user;
  final PlanningData? planningData;

  const MainScreen({
    super.key,
    this.user,
    this.planningData,
  });

  @override
  State<MainScreen> createState() => _MainScreen();
}

class _MainScreen extends State<MainScreen> with TickerProviderStateMixin {
  var _user = User();
  var _planningData = PlanningData();
  var _votingStory = Story();

  Widget _waitForVotingMessage() {
    return Column(
      children: [
        const SizedBox(height: 50),
        Text(
          'Aguarde o início da votação',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Icon(Icons.timer, size: 150, color: Theme.of(context).primaryColorLight)
      ],
    );
  }

  Widget _screenTitle(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Planning data
            Row(
              children: [
                // name
                Text(_planningData.name),
                const SizedBox(width: 10),
                // edit link
                if (_user.creator)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed(
                      Routes.planningDataForm,
                      arguments: {'planningData': _planningData, 'user': _user},
                    ),
                    child: const Icon(Icons.edit, size: 20),
                  ),
              ],
            ),
            // user info
            Text(
              _user.name,
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.labelLarge!.fontSize,
                color: Theme.of(context).cardColor,
              ),
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
                  _planningData.invitationCode,
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
              ClipboardData(text: _planningData.invitationCode),
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

  void _confirmPlanningExit() {
    TebCustomDialog(context: context)
        .confirmationDialog(
            message: 'Tem certeza que deseja abandona a partida?\n\nIsso fará com que seu acesso seja removido permanentemente.')
        .then((response) {
      if (response == true) {
        Provider.of<PlanningPokerController>(context, listen: false).clearCurrentPlanning();
        Provider.of<UserController>(context, listen: false).clearCurrentUser();
        Navigator.of(context).popAndPushNamed(Routes.landingScreen);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final arguments = (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{}) as Map;
    _user = arguments['user'] ?? User();
    _planningData = arguments['planningData'] ?? PlanningData();

    if (widget.user != null && widget.user!.id.isNotEmpty) _user = widget.user!;
    if (widget.planningData != null && widget.planningData!.id.isNotEmpty) _planningData = widget.planningData!;

    Consts.storyCardHeight = MediaQuery.of(context).size.height * 0.19;

    if (_user.id.isEmpty) return const Text('');
    if (_planningData.id.isEmpty) return const Text('');

    return StreamBuilder(
      stream: Provider.of<PlanningPokerController>(context, listen: false).getPlanningData(planningId: _planningData.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const TebCustomScaffold(
            body: Center(child: Text('Parece que houve um erro, pois não há dados da planning e você está nesta tela')),
            bottomNavigationBar: BottonInfo(),
          );
        }

        if (snapshot.hasData) _planningData = PlanningData.fromDocument(snapshot.data!);

        return TebCustomScaffold(
          // appbar
          appBar: AppBar(
            title: _screenTitle(context),
            actions: [
              const AboutDialogButton(),
              IconButton(
                onPressed: () => _confirmPlanningExit(),
                icon: const Icon(Icons.exit_to_app),
              )
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: Provider.of<StoryController>(context, listen: false).getStories(planningPokerId: _planningData.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Ocorreu um erro na consulta da escala');
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              List<Story> stories = [];
              if (snapshot.hasData) {
                stories = snapshot.data!.docs.map((e) => Story.fromDocument(e)).toList();
                stories.sort(
                  (a, b) => ((a.status == StoryStatus.voting) == (b.status == StoryStatus.voting)
                      ? 0
                      : ((a.status == StoryStatus.voting) ? -1 : 1)),
                );
              }
              _votingStory = stories
                      .where((story) => story.status == StoryStatus.voting || story.status == StoryStatus.votingFinished)
                      .firstOrNull ??
                  Story();

              if (stories.isEmpty) {
                if (_user.creator) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StoryCard.newCard(
                          size: Size(Consts.storyCardWidth - 20, Consts.storyCardHeight),
                          context: context,
                          planningData: _planningData,
                          user: _user),
                    ],
                  );
                } else {
                  return const Text('');
                }
              } else {
                return Column(
                  children: [
                    // Stories
                    SizedBox(
                      height: Consts.storyCardHeight + 5,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: stories.length,
                        itemBuilder: (context, index) {
                          var storyCard = StoryCard(
                            user: _user,
                            planningData: _planningData,
                            story: stories[index],
                            votingStory: _votingStory,
                            clearVotingStory: () => _votingStory.clear(),
                            size: Size(Consts.storyCardWidth, Consts.storyCardHeight),
                          );
                          if (_user.creator) {
                            return index == 0
                                ? Row(
                                    children: [
                                      StoryCard.newCard(
                                          size: Size(Consts.storyCardWidth - 20, Consts.storyCardHeight),
                                          context: context,
                                          planningData: _planningData,
                                          user: _user),
                                      storyCard,
                                    ],
                                  )
                                : storyCard;
                          } else {
                            return storyCard;
                          }
                        },
                      ),
                    ),
                    _votingStory.id.isEmpty
                        ? _waitForVotingMessage()
                        : StreamBuilder<QuerySnapshot>(
                            stream: Provider.of<StoryController>(context, listen: false).getStoryVotes(
                              story: _votingStory,
                              planningId: _planningData.id,
                            ),
                            builder: (context, snapshot) {
                              List<StoryVote> storyVotes = [];
                              if (snapshot.hasData) {
                                storyVotes = snapshot.data!.docs.map((e) => StoryVote.fromDocument(e)).toList();
                              }

                              var storyVote = storyVotes.where((vote) => vote.userId == _user.id).firstOrNull ?? StoryVote();

                              var votesAvarege = 0.0;
                              var minVote = 0;
                              var maxVote = 0;

                              if (storyVotes.isNotEmpty) {
                                var votesPoints = storyVotes.map((e) => e.points).toList();
                                var votesPointsTotal = votesPoints.fold(0, (p, c) => p + c);
                                votesAvarege = votesPointsTotal / votesPoints.length;
                                minVote = votesPoints.reduce(min);
                                maxVote = votesPoints.reduce(max);
                              }

                              return Column(
                                children: [
                                  // vote data
                                  if (((_user.creator || _user.isSpectator) && storyVotes.isNotEmpty) ||
                                      (_user.isPlayer && _votingStory.status == StoryStatus.votingFinished))
                                    ListTile(
                                      leading: Text(
                                        '${votesAvarege.round()}',
                                        style: Theme.of(context).textTheme.headlineLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                      title: Text('Média dos votos: ${votesAvarege.round()} ($votesAvarege)'),
                                      subtitle: Text('Menor Voto: $minVote / Maior Voto $maxVote'),
                                    ),

                                  if ((_user.creator || _user.isSpectator) ||
                                      (_user.isPlayer && _votingStory.status == StoryStatus.votingFinished))
                                    VoteCard.castedVotesList(context: context, user: _user, storyVotes: storyVotes),

                                  if (!_user.creator &&
                                      _user.isPlayer &&
                                      _votingStory.id.isNotEmpty &&
                                      _votingStory.status != StoryStatus.votingFinished)
                                    VoteCard.listCardsForVote(
                                      context: context,
                                      user: _user,
                                      votingStory: _votingStory,
                                      storyVote: storyVote,
                                    )
                                ],
                              );
                            },
                          ),
                  ],
                );
              }
            },
          ),
        );
      },
    );
  }
}
