import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/features/story/models/story.dart';
import 'package:planningpoker/features/story/models/story_vote.dart';
import 'package:planningpoker/features/user/model/user.dart';
import 'package:teb_package/util/teb_return.dart';
import 'package:teb_package/util/teb_uid_generator.dart';

enum StoryOrderChange { upward, downward }

class StoryController with ChangeNotifier {
  final String _planningDataCollectionName = 'planningData';
  final String _storyCollectionName = 'story';
  final String _storyVoteCollectionName = 'storyVote';

  StoryController();

  Future<TebCustomReturn> save({required Story story, required String planningPokerId}) async {
    try {
      if (story.id.isEmpty) {
        var query = await FirebaseFirestore.instance
            .collection(_planningDataCollectionName)
            .doc(planningPokerId)
            .collection(_storyCollectionName)
            .get();

        var dataList = query.docs.map((doc) => doc.data()).toList();

        story.id = TebUidGenerator.firestoreUid;
        story.planningPokerId = planningPokerId;
        story.order = dataList.length + 1;
      }
      await FirebaseFirestore.instance
          .collection(_planningDataCollectionName)
          .doc(planningPokerId)
          .collection(_storyCollectionName)
          .doc(story.id)
          .set(story.toMap);

      notifyListeners();
      return TebCustomReturn.sucess;
    } catch (e) {
      return TebCustomReturn.error(e.toString());
    }
  }

  Future<TebCustomReturn> reOpenStory({required Story story, required bool removeCastedVotes}) async {
    try {
      if (removeCastedVotes) {
        var storyVotes = await FirebaseFirestore.instance
            .collection(_planningDataCollectionName)
            .doc(story.planningPokerId)
            .collection(_storyCollectionName)
            .doc(story.id)
            .collection(_storyVoteCollectionName)
            .get();

        for (var vote in storyVotes.docs) {
          vote.reference.delete();
        }
      }

      story.points = 0;
      story.status = StoryStatus.created;
      save(planningPokerId: story.planningPokerId, story: story);

      notifyListeners();
      return TebCustomReturn.sucess;
    } catch (e) {
      return TebCustomReturn.error(e.toString());
    }
  }

  Future<TebCustomReturn> delete({required Story story, required String planningPokerId}) async {
    try {
      await FirebaseFirestore.instance
          .collection(_planningDataCollectionName)
          .doc(planningPokerId)
          .collection(_storyCollectionName)
          .doc(story.id)
          .delete();

      notifyListeners();
      return TebCustomReturn.sucess;
    } catch (e) {
      return TebCustomReturn.error(e.toString());
    }
  }

  Future<TebCustomReturn> changeStoryOrder({required Story story, required StoryOrderChange storyOrderChange}) async {
    try {
      final otherStoryOrder = storyOrderChange == StoryOrderChange.downward ? story.order + 1 : story.order - 1;

      var query = await FirebaseFirestore.instance
          .collection(_planningDataCollectionName)
          .doc(story.planningPokerId)
          .collection(_storyCollectionName)
          .where('order', isEqualTo: otherStoryOrder)
          .get();
      final dataList = query.docs.map((doc) => doc.data()).toList();
      final otherStory = Story.fromMap(dataList.first);

      final newOrder = otherStory.order;
      otherStory.order = story.order;
      story.order = newOrder;

      var result = await save(story: otherStory, planningPokerId: story.planningPokerId);
      if (result.returnType != TebCustomReturn.sucess.returnType) return result;

      result = await save(story: story, planningPokerId: story.planningPokerId);
      if (result.returnType != TebCustomReturn.sucess.returnType) return result;

      return TebCustomReturn.sucess;
    } catch (e) {
      return TebCustomReturn.error(e.toString());
    }
  }

