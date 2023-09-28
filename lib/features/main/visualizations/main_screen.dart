import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/components/messaging/custom_dialog.dart';
import 'package:planningpoker/components/messaging/custom_message.dart';
import 'package:planningpoker/components/screen_elements/custom_scaffold.dart';
import 'package:planningpoker/components/util/custom_return.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/planning_poker/planning_controller.dart';
import 'package:planningpoker/features/planning_poker/planning_poker.dart';
import 'package:planningpoker/features/story/story.dart';
import 'package:planningpoker/features/story/story_controller.dart';
import 'package:planningpoker/features/story/story_vote.dart';
import 'package:planningpoker/features/user/user.dart';
import 'package:planningpoker/features/user/user_controller.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreen();
}

class _MainScreen extends State<MainScreen> with TickerProviderStateMixin {
  var _planningData = PlanningData();
  var _storyCardHeight = 130.0;
  final _storyCardWidht = 120.0;

  final List<Map<int, String>> avaliablesCards = [
    {0: 'Um café'},
    {1: 'Um'},
    {2: 'Dois'},
    {5: 'Cinco'},
    {8: 'Oito'},
    {13: 'Treze'},
    {21: 'Vinte e um'},
    {40: 'Quarenta'},
    {100: 'Cem'},
  ];
  @override
  void initState() {
    super.initState();
  }

