import 'dart:io';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../main.dart';
import 'business_profile_screen.dart';
import 'main_shell.dart';

class ProfileListScreen extends StatefulWidget {
  const ProfileListScreen({super.key});

  @override
  State<ProfileListScreen> createState() => _ProfileListScreenState();
}

class _ProfileListScreenState extends State<ProfileListScreen> {
  List<Map<String, String>> _profiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final profiles = await StorageService.getAllProfiles();
    setState(() {
      _profiles = profiles;
      _loading = false;
    });
  }

  void _switchProfile(String id) async {
    await StorageService.setActiveProfileId(id);
    final activeFY = await StorageService.getActiveFY() ?? '';
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MainShell(activeFY: activeFY)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(TranslationService.translate('switch_profile', lang)),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _profiles.isEmpty
                  ? Center(child: Text(TranslationService.translate('no_profiles_found', lang)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _profiles.length,
                      itemBuilder: (context, index) {
                        final p = _profiles[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: p['logoPath']!.isNotEmpty 
                                  ? FileImage(File(p['logoPath']!)) 
                                  : null,
                              child: p['logoPath']!.isEmpty 
                                  ? const Icon(Icons.business) 
                                  : null,
                            ),
                            title: Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(p['email']!),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _switchProfile(p['id']!),
                          ),
                        );
                      },
                    ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BusinessProfileScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(TranslationService.translate('create_new_profile', lang)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        );
      },
    );
  }
}
