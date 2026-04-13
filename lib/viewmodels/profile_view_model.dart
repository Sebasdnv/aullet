import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aullet/models/profile.dart';
import 'package:aullet/repositories/profile_repository.dart';
import 'package:image_picker/image_picker.dart';


class ProfileViewModel extends ChangeNotifier {
  final _repo = ProfileRepository();
  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;

  Future<void> loadProfile() async {
    _setLoading(true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      _profile = await _repo.fetchProfile(user.id);

      if(_profile == null) {
        _profile = Profile(
          id: '',
          userId: user.id,
          displayName: user.email!.split('@')[0],
        );

      await _repo.createProfile(_profile!);
      _profile = await _repo.fetchProfile(user.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateDisplayName(String name) async {
    if (_profile == null) return;
    
    _setLoading(true);
    try {
      final updatedProfile = _profile!.copyWith(displayName: name);
      
      await _repo.updateProfile(updatedProfile);
      _profile = updatedProfile;
      
    } catch (e) {
      _error = "Errore durante il salvataggio: ${e.toString()}";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> pickAndUploadAvatar() async {
    if (_profile == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _setLoading(true);
      try {
        final file = File(image.path);
        final fileName = '${_profile!.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        final storage = Supabase.instance.client.storage.from('avatars');
        await storage.upload(fileName, file);

        final String publicUrl = storage.getPublicUrl(fileName);

        final updatedProfile = _profile!.copyWith(avatarUrl: publicUrl);
        await _repo.updateProfile(updatedProfile);
        
        _profile = updatedProfile;
      } catch (e) {
        _error = "Errore caricamento immagine: ${e.toString()}";
      } finally {
        _setLoading(false);
      }
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _error = null;
    notifyListeners();
  }

}