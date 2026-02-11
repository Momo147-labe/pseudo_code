enum ChallengeDifficulty { Easy, Medium, Hard, Expert }

class Challenge {
  final String id;
  final String title;
  final String description;
  final String instructions;
  final ChallengeDifficulty difficulty;
  final int xpReward;
  final String? initialCode;
  final List<TestCase> testCases;
  final DateTime createdAt;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.instructions,
    required this.difficulty,
    required this.xpReward,
    this.initialCode,
    required this.testCases,
    required this.createdAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      instructions: json['instructions'] ?? '',
      difficulty: ChallengeDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == json['difficulty'],
        orElse: () => ChallengeDifficulty.Easy,
      ),
      xpReward: json['xp_reward'] ?? 100,
      initialCode: json['initial_code'],
      testCases: (json['test_cases'] as List)
          .map((t) => TestCase.fromJson(t))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class TestCase {
  final String input;
  final String expectedOutput;

  TestCase({required this.input, required this.expectedOutput});

  factory TestCase.fromJson(Map<String, dynamic> json) {
    return TestCase(
      input: json['input'].toString(),
      expectedOutput: json['output'].toString(),
    );
  }
}

class UserProfile {
  final String id;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? phone;
  final String university;
  final String? license;
  final String? department;
  final String? avatarUrl;
  final int xp;
  final int level;

  UserProfile({
    required this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.gender,
    this.phone,
    this.university = 'Université de Labé',
    this.license,
    this.department,
    this.avatarUrl,
    this.xp = 0,
    this.level = 1,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      gender: json['gender'],
      phone: json['phone'],
      university: json['university'] ?? 'Université de Labé',
      license: json['license'],
      department: json['department'],
      avatarUrl: json['avatar_url'],
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
    );
  }
}

class ChallengeAttempt {
  final String id;
  final String userId;
  final String challengeId;
  final String code;
  final String status;
  final int? timeTakenMs;
  final DateTime createdAt;

  ChallengeAttempt({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.code,
    required this.status,
    this.timeTakenMs,
    required this.createdAt,
  });

  factory ChallengeAttempt.fromJson(Map<String, dynamic> json) {
    return ChallengeAttempt(
      id: json['id'],
      userId: json['user_id'],
      challengeId: json['challenge_id'],
      code: json['code'],
      status: json['status'],
      timeTakenMs: json['time_taken_ms'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
