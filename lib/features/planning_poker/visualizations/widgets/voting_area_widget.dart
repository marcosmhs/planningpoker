import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/consts.dart';
import 'package:planningpoker/features/planning_poker/visualizations/widgets/voting_info.dart';
import 'package:planningpoker/features/planning_data/models/planning_poker.dart';
import 'package:planningpoker/features/story/models/story.dart';
import 'package:planningpoker/features/story/models/story_vote.dart';
import 'package:planningpoker/features/story/story_controller.dart';
import 'package:planningpoker/features/story/visualizations/widgets/vote_card_widget.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:planningpoker/features/user/user_controller.dart';
import 'package:teb_package/visual_elements/teb_text.dart';

class VotingAreaWidget extends StatefulWidget {
  final PlanningData planningData;
  final User user;
  const VotingAreaWidget({super.key, required this.planningData, required this.user});

  @override
  State<VotingAreaWidget> createState() => _VotingAreaWidgetState();
}

class _VotingAreaWidgetState extends State<VotingAreaWidget> {
  List<Story> storiesList = [];

  Widget get _waitForVotingMessage {
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

  Widget _votingArea(
    Story storyVoting,
    Size size,
    List<StoryVote> storyVotesList,
    BuildContext context,
    StoryVote userStoryVote,
  ) {
    return Column(
      children: [
        // Voting statistics
        if ((widget.user.creator || widget.user.isSpectator) ||
            (widget.user.isPlayer && storyVoting.status == StoryStatus.votingFinished))
          VontingInfo(
            size: size,
            user: widget.user,
            storyVotesList: storyVotesList,
            votingStory: storyVoting,
            planningData: widget.planningData,
          ),

        // Votes
        // for players: when the voting session is finished
        // for spectators: all the time
        if ((widget.user.creator || widget.user.isSpectator) ||
            (widget.user.isPlayer && storyVoting.status == StoryStatus.votingFinished))
          VoteCard.castedVotesList(
            context: context,
            user: widget.user,
            planningData: widget.planningData,
            storyVotes: storyVotesList,
          ),

        // Cards for vote (only for players when there is a story to vote)
        if (!widget.user.creator && widget.user.isPlayer && storyVoting.id.isNotEmpty && storyVoting.status == StoryStatus.voting)
          VoteCard.listCardsForVote(
            context: context,
            user: widget.user,
            votingStory: StoryController().getVotingStory(storiesList),
            planningData: widget.planningData,
            storyVote: userStoryVote,
          ),
      ],
    );
  }

  Widget _usersArea(List<StoryVote> storyVotesList) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      width: Consts.usersArea,
      child: StreamBuilder<QuerySnapshot>(
        stream: UserController().getUserListData(planningId: widget.planningData.id),
        builder: (context, snapshot) {
          List<User> users = [];
          if (snapshot.hasData) {
            users = snapshot.data!.docs.map((e) => User.fromDocument(e)).toList();
          }

          var players = users.where((u) => u.isPlayer).toList();
          var spectators = users.where((u) => u.isSpectator).toList();

          players.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          spectators.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          return SingleChildScrollView(
            child: Column(
              children: [
                const TebText(
                  'Jogadores',
                  textWeight: FontWeight.w600,
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
                ListView.builder(
                  itemCount: players.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        dense: true,
                        title: TebText(
                          players[index].name,
                          textSize: 15,
                          textWeight: players[index].id == widget.user.id ? FontWeight.bold : null,
                        ),
                        trailing: storyVotesList.where((v) => v.userId == players[index].id).isNotEmpty
                            ? Icon(Icons.back_hand, color: Theme.of(context).primaryColorLight)
                            : null,
                      ),
                    );
                  },
                ),
                const TebText(
                  'Criadores de Histórias/\nEspectadores',
                  textWeight: FontWeight.w600,
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
                ListView.builder(
                  itemCount: spectators.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        dense: true,
                        title: TebText(
                          spectators[index].name,
                          textSize: 15,
                          textWeight: spectators[index].id == widget.user.id ? FontWeight.bold : null,
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return StreamBuilder<QuerySnapshot>(
      stream: StoryController().getStories(planningPokerId: widget.planningData.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Ocorreu um erro na consulta dos dados');
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          storiesList = snapshot.data!.docs.map((e) => Story.fromDocument(e)).toList();
          storiesList.sort(
            (a, b) => ((a.status == StoryStatus.voting) == (b.status == StoryStatus.voting)
                ? 0
                : ((a.status == StoryStatus.voting) ? -1 : 1)),
          );
        }

        var storyVoting = StoryController().getVotingStory(storiesList);

        if (storyVoting.id.isEmpty) {
          storyVoting = StoryController().getVotingFinishedStory(storiesList);
        }

        return storyVoting.id.isEmpty
            ? Row(
                children: [
                  // votes
                  Container(
                    width: size.width - Consts.storiesAreaWidth - Consts.usersArea,
                    padding: const EdgeInsets.only(left: 20),
                    child: _waitForVotingMessage,
                  ),
                  const Spacer(),
                  // planning users
                  _usersArea([])
                ],
              )
            : StreamBuilder<QuerySnapshot>(
                stream: StoryController().getStoryVotes(
                  story: storyVoting,
                  planningId: widget.planningData.id,
                ),
                builder: (context, snapshot) {
                  List<StoryVote> storyVotesList = [];
                  if (snapshot.hasData) {
                    storyVotesList = snapshot.data!.docs.map((e) => StoryVote.fromDocument(e)).toList();
                    storyVotesList.sort((a, b) => a.userName.compareTo(b.userName));
                  }

                  var userStoryVote = storyVotesList.where((vote) => vote.userId == widget.user.id).firstOrNull ?? StoryVote();

                  return Row(
                    children: [
                      // votes
                      Container(
                        width: size.width - Consts.storiesAreaWidth - Consts.usersArea,
                        padding: const EdgeInsets.only(left: 20),
                        child: _votingArea(storyVoting, size, storyVotesList, context, userStoryVote),
                      ),

                      const Spacer(),

                      // planning users
                      _usersArea(storyVotesList)
                    ],
                  );
                },
              );
      },
    );
  }
}
