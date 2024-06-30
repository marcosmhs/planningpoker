// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/planning_data/models/planning_poker.dart';
import 'package:planningpoker/features/story/models/story.dart';
import 'package:planningpoker/features/story/story_controller.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:teb_package/messaging/teb_custom_dialog.dart';
import 'package:teb_package/messaging/teb_custom_message.dart';
import 'package:teb_package/util/teb_return.dart';
import 'package:teb_package/util/teb_url_manager.dart';
import 'package:teb_package/visual_elements/teb_buttons_line.dart';
import 'package:teb_package/visual_elements/teb_text.dart';

class StoryCard extends StatefulWidget {
  final Size size;
  final PlanningData planningData;
  final Story story;
  final Story votingStory;
  final User user;
  // final void Function() clearVotingStory;
  const StoryCard({
    super.key,
    required this.user,
    required this.planningData,
    required this.story,
    required this.votingStory,
    required this.size,
    // required this.clearVotingStory,
  });

  @override
  State<StoryCard> createState() => _StoryCardState();

  static Widget newCard({
    required BuildContext context,
    //required Size size,
    required PlanningData planningData,
    required User user,
  }) {
    return TebButton(
      label: 'Nova História',
      icon: const Icon(Icons.add),
      padding: const EdgeInsets.symmetric(vertical: 20),
      onPressed: () => Navigator.of(context).pushNamed(
        Routes.storyForm,
        arguments: {'planningData': planningData, 'user': user},
      ),
    );
  }

  //@override
  //void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  //  super.debugFillProperties(properties);
  //  properties.add(ObjectFlagProperty<void Function()>.has('clearVotingStory', clearVotingStory));
  //}
}

