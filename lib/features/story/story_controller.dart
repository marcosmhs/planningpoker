import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/components/util/custom_return.dart';
import 'package:planningpoker/components/util/uid_generator.dart';
import 'package:planningpoker/features/story/story.dart';
import 'package:planningpoker/features/story/story_vote.dart';
import 'package:planningpoker/features/user/user.dart';

class StoryController with ChangeNotifier {
  final String _planningDataCollectionName = 'planningData';
  final String _storyCollectionName = 'story';
  final String _storyVoteCollectionName = 'storyVote';

  final User user;

  StoryController(this.user);

  Future<CustomReturn> save({required Story story}) async {
    try {
      if (story.id.isEmpty) {
        story.id = UidGenerator.firestoreUid;
        story.planningPokerId = user.planningPokerId;
      }
      await FirebaseFirestore.instance
          .collection(_planningDataCollectionName)
          .doc(user.planningPokerId)
          .collection(_storyCollectionName)
          .doc(story.id)
          .set(story.toMap());

      notifyListeners();
      return CustomReturn.sucess;
    } catch (e) {
      return CustomReturn.error(e.toString());
    }
  }

  Future<CustomReturn> delete({required Story story}) async {
    try {
      await FirebaseFirestore.instance
          .collection(_planningDataCollectionName)
          .doc(user.planningPokerId)
          .collection(_storyCollectionName)
          .doc(story.id)
          .delete();

      notifyListeners();
      return CustomReturn.sucess;
    } catch (e) {
      return CustomReturn.error(e.toString());
    }
  }

  Future<CustomReturn> setStoryToVote({required Story story}) async {
    try {
      var query = await FirebaseFirestore.instance
          .collection(_planningDataCollectionName)
          .doc(user.planningPokerId)
          .collection(_storyCollectionName)
          .where('voting', isEqualTo: true)
          .get();

      if (query.docs.isNotEmpty) {
        return CustomReturn.error('Já existe uma história em votacão, finalize ela antes de iniciar uma nova');
      }

      story.status = StoryStatus.voting;
      return save(story: story);
    } catch (e) {
      return CustomReturn.error(e.toString());
    }
  }

  Future<CustomReturn> vote({required StoryVote storyVote}) async {
    try {
      if (storyVote.id.isEmpty) {
        storyVote.id = UidGenerator.firestoreUid;
        storyVote.planningPokerId = user.planningPokerId;
        storyVote.userid = user.id;
        storyVote.userName = user.name;
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
      return CustomReturn.sucess;
    } catch (e) {
      return CustomReturn.error(e.toString());
    }
  }

  Future<StoryVote> getUserVote({required Story story}) async {
    var query = await FirebaseFirestore.instance
        .collection(_planningDataCollectionName)
        .doc(user.planningPokerId)
        .collection(_storyCollectionName)
        .doc(story.id)
        .collection(_storyVoteCollectionName)
        .where("userId", isEqualTo: user.id)
        .get();

    var dataList = query.docs.map((doc) => doc.data()).toList();

    return StoryVote.fromMap(dataList.first);
  }

  Stream<QuerySnapshot<Object?>> get getStories {
    return FirebaseFirestore.instance
        .collection(_planningDataCollectionName)
        .doc(user.planningPokerId)
        .collection(_storyCollectionName)
        .snapshots();
  }

  Stream<QuerySnapshot<Object?>> getStoryVotes({required Story story}) {
    return FirebaseFirestore.instance
        .collection(_planningDataCollectionName)
        .doc(user.planningPokerId)
        .collection(_storyCollectionName)
        .doc(story.id)
        .collection(_storyVoteCollectionName)
        .snapshots();
  }
}