  Future<TebCustomReturn> setStoryToVote({required Story story, required String planningPokerId}) async {
    try {
      var query = await FirebaseFirestore.instance
          .collection(_planningDataCollectionName)
          .doc(planningPokerId)
          .collection(_storyCollectionName)
          .where('voting', isEqualTo: true)
          .get();

      if (query.docs.isNotEmpty) {
        return TebCustomReturn.error('Já existe uma história em votacão, finalize ela antes de iniciar uma nova');
      }

      story.status = StoryStatus.voting;
      return save(story: story, planningPokerId: planningPokerId);
    } catch (e) {
      return TebCustomReturn.error(e.toString());
    }
  }

  Future<TebCustomReturn> vote({required StoryVote storyVote, required User user, StoryVote? oldStoryVote}) async {
    try {
      if (storyVote.id.isEmpty) {
        storyVote.id = TebUidGenerator.firestoreUid;
        storyVote.planningPokerId = user.planningPokerId;
        storyVote.userId = user.id;
        storyVote.userName = user.name;
      }

      if (oldStoryVote != null && oldStoryVote.id.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(_planningDataCollectionName)
            .doc(user.planningPokerId)
            .collection(_storyCollectionName)
            .doc(oldStoryVote.storyId)
            .collection(_storyVoteCollectionName)
            .doc(oldStoryVote.id)
            .delete();
      }

      await FirebaseFirestore.instance
          .collection(_planningDataCollectionName)
          .doc(user.planningPokerId)
          .collection(_storyCollectionName)
          .doc(storyVote.storyId)
          .collection(_storyVoteCollectionName)
          .doc(storyVote.id)
          .set(storyVote.toMap());

      notifyListeners();
      return TebCustomReturn.sucess;
    } catch (e) {
      return TebCustomReturn.error(e.toString());
    }
  }

  Future<StoryVote> getUserVote({required Story story, required User user}) async {
    var query = await FirebaseFirestore.instance
        .collection(_planningDataCollectionName)
        .doc(user.planningPokerId)
        .collection(_storyCollectionName)
        .doc(story.id)
        .collection(_storyVoteCollectionName)
        .where("userId", isEqualTo: user.id)
        .get();

    var dataList = query.docs.map((doc) => doc.data()).toList();

    return dataList.isEmpty ? StoryVote() : StoryVote.fromMap(dataList.first);
  }

  Stream<QuerySnapshot<Object?>> getStories({required String planningPokerId}) {
    return FirebaseFirestore.instance
        .collection(_planningDataCollectionName)
        .doc(planningPokerId)
        .collection(_storyCollectionName)
        .snapshots();
  }

  Future<List<Story>> getInitialStories(String planningPokerId) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection(_planningDataCollectionName)
        .doc(planningPokerId)
        .collection(_storyCollectionName)
        .get();
    var storiesList = querySnapshot.docs.map((e) => Story.fromDocument(e)).toList();
    storiesList.sort((a, b) => a.order.compareTo(b.order));
    storiesList.sort((a, b) => a.storyStatusOrder.compareTo(b.storyStatusOrder));
    return storiesList;
  }

  Story getVotingStory(List<Story> storiesList) {
    var l = storiesList.where((s) => s.status == StoryStatus.voting).toList();
    if (l.isEmpty) return Story();
    return l.first;
  }

  Story getVotingFinishedStory(List<Story> storiesList) {
    var l = storiesList.where((s) => s.status == StoryStatus.votingFinished).toList();
    if (l.isEmpty) return Story();
    return l.first;
  }

  Story getClosedStory(List<Story> storiesList) {
    var l = storiesList.where((s) => s.status == StoryStatus.closed).toList();
    if (l.isEmpty) return Story();
    return l.first;
  }

  Stream<QuerySnapshot<Object?>> getStoryVotes({required Story story, String planningId = ''}) {
    return FirebaseFirestore.instance
        .collection(_planningDataCollectionName)
        .doc(planningId)
        .collection(_storyCollectionName)
        .doc(story.id)
        .collection(_storyVoteCollectionName)
        .snapshots();
  }
}
