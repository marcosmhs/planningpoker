// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/story/models/story.dart';
import 'package:planningpoker/features/story/story_controller.dart';
import 'package:planningpoker/features/user/visualizations/user.dart';
import 'package:teb_package/messaging/teb_custom_dialog.dart';
import 'package:teb_package/messaging/teb_custom_message.dart';
import 'package:teb_package/util/teb_return.dart';

class StoryCard extends StatefulWidget {
  final Size size;
  final PlanningData planningData;
  final Story story;
  final Story votingStory;
  final User user;
  const StoryCard({
    super.key,
    required this.user,
    required this.planningData,
    required this.story,
    required this.votingStory,
    required this.size,
  });

  @override
  State<StoryCard> createState() => _StoryCardState();

  static Widget newCard(
      {required BuildContext context, required Size size, required PlanningData planningData, required User user}) {
    return Card(
      child: SizedBox(
        height: size.height,
        width: size.width,
        child: ClipOval(
          child: InkWell(
            splashColor: Theme.of(context).primaryColor,
            onTap: () => Navigator.of(context).pushNamed(
              Routes.storyForm,
              arguments: {'planningData': planningData, 'user': user},
            ),
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
}

class _StoryCardState extends State<StoryCard> {
  Widget _editStory({required BuildContext dialogContext, required BuildContext context, required Story story}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(height: 45, width: MediaQuery.of(dialogContext).size.width * 0.70),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pushNamed(
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

  Widget _setStoryToVote({required BuildContext dialogContext, required BuildContext context, required Story story}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(height: 45, width: MediaQuery.of(dialogContext).size.width * 0.70),
        child: ElevatedButton.icon(
          onPressed: () async {
            if (widget.votingStory.id.isNotEmpty && widget.votingStory.id != story.id) {
              TebCustomDialog(context: context)
                  .errorMessage(message: 'Já existe uma história em votação, é necssário finalizá-la antes')
                  .then((value) => Navigator.of(dialogContext, rootNavigator: true).pop());
              return;
            }
            if (story.status == StoryStatus.voting || story.status == StoryStatus.votingFinished) {
              (TebCustomDialog(context: context).customdialog(
                message: 'Esta história já está em votacão, deseja cancelar a votação dela?',
                yesButtonText: 'Sim',
                noButtonText: 'Não',
                icon: const Icon(Icons.question_mark, size: 50),
              )).then((dialogReturn) {
                if (dialogReturn == true) {
                  story.status = StoryStatus.created;
                  StoryController().save(story: story, planningPokerId: widget.planningData.id).then((customReturn) {
                    if (customReturn.returnType == TebReturnType.error) {
                      TebCustomMessage.error(context, message: customReturn.message);
                    } else {
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
          label: const Text('Iniciar Votação'),
          icon: const Icon(Icons.send_to_mobile_rounded),
        ),
      ),
    );
  }

  Padding _finishStoryVote({required BuildContext dialogContext, required BuildContext context, required Story story}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(height: 45, width: MediaQuery.of(dialogContext).size.width * 0.70),
        child: ElevatedButton.icon(
          onPressed: () async {
            if (story.status == StoryStatus.voting || story.status == StoryStatus.votingFinished) {
              (TebCustomDialog(context: context).customdialog(
                message: 'Confirma a finalização da votação? Após isso ninguém mais poderá lançar seus votos?',
                yesButtonText: 'Sim',
                noButtonText: 'Não',
                icon: const Icon(Icons.question_mark, size: 50),
              )).then(
                (dialogReturn) {
                  if (dialogReturn == true) {
                    story.status = StoryStatus.votingFinished;
                    StoryController().save(story: story, planningPokerId: widget.planningData.id).then((customReturn) {
                      if (customReturn.returnType == TebReturnType.error) {
                        TebCustomMessage.error(context, message: customReturn.message);
                      } else {
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
              }
            }
          },
          label: const Text('Finalizar Votação'),
          icon: const Icon(Icons.close_outlined),
        ),
      ),
    );
  }

  Padding _deleteStory({required BuildContext dialogContext, required BuildContext context, required Story story}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(height: 45, width: MediaQuery.of(dialogContext).size.width * 0.70),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () async {
            (TebCustomDialog(context: context).customdialog(
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
              }
              Navigator.of(context).pop();
            });
          },
          label: const Text('Excluir'),
          icon: const Icon(Icons.delete),
        ),
      ),
    );
  }

  Future<void> _showStoryOptions({required BuildContext context, required Story story}) async {
    if (!widget.user.creator) {
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
                  : EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width <= 1000 ? 0 : 300)
              : EdgeInsets.zero,
          scrollable: true,
          title: const Text('O que deseja fazer?'),
          titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
          content: StatefulBuilder(
            builder: (BuildContext ctx2, StateSetter setState) {
              return Column(
                children: [
                  // edit
                  _editStory(dialogContext: dialogContext, context: context, story: story),
                  // set to vote
                  _setStoryToVote(dialogContext: dialogContext, context: context, story: story),
                  // Finalize vote
                  _finishStoryVote(dialogContext: dialogContext, context: context, story: story),
                  // delete
                  _deleteStory(dialogContext: dialogContext, context: context, story: story),
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
      onTap: () async {
        _showStoryOptions(context: context, story: widget.story);
      },
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Card(
          color: widget.story.status == StoryStatus.voting || widget.story.status == StoryStatus.votingFinished
              ? Theme.of(context).primaryColorLight
              : Theme.of(context).cardColor,
          child: SizedBox(
            height: widget.size.height,
            width: widget.size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // name
                Padding(
                  padding: const EdgeInsets.only(left: 5, top: 10, bottom: 5),
                  child: Text(
                    widget.story.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                // description
                Padding(
                  padding: const EdgeInsets.only(left: 5, top: 5, bottom: 5),
                  child: Text(
                    widget.story.description.length > 50
                        ? '${widget.story.description.substring(1, 50)}...'
                        : widget.story.description,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                const Spacer(),
                // Status
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.story.status == StoryStatus.closed
                        ? '${widget.story.statusLabel} - ${widget.story.points} pontos'
                        : widget.story.statusLabel,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),

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
}
