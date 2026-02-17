import 'dart:io';
import 'package:flutter/material.dart';
import '../models/challenge_model.dart';
import '../services/challenge_service.dart';
import '../services/auth_service.dart';

class ChallengeProvider with ChangeNotifier {
  final ChallengeService _service = ChallengeService();
  final AuthService _authService = AuthService();

  List<Challenge> _challenges = [];
  List<Challenge> get challenges => _challenges;

  List<String> _completedChallengeIds = [];
  List<String> get completedChallengeIds => _completedChallengeIds;

  List<UserProfile> _leaderboard = [];
  List<UserProfile> get leaderboard => _leaderboard;

  UserProfile? _myProfile;
  UserProfile? get myProfile => _myProfile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Challenge? _activeChallenge;
  Challenge? get activeChallenge => _activeChallenge;

  ChallengeProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadChallenges();
    await loadMyProfile();
  }

  Future<void> loadChallenges() async {
    _isLoading = true;
    notifyListeners();
    try {
      _challenges = await _service.getChallenges();
      _completedChallengeIds = await _service.getCompletedChallengeIds();
    } catch (e) {
      debugPrint("Error loading challenges: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isChallengeUnlocked(String challengeId) {
    if (_challenges.isEmpty) return false;

    final index = _challenges.indexWhere((c) => c.id == challengeId);
    if (index == -1) return false;

    // First challenge is always unlocked
    if (index == 0) return true;

    // Subsequent challenges are unlocked if the previous one is completed
    final previousChallengeId = _challenges[index - 1].id;
    return _completedChallengeIds.contains(previousChallengeId);
  }

  bool isChallengeCompleted(String challengeId) {
    return _completedChallengeIds.contains(challengeId);
  }

  Future<void> loadLeaderboard() async {
    try {
      _leaderboard = await _service.getLeaderboard();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading leaderboard: $e");
    }
  }

  Future<void> loadMyProfile() async {
    try {
      _myProfile = await _service.getMyProfile();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading my profile: $e");
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    required String? phone,
    required String university,
    required String license,
    required String department,
    File? avatarFile,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        phone: phone,
        university: university,
        license: license,
        department: department,
        avatarFile: avatarFile,
      );
      await loadMyProfile();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signIn(email: email, password: password);
      await loadMyProfile();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _myProfile = null;
    notifyListeners();
  }

  void setActiveChallenge(Challenge? challenge) {
    _activeChallenge = challenge;
    notifyListeners();
  }

  Future<void> submitResult({
    required String challengeId,
    required String code,
    required bool success,
    int? timeTakenMs,
  }) async {
    try {
      await _service.submitAttempt(
        challengeId: challengeId,
        code: code,
        success: success,
        timeTakenMs: timeTakenMs,
      );

      // Refresh completion list and profile
      _completedChallengeIds = await _service.getCompletedChallengeIds();
      await loadMyProfile(); // This updates XP and Level

      notifyListeners();
    } catch (e) {
      debugPrint("Error submitting attempt: $e");
    }
  }

  Stream<List<UserProfile>> leaderboardStream() {
    return _service.getLeaderboardStream();
  }
}
