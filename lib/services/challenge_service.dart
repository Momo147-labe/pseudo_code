import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/challenge_model.dart';

class ChallengeService {
  static const String _completedKey = 'completed_challenges';
  static const String _pointsKey = 'user_points';

  Future<List<Challenge>> getChallenges() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/challenges.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<Challenge> allChallenges = jsonList
          .map((c) => Challenge.fromJson(c))
          .toList();

      // Mark locked state based on completion of the previous challenge
      final prefs = await SharedPreferences.getInstance();
      final completedIds = prefs.getStringList(_completedKey) ?? [];

      for (int i = 0; i < allChallenges.length; i++) {
        // First challenge (i=0) is always unlocked
        // Subsequent challenges (i>0) are unlocked if the previous one is completed
        bool isUnlocked =
            i == 0 || completedIds.contains(allChallenges[i - 1].id);
        // We need to add a "locked" flag or similar to the Challenge model or handle it in the UI/Provider.
        // For now, the service just returns the list, and we'll handle the logic in the Provider.
      }

      return allChallenges;
    } catch (e) {
      print("Error loading challenges from assets: $e");
      return [];
    }
  }

  Future<List<UserProfile>> getLeaderboard() async {
    return [];
  }

  Future<void> submitAttempt({
    required String challengeId,
    required String code,
    required bool success,
    int? timeTakenMs,
  }) async {
    if (!success) return;

    final prefs = await SharedPreferences.getInstance();
    final completedIds = prefs.getStringList(_completedKey) ?? [];

    if (!completedIds.contains(challengeId)) {
      completedIds.add(challengeId);
      await prefs.setStringList(_completedKey, completedIds);

      // Add points based on challenge reward (requires finding the challenge)
      // For simplicity, we'll reload challenges or pass reward in this method.
      // But let's keep it simple: the Provider will call submitResult which calls this.
    }
  }

  Future<List<String>> getCompletedChallengeIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_completedKey) ?? [];
  }

  Stream<List<UserProfile>> getLeaderboardStream() {
    return Stream.value([]);
  }

  Future<UserProfile?> getMyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final completedIds = prefs.getStringList(_completedKey) ?? [];

    // Load challenges to sum XP
    final allChallenges = await getChallenges();
    int totalXp = 0;

    for (var id in completedIds) {
      final challenge = allChallenges.where((c) => c.id == id).firstOrNull;
      if (challenge != null) {
        totalXp += challenge.xpReward;
      }
    }

    return UserProfile(
      id: 'local_user',
      username: 'Utilisateur',
      xp: totalXp,
      level: (totalXp / 500).floor() + 1,
    );
  }
}
