import 'package:aullet/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final _client = Supabase.instance.client;

  Future<Profile?> fetchProfile(String userId) async {
    final data = await _client
    .from('profiles')
    .select()
    .eq('user_id', userId)
    .maybeSingle();

    if(data == null) return null;
    return Profile.fromMap(data as Map<String, dynamic>);
  }

  Future<void> createProfile(Profile profile) async {
    final _ = await _client
    .from('profiles')
    .insert(profile.toMap());
  }

  Future<void> updateProfile(Profile profile) async {
    final _ = await _client
    .from('profiles')
    .update(profile.toMap())
    .eq('user_id', profile.userId);
  }
}