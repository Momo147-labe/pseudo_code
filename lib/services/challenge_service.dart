import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge_model.dart';

class ChallengeService {
  final _supabase = Supabase.instance.client;

  Future<List<Challenge>> getChallenges() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/challenges.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((c) => Challenge.fromJson(c)).toList();
    } catch (e) {
      print("Error loading challenges from assets: $e");
      return [];
    }
  }

  Future<List<UserProfile>> getLeaderboard() async {
    final response = await _supabase
        .from('profiles')
        .select()
        .order('xp', ascending: false)
        .limit(50);

    return (response as List).map((p) => UserProfile.fromJson(p)).toList();
  }

  Future<void> submitAttempt({
    required String challengeId,
    required String code,
    required bool success,
    int? timeTakenMs,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final status = success ? 'success' : 'failed';

    await _supabase.from('challenge_attempts').insert({
      'user_id': user.id,
      'challenge_id': challengeId,
      'code': code,
      'status': status,
      'time_taken_ms': timeTakenMs,
    });

    if (success) {
      // Logic for adding XP would ideally be in a Supabase Function/Trigger,
      // but we can increment it here if RLS allows.
      // For now, let's assume a trigger on the database increments the XP.
    }
  }

  Stream<List<UserProfile>> getLeaderboardStream() {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('xp', ascending: false)
        .limit(50)
        .map((data) => data.map((p) => UserProfile.fromJson(p)).toList());
  }

  Future<UserProfile?> getMyProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return UserProfile.fromJson(response);
  }
}