  Future<void> _showStoryOptions({required BuildContext context, required Story story}) async {
    if (!Provider.of<UserController>(context, listen: false).currentUser.creator) return;
    await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          scrollable: true,
          title: const Text('O que deseja fazer?'),
          titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
          content: StatefulBuilder(
            builder: (BuildContext ctx2, StateSetter setState) {
              return Column(
                children: [
                  // edit
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints.tightFor(height: 45, width: MediaQuery.of(ctx).size.width * 0.70),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pushNamed(Routes.storyForm, arguments: {'story': story});
                        },
                        label: const Text('Editar'),
                        icon: const Icon(Icons.edit),
                      ),
                    ),
                  ),
                  // set to vote
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints.tightFor(height: 45, width: MediaQuery.of(ctx).size.width * 0.70),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (story.status == StoryStatus.voting || story.status == StoryStatus.votingFinished) {
                            (CustomDialog(context: context).customdialog(
                              message: 'Esta história já está em votacão, deseja cancelar a votação dela?',
                              yesButtonText: 'Sim',
                              noButtonText: 'Não',
                              icon: const Icon(Icons.question_mark, size: 50),
                            )).then((dialogReturn) {
                              if (dialogReturn == true) {
                                story.status = StoryStatus.created;
                                Provider.of<StoryController>(context, listen: false).save(story: story).then((customReturn) {
                                  if (customReturn.returnType == ReturnType.error) {
                                    // ignore: use_build_context_synchronously
                                    CustomMessage.error(context, message: customReturn.message);
                                  } else {
                                    Navigator.of(ctx).pop();
                                  }
                                });
                              }
                            });
                          } else {
                            var customReturn = await Provider.of<StoryController>(context, listen: false).setStoryToVote(
                              story: story,
                            );
                            if (customReturn.returnType == ReturnType.error) {
                              // ignore: use_build_context_synchronously
                              CustomMessage.error(context, message: customReturn.message);
                            }
                          }
                        },
                        label: const Text('Iniciar Votação'),
                        icon: const Icon(Icons.send_to_mobile_rounded),
                      ),
                    ),
                  ),
                  // cancel vote
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints.tightFor(height: 45, width: MediaQuery.of(ctx).size.width * 0.70),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (story.status == StoryStatus.voting || story.status == StoryStatus.votingFinished) {
                            (CustomDialog(context: context).customdialog(
                              message: 'Confirma a finalização da votação? Após isso ninguém mais poderá lançar seus votos?',
                              yesButtonText: 'Sim',
                              noButtonText: 'Não',
                              icon: const Icon(Icons.question_mark, size: 50),
                            )).then((dialogReturn) {
                              if (dialogReturn == true) {
                                story.status = StoryStatus.votingFinished;
                                Provider.of<StoryController>(context, listen: false).save(story: story).then((customReturn) {
                                  if (customReturn.returnType == ReturnType.error) {
                                    // ignore: use_build_context_synchronously
                                    CustomMessage.error(context, message: customReturn.message);
                                  } else {
                                    Navigator.of(ctx).pop();
                                  }
                                });
                              }
                            });
                          } else {
                            var customReturn = await Provider.of<StoryController>(context, listen: false).setStoryToVote(
                              story: story,
                            );
                            if (customReturn.returnType == ReturnType.error) {
                              // ignore: use_build_context_synchronously
                              CustomMessage.error(context, message: customReturn.message);
                            }
                          }
                        },
                        label: const Text('Finalizar Votação'),
                        icon: const Icon(Icons.close_outlined),
                      ),
                    ),
                  ),
                  // delete
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints.tightFor(height: 45, width: MediaQuery.of(ctx).size.width * 0.70),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () async {
                          (CustomDialog(context: context).customdialog(
                            message: 'Deseja realmente excluir esta história?',
                            yesButtonText: 'Sim',
                            noButtonText: 'Não',
                            icon: const Icon(Icons.question_mark, size: 50),
                          )).then((dialogReturn) {
                            if (dialogReturn == true) {
                              Provider.of<StoryController>(context, listen: false).delete(story: story);
                            }
                            Navigator.of(context).pop();
                          });
                        },
                        label: const Text('Excluir'),
                        icon: const Icon(Icons.delete),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _newStory({required BuildContext context}) {
    return Card(
      child: SizedBox(
        height: _storyCardHeight,
        width: _storyCardWidht - 20,
        child: ClipOval(
          child: InkWell(
            splashColor: Theme.of(context).primaryColor,
            onTap: () => Navigator.of(context).pushNamed(Routes.storyForm),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("Nova história"),
                Icon(Icons.add, size: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _story({required BuildContext context, required Story story}) {
    return GestureDetector(
      onTap: () async {
        _showStoryOptions(context: context, story: story);
      },
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Card(
          color: story.status == StoryStatus.voting || story.status == StoryStatus.votingFinished
              ? Theme.of(context).primaryColorLight
              : Theme.of(context).cardColor,
          child: SizedBox(
            height: _storyCardHeight,
            width: _storyCardWidht,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // name
                Padding(
                  padding: const EdgeInsets.only(left: 5, top: 10, bottom: 5),
                  child: Text(
                    story.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                // description
                Padding(
                  padding: const EdgeInsets.only(left: 5, top: 5, bottom: 5),
                  child: Text(
                    story.description.length > 50 ? '${story.description.substring(1, 50)}...' : story.description,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                const Spacer(),
                //// url
                //Padding(
                //  padding: const EdgeInsets.all(8.0),
                //  child: GestureDetector(
                //    onTap: () async {
                //      try {
                //        if (!await launchUrl(Uri.parse(story.url))) {
                //          // ignore: use_build_context_synchronously
                //          CustomMessage.error(context, message: 'Não foi possível abrir o link: ${story.url}');
                //        }
                //      } catch (e) {
                //        // ignore: use_build_context_synchronously
                //        CustomMessage.error(context, message: e.toString());
                //      }
                //    },
                //    child: Text(
                //      'Mais detalhes',
                //      style: TextStyle(color: Theme.of(context).primaryColor),
                //    ),
                //  ),
                //),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _voteCard({
    required BuildContext context,
    required String name,
    required int vote,
    required Story story,
    bool enhance = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: enhance ? Theme.of(context).primaryColorLight : Theme.of(context).cardColor,
      ),
      child: ClipOval(
        child: InkWell(
          onTap: () {
            if (story.id.isEmpty) return;

            CustomDialog(context: context)
                .confirmationDialog(message: 'Confirma o voto ${vote == 0 ? 'um café' : vote}?')
                .then((response) {
              if (response == true) {
                Provider.of<StoryController>(context, listen: false).vote(
                  storyVote: StoryVote(
                    points: vote,
                    storyId: story.id,
                  ),
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
                Text(
                  name,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 10),
                vote == 0
                    ? const Icon(Icons.coffee_outlined, size: 60)
                    : Text(
                        vote.toString(),
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardsForVote({required BuildContext context, required Story votingStory, required StoryVote storyVote}) {
    return Container(
      padding: const EdgeInsets.all(8),
      height: Provider.of<UserController>(context, listen: false).currentUser.creator
          ? MediaQuery.of(context).size.height * 0.50
          : MediaQuery.of(context).size.height * 0.68,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          mainAxisExtent: 200,
          childAspectRatio: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: avaliablesCards.length,
        itemBuilder: (BuildContext ctx, index) {
          return _voteCard(
              context: context,
              name: avaliablesCards[index].values.first,
              vote: avaliablesCards[index].keys.first,
              story: votingStory,
              enhance: storyVote.id.isEmpty ? false : storyVote.points == avaliablesCards[index].keys.first);
        },
      ),
    );
  }

  Widget _castedVotes({required BuildContext context, required List<StoryVote> storyVotes}) {
    return Container(
      color: Colors.amberAccent,
      padding: const EdgeInsets.all(8),
      height: Provider.of<UserController>(context, listen: false).currentUser.creator
          ? MediaQuery.of(context).size.height * 0.58
          : MediaQuery.of(context).size.height * 0.68,
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
          return _voteCard(
            context: context,
            name: storyVotes[index].userName,
            vote: storyVotes[index].points,
            story: Story(),
          );
        },
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    _storyCardHeight = MediaQuery.of(context).size.height * 0.19;

    var user = Provider.of<UserController>(context, listen: false).currentUser;
    return StreamBuilder(
      stream: Provider.of<PlanningPokerController>(context, listen: false).getPlanningData,
      builder: (context, snapshot) {
        if (!snapshot.hasData) const Text('Parece que houve um erro, pois não há dados da planning e você está nesta tela');
        if (snapshot.hasData) _planningData = PlanningData.fromDocument(snapshot.data!);
        return CustomScaffold(
          // appbar
          appBar: AppBar(
            title: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(Routes.planningDataForm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_planningData.name),
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.labelLarge!.fontSize,
                      color: Theme.of(context).cardColor,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                  onPressed: () {
                    var user = Provider.of<UserController>(context, listen: false).currentUser;
                    user.creator = !user.creator;
                    Provider.of<UserController>(context, listen: false).save(user: user);
                  },
                  icon: const Icon(Icons.person_add)),
              IconButton(
                  onPressed: () {
                    Provider.of<PlanningPokerController>(context, listen: false).clearCurrentPlanning();
                    Provider.of<UserController>(context, listen: false).clearCurrentUser();
                    Navigator.of(context).popAndPushNamed(Routes.landingScreen);
                  },
                  icon: const Icon(Icons.exit_to_app))
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: Provider.of<StoryController>(context, listen: false).getStories,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Ocorreu um erro na consulta da escala');
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              List<Story> stories = [];
              if (snapshot.hasData) {
                stories = snapshot.data!.docs.map((e) => Story.fromDocument(e)).toList();
              }
              var votingStory = stories
                      .where((story) => story.status == StoryStatus.voting || story.status == StoryStatus.votingFinished)
                      .firstOrNull ??
                  Story();
              //stories.sort(
              //  (a, b) => (a.voting == b.voting ? 0 : (a.voting ? -1 : 1)),
              //);

              var currentUser = Provider.of<UserController>(context, listen: false).currentUser;

              if (stories.isEmpty) {
                return _newStory(context: context);
              } else {
                return Column(
                  children: [
                    // check if there is a story to be voted.
                    votingStory.id.isEmpty
                        // if not, display wait message
                        ? _waitForVotingMessage()
                        // else show de cards for players or the votes for the creator of the planning
                        : StreamBuilder<QuerySnapshot>(
                            stream: Provider.of<StoryController>(context, listen: false).getStoryVotes(story: votingStory),
                            builder: (context, snapshot) {
                              List<StoryVote> storyVotes = [];
                              if (snapshot.hasData) {
                                storyVotes = snapshot.data!.docs.map((e) => StoryVote.fromDocument(e)).toList();
                              }

                              var storyVote =
                                  storyVotes.where((vote) => vote.userid == currentUser.id).firstOrNull ?? StoryVote();

                              var votesPoints = storyVotes.map((e) => e.points).toList();
                              var votesPointsTotal = votesPoints.fold(0, (p, c) => p + c);
                              var votesAvarege = 0.0;
                              votesPoints.reduce(min);
                              if (votesPointsTotal > 0) {
                                votesAvarege = votesPointsTotal / votesPoints.length;
                              }

                              return Column(
                                children: [
                                  // Stories
                                  SizedBox(
                                    height: _storyCardHeight + 5,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: stories.length,
                                      itemBuilder: (context, index) {
                                        return index == 0
                                            ? Row(
                                                children: [
                                                  _newStory(context: context),
                                                  _story(context: context, story: stories[index]),
                                                ],
                                              )
                                            : _story(context: context, story: stories[index]);
                                      },
                                    ),
                                  ),
                                  // voite data
                                  if (currentUser.creator && storyVotes.isNotEmpty)
                                    ListTile(
                                      leading: Text(
                                        'Z',
                                        style: Theme.of(context).textTheme.headlineLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                      title: Text('Média dos voto: ${votesAvarege.round()} ($votesAvarege)'),
                                      subtitle:
                                          Text('Menor Voto: ${votesPoints.reduce(min)} / Maior Voto ${votesPoints.reduce(max)}'),
                                    ),
                                  if (currentUser.creator || currentUser.role == Role.spectator)
                                    _castedVotes(context: context, storyVotes: storyVotes),

                                  if (!currentUser.creator)
                                    _cardsForVote(
                                      context: context,
                                      votingStory: votingStory,
                                      storyVote: storyVote,
                                    )
                                ],
                              );
                            },
                          ),
                    // Cards for voting
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