class _StoryCardState extends State<StoryCard> {
  Widget _editStory({required BuildContext dialogContext, required Story story}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(height: 45, width: MediaQuery.of(dialogContext).size.width * 0.70),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(dialogContext).pushNamed(
              Routes.storyForm,
              arguments: {
                'story': story,
                'planningData': widget.planningData,
                'user': widget.user,
              },
            );
          },
          label: const Text('Editar'),
          icon: const Icon(Icons.edit),
        ),
      ),
    );
  }

  Widget _setStoryToVote({required BuildContext dialogContext, required Story story}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(height: 45, width: MediaQuery.of(dialogContext).size.width * 0.70),
        child: ElevatedButton.icon(
          onPressed: () async {
            if (widget.votingStory.id.isNotEmpty &&
                widget.votingStory.id != story.id &&
                (widget.votingStory.status == StoryStatus.voting || widget.votingStory.status == StoryStatus.votingFinished)) {
              TebCustomDialog(context: dialogContext)
                  .errorMessage(message: 'Já existe uma história em votação, é necssário concluí-la antes')
                  .then((value) => Navigator.of(dialogContext, rootNavigator: true).pop());
              return;
            }
            if (story.status == StoryStatus.voting) {
              (TebCustomDialog(context: dialogContext).customdialog(
                message: 'Esta história já está em votacão, deseja cancelar a votação dela?',
                yesButtonText: 'Sim',
                noButtonText: 'Não',
                icon: const Icon(Icons.question_mark, size: 50),
              )).then((dialogReturn) {
                if (dialogReturn == true) {
                  story.status = StoryStatus.created;
                  StoryController()
                      .save(story: story, user: User(), planningPokerId: widget.planningData.id)
                      .then((customReturn) {
                    if (customReturn.returnType == TebReturnType.error) {
                      TebCustomMessage.error(context, message: customReturn.message);
                    } else {
                      widget.votingStory.clear();
                      // widget.clearVotingStory();
                      Navigator.of(dialogContext, rootNavigator: true).pop();
                    }
                  });
                }
              });
            } else {
              var customReturn = await StoryController().setStoryToVote(
                story: story,
                planningPokerId: widget.planningData.id,
              );
              if (customReturn.returnType == TebReturnType.error) {
                TebCustomMessage.error(context, message: customReturn.message);
              } else {
                Navigator.of(dialogContext, rootNavigator: true).pop();
              }
            }
          },
          label: Text(
            widget.votingStory.id.isNotEmpty && widget.votingStory.id == story.id ? 'Cancelar Votação' : 'Iniciar Votação',
          ),
          icon: Icon(widget.votingStory.id.isNotEmpty && widget.votingStory.id == story.id
              ? Icons.cancel_outlined
              : Icons.send_to_mobile_rounded),
        ),
      ),
    );
  }

  Padding _finishStoryVote({required BuildContext dialogContext, required Story story}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(height: 45, width: MediaQuery.of(dialogContext).size.width * 0.70),
        child: ElevatedButton.icon(
          onPressed: () async {
            if (story.status == StoryStatus.voting) {
              (TebCustomDialog(context: dialogContext).customdialog(
                message: 'Finalização a votação?',
                yesButtonText: 'Sim',
                noButtonText: 'Não',
                icon: const Icon(Icons.question_mark, size: 50),
              )).then(
                (dialogReturn) {
                  if (dialogReturn == true) {
                    story.status = StoryStatus.votingFinished;
                    StoryController()
                        .save(story: story, user: User(), planningPokerId: widget.planningData.id)
                        .then((customReturn) {
                      if (customReturn.returnType == TebReturnType.error) {
                        TebCustomMessage.error(context, message: customReturn.message);
                      } else {
                        widget.votingStory.clear();
                        // widget.clearVotingStory();
                        Navigator.of(dialogContext).pop();
                      }
                    });
                  }
                },
              );
            } else {
              var customReturn = await StoryController().setStoryToVote(
                story: story,
                planningPokerId: widget.planningData.id,
              );
              if (customReturn.returnType == TebReturnType.error) {
                TebCustomMessage.error(context, message: customReturn.message);
              } else {
                widget.votingStory.clear();
                // widget.clearVotingStory();
              }
            }
          },
          label: const Text('Finalizar Votação'),
          icon: const Icon(Icons.close_outlined),
        ),
      ),
    );
  }

  Padding _closeStory({required BuildContext dialogContext, required Story story}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(height: 45, width: MediaQuery.of(dialogContext).size.width * 0.70),
        child: ElevatedButton.icon(
          onPressed: () async {
            if (story.status == StoryStatus.votingFinished) {
              (TebCustomDialog(context: dialogContext).customdialog(
                message: 'Concluir a história?',
                yesButtonText: 'Sim',
                noButtonText: 'Não',
                icon: const Icon(Icons.question_mark, size: 50),
              )).then(
                (dialogReturn) {
                  if (dialogReturn == true) {
                    story.status = StoryStatus.closed;
                    StoryController()
                        .save(story: story, user: User(), planningPokerId: widget.planningData.id)
                        .then((customReturn) {
                      if (customReturn.returnType == TebReturnType.error) {
                        TebCustomMessage.error(context, message: customReturn.message);
                      } else {
                        widget.votingStory.clear();
                        Navigator.of(dialogContext).pop();
                      }
                    });
                  }
                },
              );
            }
          },
          label: const Text('Concluir história'),
          icon: const Icon(Icons.door_sliding_sharp),
        ),
      ),
    );
  }

  Padding _reopenStory({required BuildContext dialogContext, required Story story}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(height: 45, width: MediaQuery.of(dialogContext).size.width * 0.70),
        child: ElevatedButton.icon(
          onPressed: () async {
            if (story.status == StoryStatus.closed) {
              TebCustomDialog(context: dialogContext)
                  .customdialog(
                message: 'Retornar história para aguardando votos?',
                yesButtonText: 'Sim',
                noButtonText: 'Não',
                icon: const Icon(Icons.question_mark, size: 50),
              )
                  .then(
                (dialogReturn) async {
                  if (dialogReturn == true) {
                    var removeCastedVotes = await TebCustomDialog(context: dialogContext).customdialog(
                          message: 'O que quer fazer com os votos já lançados',
                          yesButtonText: 'REMOVER e recomeçar do zero',
                          noButtonText: 'MANTER os votos e a pontuação',
                          icon: const Icon(Icons.question_mark, size: 50),
                        ) ??
                        false;

                    StoryController().reOpenStory(story: story, removeCastedVotes: removeCastedVotes).then((customReturn) {
                      if (customReturn.returnType == TebReturnType.error) {
                        TebCustomMessage.error(context, message: customReturn.message);
                      } else {
                        widget.votingStory.clear();
                        Navigator.of(dialogContext).pop();
                      }
                    });
                  }
                },
              );
            }
          },
          label: const Text('Reabrir história'),
          icon: const Icon(Icons.file_open),
        ),
      ),
    );
  }

  Padding _deleteStory({required BuildContext dialogContext, required Story story}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(height: 45, width: MediaQuery.of(dialogContext).size.width * 0.70),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          onPressed: () async {
            (TebCustomDialog(context: dialogContext).customdialog(
              message: 'Deseja realmente excluir esta história?',
              yesButtonText: 'Sim',
              noButtonText: 'Não',
              icon: const Icon(Icons.question_mark, size: 50),
            )).then((dialogReturn) {
              if (dialogReturn == true) {
                StoryController().delete(
                  story: story,
                  planningPokerId: widget.planningData.id,
                );
                Navigator.of(dialogContext).pop();
              }
            });
          },
          label: const Text('Excluir'),
          icon: const Icon(Icons.delete),
        ),
      ),
    );
  }

  Future<void> _showStoryOptions({required BuildContext context, required Story story}) async {
    if (!widget.user.isSpectator) {
      Navigator.of(context).pushNamed(Routes.storyForm, arguments: {
        'story': story,
        'planningData': widget.planningData,
        'user': widget.user,
      });
      return;
    }

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
          title: const Text('O que deseja fazer?'),
          titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
          content: StatefulBuilder(
            builder: (BuildContext ctx2, StateSetter setState) {
              return Column(
                children: [
                  // edit
                  _editStory(dialogContext: dialogContext, story: story),
                  // set to vote
                  if (story.status != StoryStatus.closed) _setStoryToVote(dialogContext: dialogContext, story: story),
                  // finish voting
                  if (story.status == StoryStatus.voting) _finishStoryVote(dialogContext: dialogContext, story: story),
                  // close story
                  if (story.status == StoryStatus.votingFinished) _closeStory(dialogContext: dialogContext, story: story),
                  // reopen story
                  if (story.status == StoryStatus.closed) _reopenStory(dialogContext: dialogContext, story: story),

                  // delete
                  _deleteStory(dialogContext: dialogContext, story: story),
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
    return GestureDetector(
      onTap: () async => _showStoryOptions(context: context, story: widget.story),
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Card(
          color: widget.story.status == StoryStatus.voting
              ? Theme.of(context).primaryColorLight
              : widget.story.status == StoryStatus.created
                  ? Theme.of(context).cardColor
                  : widget.story.status == StoryStatus.closed
                      ? Theme.of(context).primaryColorDark.withAlpha(90)
                      : Theme.of(context).primaryColorDark.withAlpha(20),
          child: SizedBox(
            height: widget.size.height,
            width: widget.size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // name / title
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
                  child: Text(
                    widget.story.name.length > 30 ? '${widget.story.name.substring(0, 30)}...' : widget.story.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                // description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    widget.story.description.length > 150
                        ? '${widget.story.description.substring(0, 150)}...'
                        : widget.story.description,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const Spacer(),
                // points
                if (widget.story.status == StoryStatus.closed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.numbers, size: 15),
                        TebText(
                          widget.story.points == 0
                              ? 'Um café'
                              : '${widget.story.points} ${widget.story.points == 1 ? 'ponto' : 'pontos'}',
                          padding: const EdgeInsets.only(left: 10),
                          textSize: 14,
                        ),
                      ],
                    ),
                  ),
                // user name
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5),
                  child: Text(
                    'Criado por ${widget.story.user!.name.length > 30 ? '${widget.story.user!.name.substring(0, 30)}...' : widget.story.user!.name}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      if (widget.story.url.isNotEmpty)
                        // url
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: GestureDetector(
                            onTap: () {
                              TebUrlManager.launchUrl(url: widget.story.url).then((value) {
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
                      const Spacer(),
                      // order options
                      IconButton.filled(
                        onPressed: () => StoryController().changeStoryOrder(
                          story: widget.story,
                          storyOrderChange: StoryOrderChange.downward,
                        ),
                        icon: const Icon(Icons.arrow_downward),
                        iconSize: 26,
                      ),
                      IconButton.filled(
                        onPressed: () => StoryController().changeStoryOrder(
                          story: widget.story,
                          storyOrderChange: StoryOrderChange.upward,
                        ),
                        icon: const Icon(Icons.arrow_upward),
                        iconSize: 26,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
