import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    required String? phone,
    String university = 'Université de Labé',
    required String license,
    required String department,
    File? avatarFile,
  }) async {
    // 1. Sign up user in Supabase Auth
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      String? avatarUrl;

      // 2. Upload avatar if selected
      if (avatarFile != null) {
        final fileName =
            '${response.user!.id}_${DateTime.now().millisecondsSinceEpoch}.png';
        await _supabase.storage.from('avatars').upload(fileName, avatarFile);
        avatarUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      // 3. Create profile in public.profiles
      await _supabase.from('profiles').upsert({
        'id': response.user!.id,
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
        'phone': phone,
        'university': university,
        'license': license,
        'department': department,
        'avatar_url': avatarUrl,
        'username': email.split('@')[0], // Default username
      });
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<UserProfile?> getProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response != null) {
      return UserProfile.fromJson(response);
    }
    return null;
  }
}
