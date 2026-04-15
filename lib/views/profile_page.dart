import 'package:aullet/viewmodels/auth_view_model.dart';
import 'package:aullet/viewmodels/profile_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<ProfileViewModel>();
      await vm.loadProfile();
      if (mounted && vm.profile != null) {
        _nameCtrl.text = vm.profile!.displayName;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final authVM = context.read<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await authVM.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: (vm.isLoading || vm.profile == null)
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: vm.profile?.avatarUrl != null
                          ? NetworkImage(vm.profile!.avatarUrl!)
                          : null,
                      child: vm.profile?.avatarUrl == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    TextButton(
                      onPressed: vm.pickAndUploadAvatar,
                      child: const Text('Cambia Avatar'),
                    ),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nome'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        vm.updateDisplayName(_nameCtrl.text);
                      },
                      child: const Text('Salva'),
                    ),
                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        vm.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
